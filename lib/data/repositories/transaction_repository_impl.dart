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
        // A filtered response is a subset, so cached rows outside the window
        // must be kept; only an unfiltered fetch may prune stale rows.
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

    _syncing = true;
    var syncedAny = false;
    try {
      // Flush the offline deletions before uploading anything, so a row the user
      // removed can never be re-created by a queued insert.
      if (await _flushPendingDeletes(userId)) syncedAny = true;

      for (final item in await _localSource.readPending(userId)) {
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
          // Still offline: keep the rest of the queue for the next attempt.
          if (failure.isOffline) break;
          // The backend rejected this one; leave it queued and carry on.
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
    // The backend updates the user's totals atomically with the insert, so this
    // maps to the same endpoint as [addTransaction].
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

    // Only the backend primary key captured from `GET /api/transactions` can
    // delete the row remotely — never a local placeholder id.
    final id = transaction.id.trim();
    if (id.isEmpty) {
      throw const DataFailure('Could not delete the transaction.');
    }

    // A transaction that never reached the backend — created offline, still
    // queued (`pending_sync = 1`) or carrying a temporary `local-…` id — only
    // lives in SQLite, so dropping the row is the whole delete. Nothing is
    // queued remotely.
    if (_isLocalId(id) || await _localSource.isPending(id)) {
      await _localSource.deleteTransaction(id);
      unawaited(_refreshSummary(userId));
      return;
    }

    try {
      // Online: the backend must confirm (`200`/`204`) before the cached row is
      // dropped, so the two stores never drift apart.
      await _remoteSource.deleteTransaction(id);
    } on DataFailure catch (failure) {
      if (failure.isOffline) {
        // No connection (socket error, DNS, timeout): flag the row for deletion
        // so it leaves the list and the balance at once, and replay the
        // `DELETE` on the next sync.
        await _localSource.markPendingDelete(id);
        unawaited(_refreshSummary(userId));
        return;
      }
      // `404` means the row is already gone on the server, so the delete is a
      // success. Every other status (`400`, `401`, `500`, …) is a real failure
      // and is surfaced instead of silently dropping the local copy.
      if (failure.statusCode != 404) rethrow;
    } catch (_) {
      throw const DataFailure('Could not delete the transaction.');
    }

    await _localSource.deleteTransaction(id);
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

      // Offline: keep the transaction locally and replay it once we're back.
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

  /// The cached summary plus the deltas of everything still queued offline, so
  /// the overview reflects an offline transaction immediately. Returns `null`
  /// while nothing is known yet, letting the caller fall back to the profile.
  Future<TransactionSummary?> _readSummary() async {
    final userId = _userId;
    if (userId == null) return null;

    final cached = await _localSource.readSummary(userId);
    final pending = await _localSource.readPending(userId);
    final pendingDeletes = await _localSource.readPendingDeletes(userId);
    if (cached == null && pending.isEmpty && pendingDeletes.isEmpty) {
      return null;
    }

    var balance = cached?.balance ?? 0;
    var income = cached?.totalIncome ?? 0;
    var expense = cached?.totalExpense ?? 0;
    // Offline creates add to the cached (server) totals…
    for (final item in pending) {
      if (item.type == TransactionType.income.name) {
        balance += item.amount;
        income += item.amount;
      } else {
        balance -= item.amount;
        expense += item.amount;
      }
    }
    // …while offline deletions subtract from them, so the balance tracks the
    // list even before the queued `DELETE` reaches the backend.
    for (final item in pendingDeletes) {
      if (item.type == TransactionType.income.name) {
        balance -= item.amount;
        income -= item.amount;
      } else {
        balance += item.amount;
        expense -= item.amount;
      }
    }
    return TransactionSummary(
      balance: balance,
      totalIncome: income,
      totalExpense: expense,
    );
  }

  /// Replays every locally queued deletion (`pending_delete = 1`) on the
  /// backend. A row is dropped from SQLite once the server confirms with
  /// `200`/`204`, or with `404` because it is already gone. Returns `true` when
  /// at least one row was removed so the caller can refresh the summary.
  Future<bool> _flushPendingDeletes(String userId) async {
    final pending = await _localSource.readPendingDeletes(userId);
    if (pending.isEmpty) return false;

    var removedAny = false;
    for (final item in pending) {
      try {
        await _remoteSource.deleteTransaction(item.id);
        await _localSource.deleteTransaction(item.id);
        removedAny = true;
      } on DataFailure catch (failure) {
        // Still offline: keep the rest of the queue for the next attempt.
        if (failure.isOffline) break;
        if (failure.statusCode == 404) {
          // Already gone on the server — the local row can go too.
          await _localSource.deleteTransaction(item.id);
          removedAny = true;
          continue;
        }
        // The backend rejected the delete (auth, validation, server error);
        // leave it queued and carry on with the rest.
      }
    }
    return removedAny;
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

  /// Emits the cached value as soon as a listener attaches, re-emits on every
  /// local change, and kicks off a sync + backend refresh in the background.
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

  /// Pushes the offline queue first, then reloads, so a reconnecting device
  /// uploads its queued writes before pulling the fresh state back.
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

  /// True for the temporary ids minted locally for transactions the backend
  /// never acknowledged (`local-<micros>-<seed>`).
  bool _isLocalId(String id) => id.startsWith('local-');
}
