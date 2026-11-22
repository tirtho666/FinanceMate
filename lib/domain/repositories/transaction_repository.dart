import '../entities/finance_transaction.dart';
import '../entities/transaction_summary.dart';

/// Contract for the transaction feature.
///
/// Implementations are backed by the FinanceMate Node.js + PostgreSQL REST API,
/// cache the last successful response in SQLite so the UI renders instantly
/// (and fully offline), and queue writes made while offline so they can be
/// replayed as soon as the backend is reachable again.
abstract class TransactionRepository {
  /// Emits the cached transactions immediately, then again on every local
  /// change (offline write, sync, or a successful refresh from the backend).
  Stream<List<FinanceTransaction>> watchCurrentUserTransactions();

  /// Emits the cached summary adjusted for anything still queued offline, or
  /// `null` while no summary is known yet (the profile totals are used then).
  Stream<TransactionSummary?> watchSummary();

  /// Pushes queued writes and reloads the transactions + summary. Used on app
  /// start, resume and screen refreshes.
  Future<void> refresh();

  /// Replays every locally queued transaction via `POST /api/transactions` and
  /// clears its `pending_sync` flag when the backend accepts it.
  Future<void> syncPendingTransactions();

  /// Reloads the cached list from `GET /api/transactions`, narrowing the request
  /// with the active UI filters. Offline, the cached list is kept as is.
  Future<void> refreshTransactions({
    DateTime? from,
    DateTime? to,
    String? category,
  });

  /// Persists a new transaction through `POST /api/transactions`. When the
  /// backend is unreachable the transaction is queued locally and synced later.
  Future<FinanceTransaction> addTransaction({
    required TransactionType type,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  });

  /// Persists a new transaction together with the resulting user totals. The
  /// backend applies both atomically, so this maps to the same insert endpoint
  /// as [addTransaction].
  Future<FinanceTransaction> addTransactionWithUserUpdate({
    required TransactionType type,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  });

  /// Updates an existing transaction via `PUT /api/transactions/:id`.
  Future<FinanceTransaction> updateTransaction({
    required String id,
    required TransactionType type,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  });

  /// Removes a transaction via `DELETE /api/transactions/:id`. Transactions
  /// that never reached the backend are simply dropped from the local queue.
  Future<void> deleteTransaction(FinanceTransaction transaction);
}
