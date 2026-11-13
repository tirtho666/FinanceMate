import '../entities/finance_transaction.dart';
import '../repositories/transaction_repository.dart';

class AddTransactionWithUserUpdate {
  const AddTransactionWithUserUpdate(this._repository);

  final TransactionRepository _repository;

  Future<FinanceTransaction> call({
    required TransactionType type,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) {
    return _repository.addTransactionWithUserUpdate(
      type: type,
      amount: amount,
      category: category,
      date: date,
      note: note,
    );
  }
}
