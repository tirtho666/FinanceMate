import 'package:flutter/foundation.dart';

enum TransactionType { expense, income }

@immutable
class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
  });

  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;
}
