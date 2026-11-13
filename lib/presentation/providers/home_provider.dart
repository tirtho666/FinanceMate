import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/finance_transaction.dart';
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

  String? _uid;
  UserProfile? _profile;
  List<FinanceTransaction> _transactions = const [];
  bool _isLoading = true;
  String? _errorMessage;

  UserProfile get profile =>
      _profile ??
      const UserProfile(
        uid: '',
        balance: 0,
        totalIncome: 0,
        totalExpense: 0,
        currency: 'BDT',
      );

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
    _profileSubscription = null;
    _transactionsSubscription = null;
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
