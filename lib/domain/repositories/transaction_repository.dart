import '../entities/finance_transaction.dart';

abstract class TransactionRepository {
  Stream<List<FinanceTransaction>> watchCurrentUserTransactions();

  /// Persists a new transaction. [userId] is never taken from the caller;
  /// implementations must write the current authenticated user's uid.
  Future<FinanceTransaction> addTransaction({
    required TransactionType type,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  });

  /// Atomically persists a new transaction AND updates the current user's
  /// totalIncome / totalExpense / balance in a single Firestore batch write.
  Future<FinanceTransaction> addTransactionWithUserUpdate({
    required TransactionType type,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  });
}
