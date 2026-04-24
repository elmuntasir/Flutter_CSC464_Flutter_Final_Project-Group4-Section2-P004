import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_model.dart';

/// All CRUD operations are scoped to the currently signed-in user.
/// Firestore path: users/{uid}/expenses/{expenseId}
/// This ensures no user can ever read or write another user's data.
class ExpenseRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns the current user's UID. Throws if not authenticated.
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  /// Reference to this user's expenses subcollection.
  CollectionReference get _collection =>
      _db.collection('users').doc(_uid).collection('expenses');

  // ── Create ────────────────────────────────────────────────────────────────
  Future<void> addExpense(Expense expense) async {
    await _collection.add(expense.toFirestore());
  }

  // ── Read (real-time stream) ───────────────────────────────────────────────
  Stream<List<Expense>> getExpenses() {
    return _collection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList());
  }

  // ── Update ────────────────────────────────────────────────────────────────
  Future<void> updateExpense(Expense expense) async {
    if (expense.id != null) {
      await _collection.doc(expense.id).update(expense.toFirestore());
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> deleteExpense(String id) async {
    await _collection.doc(id).delete();
  }
}
