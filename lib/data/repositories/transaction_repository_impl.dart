import 'dart:async';

import '../../core/storage/secure_storage_service.dart';
import '../../domain/entities/finance_transaction.dart';
import '../../domain/entities/transaction_summary.dart';
import '../../domain/failures/data_failure.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../models/transaction_model.dart';
import '../sources/local/transaction_local_source.dart';
import '../sources/remote/transaction_remote_source.dart';

/// Transaction repository backed by the REST API with an offline-first cache.
///
/// Reads are served from SQLite first (so the UI paints immediately, even with
/// no connection) and then refreshed from the backend. Writes go straight to
/// the API; a write that fails because the device is offline is queued locally
/// with `pending_sync = 1` and replayed by [syncPendingTransactions] on app
/// start, resume and every subsequent refresh.
class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(
    this._remoteSource,
    this._localSource,
    this._storage,
  );

  final TransactionRemoteSource _remoteSource;
  final TransactionLocalSource _localSource;
  final SecureStorageService _storage;

  bool _syncing = false;
  int _localIdSeed = 0;

  String? get _userId {
    final id = _storage.userId;
    return (id == null || id.isEmpty) ? null : id;
  }

  @override
  Stream<List<FinanceTransaction>> watchCurrentUserTransactions() {
    return _watch<List<FinanceTransaction>>(
      () async {
        final userId = _userId;
        if (userId == null) return const [];
        final items = await _localSource.readTransactions(userId);
        return items.map((item) => item.toEntity()).toList(growable: false);
      },
      refresh: (userId) => _reload(userId),
    );
  }

  @override
  Stream<TransactionSummary?> watchSummary() {
    return _watch<TransactionSummary?>(
      _readSummary,
      refresh: (userId) => _refreshSummary(userId),
    );
  }

  @override
  Future<void> refresh() async {
    await _restore();
    final userId = _userId;
    if (userId == null) return;
    await _localSource.init();
    await syncPendingTransactions();
    await _reload(userId);
  }

  @override
  Future<void> refreshTransactions({
    DateTime? from,
    DateTime? to,
    String? category,
  }) async {
    await _restore();
    final userId = _userId;
    if (userId == null) return;
    await _localSource.init();

    final categoryFilter = _trimmed(category);
    try {
      final remote = await _remoteSource.fetchTransactions(
        from: from,
        to: to,
        category: categoryFilter,
      );
      await _localSource.replaceRemoteTransactions(
        userId,
        _withUser(remote, userId),
        pruneMissing: from == null && to == null && categoryFilter == null,
      );
    } on DataFailure {
      // Offline or backend unavailable: keep serving the cached list.
    }
  }

  @override
  Future<void> syncPendingTransactions() async {
    await _restore();
    final userId = _userId;
    if (userId == null || _syncing) return;
    await _localSource.init();

    final pending = await _localSource.readPending(userId);
    if (pending.isEmpty) return;

    _syncing = true;
    var syncedAny = false;
    try {
      for (final item in pending) {
        try {
          final stored = await _remoteSource.createTransaction(
            type: _typeOf(item.type),
            amount: item.amount,
            category: item.category,
            date: item.date,
            note: item.note,
          );
          await _localSource.markSynced(
            item.id,
            stored.copyWith(
              id: stored.id.isEmpty ? item.id : stored.id,
              userId: userId,
            ),
          );
          syncedAny = true;
        } on DataFailure catch (failure) {
          if (failure.isOffline) break;
        }
      }
    } finally {
      _syncing = false;
    }

    if (syncedAny) await _refreshSummary(userId);
  }

  @override
  Future<FinanceTransaction> addTransaction({
    required TransactionType type,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) {
    return _createTransaction(
      type: type,
      amount: amount,
      category: category,
      date: date,
      note: note,
    );
  }

  @override
  Future<FinanceTransaction> addTransactionWithUserUpdate({
    required TransactionType type,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) {
    return _createTransaction(
      type: type,
      amount: amount,
      category: category,
      date: date,
      note: note,
    );
  }

  @override
  Future<FinanceTransaction> updateTransaction({
    required String id,
    required TransactionType type,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    await _restore();
    final userId = _requireUserId();
    await _localSource.init();

    try {
      final stored = await _remoteSource.updateTransaction(
        id: id,
        type: type,
        amount: amount,
        category: category,
        date: date,
        note: note,
      );
      final cached = stored.copyWith(
        id: stored.id.isEmpty ? id : stored.id,
        userId: userId,
      );
      await _localSource.insertTransaction(cached, pendingSync: false);
      unawaited(_refreshSummary(userId));
      return cached.toEntity();
    } on DataFailure {
      rethrow;
    } catch (_) {
      throw const DataFailure('Could not update the transaction.');
    }
  }

  @override
  Future<void> deleteTransaction(FinanceTransaction transaction) async {
    await _restore();
    final userId = _requireUserId();
    await _localSource.init();

    final isLocalOnly =
        transaction.id.startsWith('local-') ||
        await _localSource.isPending(transaction.id);

    await _localSource.deleteTransaction(transaction.id);

    if (!isLocalOnly) {
      try {
        await _remoteSource.deleteTransaction(transaction.id);
      } catch (_) {
        // Offline or server error: local deletion already succeeded.
      }
    }

    unawaited(_refreshSummary(userId));
  }

  Future<FinanceTransaction> _createTransaction({
    required TransactionType type,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    await _restore();
    final userId = _requireUserId();
    await _localSource.init();

    try {
      final stored = await _remoteSource.createTransaction(
        type: type,
        amount: amount,
        category: category,
        date: date,
        note: note,
      );
      final cached = stored.copyWith(
        id: stored.id.isEmpty ? _newLocalId() : stored.id,
        userId: userId,
      );
      await _localSource.insertTransaction(cached, pendingSync: false);
      unawaited(_refreshSummary(userId));
      return cached.toEntity();
    } on DataFailure catch (failure) {
      if (!failure.isOffline) rethrow;

      final queued = TransactionModel(
        id: _newLocalId(),
        userId: userId,
        type: type.name,
        amount: amount,
        category: category,
        date: date,
        note: note,
      );
      await _localSource.insertTransaction(queued, pendingSync: true);
      return queued.toEntity();
    }
  }

  Future<TransactionSummary?> _readSummary() async {
    final userId = _userId;
    if (userId == null) return null;

    final cached = await _localSource.readSummary(userId);
    final pending = await _localSource.readPending(userId);
    if (cached == null && pending.isEmpty) return null;

    var balance = cached?.balance ?? 0;
    var income = cached?.totalIncome ?? 0;
    var expense = cached?.totalExpense ?? 0;
    for (final item in pending) {
      if (item.type == TransactionType.income.name) {
        balance += item.amount;
        income += item.amount;
      } else {
        balance -= item.amount;
        expense += item.amount;
      }
    }
    return TransactionSummary(
      balance: balance,
      totalIncome: income,
      totalExpense: expense,
    );
  }

  Future<void> _reload(String userId) async {
    try {
      final remote = await _remoteSource.fetchTransactions();
      await _localSource.replaceRemoteTransactions(
        userId,
        _withUser(remote, userId),
      );
    } on DataFailure {
      // Offline: the cached list already covers the UI.
    }
    await _refreshSummary(userId);
  }

  Future<void> _refreshSummary(String userId) async {
    try {
      final summary = await _remoteSource.fetchSummary();
      await _localSource.saveSummary(userId, summary);
    } on DataFailure {
      // Offline: keep the cached summary.
    }
  }

  Stream<T> _watch<T>(
    Future<T> Function() read, {
    required Future<void> Function(String userId) refresh,
  }) {
    final controller = StreamController<T>();
    StreamSubscription<void>? changes;
    var closed = false;

    Future<void> emit() async {
      if (closed) return;
      try {
        final value = await read();
        if (!closed) controller.add(value);
      } catch (error, stackTrace) {
        if (!closed) controller.addError(error, stackTrace);
      }
    }

    controller.onListen = () async {
      await _restore();
      await _localSource.init();
      await emit();
      changes = _localSource.changes.listen((_) => unawaited(emit()));
      final userId = _userId;
      if (userId != null) unawaited(_syncThenRefresh(userId, refresh));
    };

    controller.onCancel = () async {
      closed = true;
      await changes?.cancel();
      changes = null;
    };

    return controller.stream;
  }

  Future<void> _restore() => _storage.restore();

  Future<void> _syncThenRefresh(
    String userId,
    Future<void> Function(String userId) refresh,
  ) async {
    await syncPendingTransactions();
    await refresh(userId);
  }

  String _requireUserId() {
    final userId = _userId;
    if (userId == null) throw const DataFailure('You must be signed in.');
    return userId;
  }

  List<TransactionModel> _withUser(
    List<TransactionModel> items,
    String userId,
  ) {
    return items
        .map((item) => item.userId.isEmpty ? item.copyWith(userId: userId) : item)
        .toList(growable: false);
  }

  TransactionType _typeOf(String value) {
    return value == TransactionType.income.name
        ? TransactionType.income
        : TransactionType.expense;
  }

  String? _trimmed(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  String _newLocalId() {
    return 'local-${DateTime.now().microsecondsSinceEpoch}-${_localIdSeed++}';
  }
}