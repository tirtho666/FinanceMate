import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  const UserProfile({
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
}
