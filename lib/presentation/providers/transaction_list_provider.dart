import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/finance_transaction.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/failures/data_failure.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/user_repository.dart';

enum TransactionTimeFilter { thisMonth, lastMonth, all }

@immutable
class _DateRange {
  const _DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }
}

class TransactionListProvider extends ChangeNotifier {
  TransactionListProvider({
    required this.transactionRepository,
    required this.userRepository,
  });

  final TransactionRepository transactionRepository;
  final UserRepository userRepository;

  StreamSubscription<List<FinanceTransaction>>? _txnSubscription;
  StreamSubscription<UserProfile?>? _profileSubscription;

  String? _uid;
  List<FinanceTransaction> _allTransactions = const [];
  UserProfile? _profile;
  TransactionTimeFilter _timeFilter = TransactionTimeFilter.thisMonth;
  String? _categoryFilter;
  bool _isLoading = true;
  String? _errorMessage;

  List<FinanceTransaction> get allTransactions =>
      List.unmodifiable(_allTransactions);

  String get currency => _profile?.currency ?? 'BDT';

  TransactionTimeFilter get timeFilter => _timeFilter;
  String? get categoryFilter => _categoryFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasCategoryFilter =>
      _categoryFilter != null && _categoryFilter!.trim().isNotEmpty;

  /// Local filtering keeps the list instant and usable offline; the same
  /// filters are also sent to the backend (see [_refreshWithFilters]) so the
  /// cached window stays in sync with what the UI is showing.
  List<FinanceTransaction> get filteredTransactions {
    final range = _timeFilterToRange(_timeFilter, DateTime.now());
    final category = _categoryFilter?.trim().toLowerCase();
    final matchesCategory = category == null || category.isEmpty;

    final results = <FinanceTransaction>[];
    for (final txn in _allTransactions) {
      if (range != null && !range.contains(txn.date)) {
        continue;
      }
      if (!matchesCategory &&
          txn.category.trim().toLowerCase() != category) {
        continue;
      }
      results.add(txn);
    }
    return List.unmodifiable(results);
  }

  int get filteredCount => filteredTransactions.length;
  bool get isEmpty => filteredTransactions.isEmpty;

  void bindUid(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _txnSubscription?.cancel();
    _txnSubscription = null;
    _profileSubscription?.cancel();
    _profileSubscription = null;

    if (uid == null || uid.isEmpty) {
      _allTransactions = const [];
      _profile = null;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _profileSubscription = userRepository.watchCurrentUser().listen(
      (profile) {
        _profile = profile;
        notifyListeners();
      },
      onError: (Object _) {
      },
    );

    _txnSubscription = transactionRepository
        .watchCurrentUserTransactions()
        .listen(
          (items) {
            _allTransactions = items;
            _isLoading = false;
            notifyListeners();
          },
          onError: (Object error) {
            _errorMessage = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  void setTimeFilter(TransactionTimeFilter filter) {
    if (_timeFilter == filter) return;
    _timeFilter = filter;
    notifyListeners();
    _refreshWithFilters();
  }

  void setCategoryFilter(String? category) {
    final trimmed = category?.trim();
    final newVal = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    if (_categoryFilter == newVal) return;
    _categoryFilter = newVal;
    notifyListeners();
    _refreshWithFilters();
  }

  void clearCategoryFilter() {
    setCategoryFilter(null);
  }

  void clearFilters() {
    var changed = false;
    if (_timeFilter != TransactionTimeFilter.thisMonth) {
      _timeFilter = TransactionTimeFilter.thisMonth;
      changed = true;
    }
    if (_categoryFilter != null) {
      _categoryFilter = null;
      changed = true;
    }
    if (changed) {
      notifyListeners();
      _refreshWithFilters();
    }
  }

  /// Pushes queued offline transactions and reloads the list. Called when the
  /// app resumes or the user switches back onto this screen.
  Future<void> syncNow() => transactionRepository.refresh();

  Future<bool> deleteTransaction(FinanceTransaction transaction) async {
    try {
      await transactionRepository.deleteTransaction(transaction);
      return true;
    } on DataFailure {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Sends the active time window and category to `GET /api/transactions` so
  /// backend-side filtering mirrors the chips the user selected.
  void _refreshWithFilters() {
    final range = _timeFilterToRange(_timeFilter, DateTime.now());
    unawaited(
      transactionRepository.refreshTransactions(
        from: range?.start,
        to: range?.end,
        category: _categoryFilter,
      ),
    );
  }

  _DateRange? _timeFilterToRange(TransactionTimeFilter filter, DateTime now) {
    switch (filter) {
      case TransactionTimeFilter.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0);
        return _DateRange(start: start, end: end);
      case TransactionTimeFilter.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 0);
        return _DateRange(start: start, end: end);
      case TransactionTimeFilter.all:
        return null;
    }
  }

  @override
  void dispose() {
    _txnSubscription?.cancel();
    _txnSubscription = null;
    _profileSubscription?.cancel();
    _profileSubscription = null;
    super.dispose();
  }
}
