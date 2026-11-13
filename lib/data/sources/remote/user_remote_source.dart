import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../domain/failures/data_failure.dart';
import '../../models/user_model.dart';
import 'firestore_paths.dart';

class UserRemoteSource {
  UserRemoteSource({
    required FirebaseFirestore firestore,
    required this.auth,
  }) : _users = firestore.collection(FirestorePaths.users);

  final CollectionReference<Map<String, dynamic>> _users;
  final FirebaseAuth auth;

  Stream<UserModel?> watchCurrentUser() {
    final uid = auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return Stream<UserModel?>.value(null);
    }
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<UserModel?> getCurrentUser() async {
    final uid = _requireUid();
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<UserModel> ensureCurrentUserProfile({String currency = 'BDT'}) async {
    final uid = _requireUid();
    final docRef = _users.doc(uid);
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      final existing = UserModel.fromFirestore(snapshot);
      final displayName = auth.currentUser?.displayName;
      if (existing.fullName == null && displayName != null && displayName.isNotEmpty) {
        await docRef.update({'fullName': displayName});
        final refreshed = await docRef.get();
        return UserModel.fromFirestore(refreshed);
      }
      return existing;
    }

    final profile = UserModel(
      uid: uid,
      balance: 0,
      totalIncome: 0,
      totalExpense: 0,
      currency: currency,
      fullName: auth.currentUser?.displayName,
    );
    await docRef.set(profile.toFirestore());
    return profile;
  }

  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
  }) async {
    final uid = _requireUid();
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['fullName'] = fullName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (updates.isEmpty) return;
      await _users.doc(uid).set(updates, SetOptions(merge: true));
    } on DataFailure {
      rethrow;
    } catch (_) {
      throw const DataFailure('Could not update your profile.');
    }
  }

  Future<void> updateCurrency(String currency) async {
    final uid = _requireUid();
    try {
      await _users.doc(uid).set(
        {'currency': currency},
        SetOptions(merge: true),
      );
    } on DataFailure {
      rethrow;
    } catch (_) {
      throw const DataFailure('Could not update your currency.');
    }
  }

  // নতুন মেথড: লক স্ক্রিনের পাসওয়ার্ড ভেরিফাই করার জন্য
  Future<bool> verifyCurrentPassword(String password) async {
    final user = auth.currentUser;
    if (user == null || user.email == null) return false;
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _requireUid() {
    final uid = auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw const DataFailure('You must be signed in.');
    }
    return uid;
  }
}