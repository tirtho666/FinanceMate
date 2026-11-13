import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../domain/entities/finance_transaction.dart';
import '../../../domain/failures/data_failure.dart';
import '../../models/transaction_model.dart';
import 'firestore_paths.dart';

class TransactionRemoteSource {
  TransactionRemoteSource({
    required FirebaseFirestore firestore,
    required this.auth,
  })  : _transactions = firestore.collection(FirestorePaths.transactions),
        _users = firestore.collection(FirestorePaths.users),
        _firestore = firestore;

  final CollectionReference<Map<String, dynamic>> _transactions;
  final CollectionReference<Map<String, dynamic>> _users;
  final FirebaseFirestore _firestore;
  final FirebaseAuth auth;

  Stream<List<TransactionModel>> watchCurrentUserTransactions() {
    final uid = auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return Stream<List<TransactionModel>>.value(const []);
    }
    return _transactions.where('userId', isEqualTo: uid).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs
          .map(TransactionModel.fromFirestore)
          .toList();
      items.sort((a, b) => b.date.compareTo(a.date));
      return List<TransactionModel>.unmodifiable(items);
    });
  }

  Future<TransactionModel> addTransaction({
    required TransactionType type,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    final uid = _requireUid();
    final docRef = _transactions.doc();
    final model = TransactionModel(
      id: docRef.id,
      userId: uid,
      type: type.name,
      amount: amount,
      category: category,
      date: date,
      note: note,
    );
    await docRef.set(model.toFirestore());
    return model;
  }

  Future<TransactionModel> addTransactionWithUserUpdate({
    required TransactionType type,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    final uid = _requireUid();
    final transactionDocRef = _transactions.doc();
    final userDocRef = _users.doc(uid);

    final model = TransactionModel(
      id: transactionDocRef.id,
      userId: uid,
      type: type.name,
      amount: amount,
      category: category,
      date: date,
      note: note,
    );

    final batch = _firestore.batch();
    batch.set(transactionDocRef, model.toFirestore());

    final isIncome = type == TransactionType.income;
    final balanceDelta = isIncome ? amount : -amount;
    final incomeDelta = isIncome ? amount : 0.0;
    final expenseDelta = isIncome ? 0.0 : amount;

    batch.set(
      userDocRef,
      <String, Object?>{
        'uid': uid,
        'balance': FieldValue.increment(balanceDelta),
        'totalIncome': FieldValue.increment(incomeDelta),
        'totalExpense': FieldValue.increment(expenseDelta),
        'currency': 'BDT',
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    return model;
  }

  // নতুন মেথড: ট্রানজেকশন ডিলিট এবং ব্যালেন্স অ্যাডজাস্ট করার জন্য
  Future<void> deleteTransactionWithUserUpdate(FinanceTransaction transaction) async {
    final uid = _requireUid();
    final transactionDocRef = _transactions.doc(transaction.id);
    final userDocRef = _users.doc(uid);

    final batch = _firestore.batch();
    batch.delete(transactionDocRef);

    final isIncome = transaction.type == TransactionType.income;
    
    // অ্যাড করার ঠিক উল্টো লজিক, যাতে ডিলিট করলে ব্যালেন্স ঠিক থাকে
    final balanceDelta = isIncome ? -transaction.amount : transaction.amount;
    final incomeDelta = isIncome ? -transaction.amount : 0.0;
    final expenseDelta = isIncome ? 0.0 : -transaction.amount;

    batch.set(
      userDocRef,
      <String, Object?>{
        'uid': uid,
        'balance': FieldValue.increment(balanceDelta),
        'totalIncome': FieldValue.increment(incomeDelta),
        'totalExpense': FieldValue.increment(expenseDelta),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  String _requireUid() {
    final uid = auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw const DataFailure('You must be signed in.');
    }
    return uid;
  }
}