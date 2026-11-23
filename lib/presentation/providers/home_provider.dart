import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/finance_transaction.dart';
import '../../domain/entities/transaction_summary.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/user_repository.dart';

class HomeProvider extends ChangeNotifier {
  HomeProvider({
    required this.userRepository,
    required this.transactionRepository,
  });

  final UserRepository userRepository;
  final TransactionRepository transactionRepository;

  StreamSubscription<UserProfile?>? _profileSubscription;
  StreamSubscription<List<FinanceTransaction>>? _transactionsSubscription;
  StreamSubscription<TransactionSummary?>? _summarySubscription;

  String? _uid;
  UserProfile? _profile;
  TransactionSummary? _summary;
  List<FinanceTransaction> _transactions = const [];
  bool _isLoading = true;
  String? _errorMessage;

  /// Profile identity (name, currency) combined with live totals calculated
  /// directly from the active transactions list so adding or deleting any
  /// item updates Balance, Income, and Expense immediately.
  UserProfile get profile {
    final base =
        _profile ??
        const UserProfile(
          uid: '',
          balance: 0,
          totalIncome: 0,
          totalExpense: 0,
          currency: 'BDT',
        );

    if (_isLoading && _transactions.isEmpty) {
      final summary = _summary;
      if (summary == null) return base;
      return UserProfile(
        uid: base.uid,
        balance: summary.balance,
        totalIncome: summary.totalIncome,
        totalExpense: summary.totalExpense,
        currency: base.currency,
        fullName: base.fullName,
        phoneNumber: base.phoneNumber,
      );
    }

    var income = 0.0;
    var expense = 0.0;
    for (final txn in _transactions) {
      if (txn.type == TransactionType.income) {
        income += txn.amount;
      } else {
        expense += txn.amount;
      }
    }

    return UserProfile(
      uid: base.uid,
      balance: income - expense,
      totalIncome: income,
      totalExpense: expense,
      currency: base.currency,
      fullName: base.fullName,
      phoneNumber: base.phoneNumber,
    );
  }

  List<FinanceTransaction> get recentTransactions =>
      _transactions.take(5).toList(growable: false);

  bool get hasTransactions => _transactions.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void bindUid(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _cancelSubscriptions();

    if (uid == null || uid.isEmpty) {
      _profile = null;
      _summary = null;
      _transactions = const [];
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    _startListening();
  }

  /// Pushes queued offline transactions and reloads the overview. Called when
  /// the app resumes or the user returns to a data screen.
  Future<void> syncNow() => transactionRepository.refresh();

  Future<void> _startListening() async {
    try {
      await userRepository.ensureCurrentUserProfile();
    } catch (error) {
      _errorMessage = error.toString();
    }

    _profileSubscription = userRepository.watchCurrentUser().listen(
      (profile) {
        _profile = profile;
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    _summarySubscription = transactionRepository.watchSummary().listen(
      (summary) {
        _summary = summary;
        notifyListeners();
      },
      onError: (Object _) {
        // Keep the profile totals when the summary cannot be loaded.
      },
    );

    _transactionsSubscription = transactionRepository
        .watchCurrentUserTransactions()
        .listen(
          (transactions) {
            _transactions = transactions;
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

  void _cancelSubscriptions() {
    _profileSubscription?.cancel();
    _transactionsSubscription?.cancel();
    _summarySubscription?.cancel();
    _profileSubscription = null;
    _transactionsSubscription = null;
    _summarySubscription = null;
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}