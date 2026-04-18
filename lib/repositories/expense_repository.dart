import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final CollectionReference _expensesCollection =
      FirebaseFirestore.instance.collection('expenses');

  // Create
  Future<void> addExpense(Expense expense) async {
    await _expensesCollection.add(expense.toFirestore());
  }

  // Read (Stream)
  Stream<List<Expense>> getExpenses() {
    return _expensesCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();
    });
  }

  // Update
  Future<void> updateExpense(Expense expense) async {
    if (expense.id != null) {
      await _expensesCollection.doc(expense.id).update(expense.toFirestore());
    }
  }

  // Delete
  Future<void> deleteExpense(String id) async {
    await _expensesCollection.doc(id).delete();
  }
}
