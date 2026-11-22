import 'package:flutter/foundation.dart';

/// Aggregated totals for the signed-in user, as returned by the backend's
/// `GET /api/transactions/summary` endpoint and cached locally for offline use.
@immutable
class TransactionSummary {
  const TransactionSummary({
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
  });

  const TransactionSummary.empty()
      : balance = 0,
        totalIncome = 0,
        totalExpense = 0;

  final double balance;
  final double totalIncome;
  final double totalExpense;
}
