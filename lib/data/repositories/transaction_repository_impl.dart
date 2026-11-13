import '../../domain/entities/finance_transaction.dart';
import '../../domain/failures/data_failure.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../sources/remote/transaction_remote_source.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this._remoteSource);

  final TransactionRemoteSource _remoteSource;

  @override
  Stream<List<FinanceTransaction>> watchCurrentUserTransactions() {
    return _remoteSource.watchCurrentUserTransactions().map(
      (items) => items.map((item) => item.toEntity()).toList(growable: false),
    );
  }

  @override
  Future<FinanceTransaction> addTransaction({
    required TransactionType type,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    try {
      final stored = await _remoteSource.addTransaction(
        type: type,
        amount: amount,
        category: category,
        date: date,
        note: note,
      );
      return stored.toEntity();
    } on DataFailure {
      rethrow;
    } catch (_) {
      throw const DataFailure('Could not save the transaction.');
    }
  }

  @override
  Future<FinanceTransaction> addTransactionWithUserUpdate({
    required TransactionType type,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    try {
      final stored = await _remoteSource.addTransactionWithUserUpdate(
        type: type,
        amount: amount,
        category: category,
        date: date,
        note: note,
      );
      return stored.toEntity();
    } on DataFailure {
      rethrow;
    } catch (_) {
      throw const DataFailure('Could not save the transaction.');
    }
  }
}
