import '../../domain/entities/finance_transaction.dart';

/// Data-layer representation of a transaction, mapped to/from the REST API
/// payloads and the local SQLite cache rows.
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

  /// Maps a transaction payload from the REST API, tolerating the usual field
  /// aliases (`id`/`_id`/`transactionId`, `type`/`transactionType`, …).
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: _firstString(json, const [
            'id',
            '_id',
            'transactionId',
            'transaction_id',
          ]) ??
          '',
      userId: _firstString(json, const ['userId', 'user_id', 'uid']) ?? '',
      type: _type(json),
      amount: _toDouble(json['amount'] ?? json['value']),
      category: _firstString(json, const [
            'category',
            'categoryName',
            'category_name',
          ]) ??
          '',
      date: _toDate(json['date'] ?? json['createdAt'] ?? json['created_at']),
      note: _firstString(json, const ['note', 'description', 'details']),
    );
  }

  /// Restores a row from the local SQLite cache.
  factory TransactionModel.fromMap(Map<String, Object?> map) {
    return TransactionModel(
      id: (map['id'] as String?) ?? '',
      userId: (map['user_id'] as String?) ?? '',
      type: (map['type'] as String?) ?? TransactionType.expense.name,
      amount: _toDouble(map['amount']),
      category: (map['category'] as String?) ?? '',
      date: DateTime.fromMillisecondsSinceEpoch((map['date'] as int?) ?? 0),
      note: map['note'] as String?,
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

  /// Serialises to a row for the local SQLite cache. [pendingSync] marks rows
  /// that were created offline and still have to be pushed to the backend.
  Map<String, Object?> toMap({required bool pendingSync}) {
    return <String, Object?>{
      'id': id,
      'user_id': userId,
      'type': type,
      'amount': amount,
      'category': category,
      'date': date.millisecondsSinceEpoch,
      'note': note,
      'pending_sync': pendingSync ? 1 : 0,
    };
  }

  TransactionModel copyWith({String? id, String? userId}) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type,
      amount: amount,
      category: category,
      date: date,
      note: note,
    );
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

  static String _type(Map<String, dynamic> json) {
    final raw = _firstString(json, const [
          'type',
          'transactionType',
          'transaction_type',
        ]) ??
        TransactionType.expense.name;
    final normalized = raw.toLowerCase();
    if (normalized.contains('income') || normalized == 'credit') {
      return TransactionType.income.name;
    }
    return TransactionType.expense.name;
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _toDate(Object? value) {
    if (value is DateTime) return value;
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toLocal();
      final millis = int.tryParse(value);
      if (millis != null) return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String? _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is num) return '$value';
    }
    return null;
  }
}
