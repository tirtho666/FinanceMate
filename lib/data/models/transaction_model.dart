import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/finance_transaction.dart';

class TransactionModel {
  const TransactionModel({
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
  final String type;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;

  factory TransactionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return TransactionModel(
      id: data['id'] as String? ?? doc.id,
      userId: data['userId'] as String? ?? '',
      type: data['type'] as String? ?? TransactionType.expense.name,
      amount: _toDouble(data['amount']),
      category: data['category'] as String? ?? '',
      date: _toDate(data['date']),
      note: data['note'] as String?,
    );
  }

  factory TransactionModel.fromEntity(FinanceTransaction transaction) {
    return TransactionModel(
      id: transaction.id,
      userId: transaction.userId,
      type: transaction.type.name,
      amount: transaction.amount,
      category: transaction.category,
      date: transaction.date,
      note: transaction.note,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date.toUtc()),
      'note': note,
    };
  }

  FinanceTransaction toEntity() {
    return FinanceTransaction(
      id: id,
      userId: userId,
      type: type == TransactionType.income.name
          ? TransactionType.income
          : TransactionType.expense,
      amount: amount,
      category: category,
      date: date,
      note: note,
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  static DateTime _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
