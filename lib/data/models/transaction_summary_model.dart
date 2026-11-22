import '../../domain/entities/transaction_summary.dart';

/// Data-layer representation of the totals returned by
/// `GET /api/transactions/summary`, also cached in the local SQLite database.
class TransactionSummaryModel {
  const TransactionSummaryModel({
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
  });

  final double balance;
  final double totalIncome;
  final double totalExpense;

  /// Maps a summary payload, tolerating snake_case aliases. When the backend
  /// omits the balance it is derived from income − expense.
  factory TransactionSummaryModel.fromJson(Map<String, dynamic> json) {
    final income = _toDouble(
      json['totalIncome'] ?? json['total_income'] ?? json['income'],
    );
    final expense = _toDouble(
      json['totalExpense'] ?? json['total_expense'] ?? json['expense'],
    );
    final rawBalance =
        json['balance'] ?? json['totalBalance'] ?? json['total_balance'];
    return TransactionSummaryModel(
      balance: rawBalance == null ? income - expense : _toDouble(rawBalance),
      totalIncome: income,
      totalExpense: expense,
    );
  }

  /// Restores the cached row.
  factory TransactionSummaryModel.fromMap(Map<String, Object?> map) {
    return TransactionSummaryModel(
      balance: _toDouble(map['balance']),
      totalIncome: _toDouble(map['total_income']),
      totalExpense: _toDouble(map['total_expense']),
    );
  }

  Map<String, Object?> toMap(String userId) {
    return <String, Object?>{
      'user_id': userId,
      'balance': balance,
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  TransactionSummary toEntity() {
    return TransactionSummary(
      balance: balance,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
