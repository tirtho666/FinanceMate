import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return UserModel(
      uid: data['uid'] as String? ?? doc.id,
      balance: _toDouble(data['balance']),
      totalIncome: _toDouble(data['totalIncome']),
      totalExpense: _toDouble(data['totalExpense']),
      currency: data['currency'] as String? ?? 'BDT',
      fullName: data['fullName'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
    );
  }

  factory UserModel.fromEntity(UserProfile profile) {
    return UserModel(
      uid: profile.uid,
      balance: profile.balance,
      totalIncome: profile.totalIncome,
      totalExpense: profile.totalExpense,
      currency: profile.currency,
      fullName: profile.fullName,
      phoneNumber: profile.phoneNumber,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'balance': balance,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'currency': currency,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
    };
  }

  Map<String, dynamic> toFirestorePartialUpdate() {
    return {
      'currency': currency,
      if (fullName != null) 'fullName': fullName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    };
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

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return 0;
  }
}
