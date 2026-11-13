import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/finance_transaction.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/user_repository.dart';
// Data layer থেকে Remote Source ইমপোর্ট করা হলো Delete মেথডের জন্য
import '../../data/sources/remote/transaction_remote_source.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  List<FinanceTransaction> get filteredTransactions {
    final now = DateTime.now();
    final range = _timeFilterToRange(_timeFilter, now);
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
  }

  void setCategoryFilter(String? category) {
    final trimmed = category?.trim();
    final newVal = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    if (_categoryFilter == newVal) return;
    _categoryFilter = newVal;
    notifyListeners();
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
    if (changed) notifyListeners();
  }

  // নতুন মেথড: UI থেকে কল করে ডিলিট করার জন্য
  Future<bool> deleteTransaction(FinanceTransaction transaction) async {
    try {
      final remoteSource = TransactionRemoteSource(
        firestore: FirebaseFirestore.instance,
        auth: FirebaseAuth.instance,
      );
      await remoteSource.deleteTransactionWithUserUpdate(transaction);
      return true;
    } catch (e) {
      return false;
    }
  }

  _DateRange? _timeFilterToRange(
    TransactionTimeFilter filter,
    DateTime now,
  ) {
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