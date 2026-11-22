import '../../domain/entities/user_profile.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.currency,
    this.fullName,
    this.phoneNumber,
  });

  final String uid;
  final double balance;
  final double totalIncome;
  final double totalExpense;
  final String currency;
  final String? fullName;
  final String? phoneNumber;

  /// Maps a profile payload from the REST API, tolerating the usual field
  /// aliases (`id`/`_id`/`userId`/`uid`, `name`/`fullName`/`displayName`, …).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: _firstString(json, const ['id', '_id', 'userId', 'user_id', 'uid']) ??
          '',
      balance: _toDouble(json['balance']),
      totalIncome: _toDouble(json['totalIncome'] ?? json['total_income']),
      totalExpense: _toDouble(json['totalExpense'] ?? json['total_expense']),
      currency: _currency(json),
      fullName: _firstString(json, const [
        'fullName',
        'full_name',
        'name',
        'displayName',
        'display_name',
        'username',
      ]),
      phoneNumber: _firstString(json, const [
        'phoneNumber',
        'phone_number',
        'phone',
      ]),
    );
  }

  UserModel copyWith({
    String? uid,
    double? balance,
    double? totalIncome,
    double? totalExpense,
    String? currency,
    String? fullName,
    String? phoneNumber,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      balance: balance ?? this.balance,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      currency: currency ?? this.currency,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  UserProfile toEntity() {
    return UserProfile(
      uid: uid,
      balance: balance,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      currency: currency,
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
  }

  static String _currency(Map<String, dynamic> json) {
    final code = _firstString(json, const [
      'currency',
      'currencyCode',
      'currency_code',
    ]);
    return (code ?? 'BDT').toUpperCase();
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
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
