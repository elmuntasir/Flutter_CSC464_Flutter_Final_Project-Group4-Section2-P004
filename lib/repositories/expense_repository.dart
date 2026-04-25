import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  static final ExpenseRepository _instance = ExpenseRepository._internal();

  ExpenseRepository._internal();

  factory ExpenseRepository() => _instance;

  CollectionReference<Map<String, dynamic>>? get _expensesCollection {
    if (Firebase.apps.isEmpty) {
      debugPrint(
        'Firebase is not initialized; expense collection unavailable.',
      );
      return null;
    }
    return FirebaseFirestore.instance.collection('expenses');
  }

  // Create
  Future<void> addExpense(Expense expense) async {
    final collection = _expensesCollection;
    if (collection == null) {
      throw StateError('Firestore is not initialized. Cannot add expense.');
    }

    try {
      await collection.add(expense.toFirestore());
      debugPrint('Expense added successfully');
    } catch (e) {
      debugPrint('Error adding expense: $e');
      rethrow;
    }
  }

  // Read (Stream)
  Stream<List<Expense>> getExpenses() {
    final collection = _expensesCollection;
    if (collection == null) {
      debugPrint(
        'Firebase is not initialized; returning empty expense stream.',
      );
      return const Stream<List<Expense>>.empty();
    }

    return collection
        .orderBy('date', descending: true)
        .limit(100)
        .snapshots()
        .map<List<Expense>>((snapshot) {
          try {
            debugPrint(
              'Received ${snapshot.docs.length} documents from Firestore',
            );
            final expenses = snapshot.docs
                .map((doc) {
                  try {
                    return Expense.fromFirestore(doc);
                  } catch (e) {
                    debugPrint('Error parsing expense from doc ${doc.id}: $e');
                    debugPrint('Doc data: ${doc.data()}');
                    return null;
                  }
                })
                .whereType<Expense>()
                .toList();
            debugPrint('Successfully parsed ${expenses.length} expenses');
            return expenses;
          } catch (e) {
            debugPrint('Error in map function: $e');
            return [];
          }
        });
  }

  // Update
  Future<void> updateExpense(Expense expense) async {
    final collection = _expensesCollection;
    if (collection == null) {
      throw StateError('Firestore is not initialized. Cannot update expense.');
    }

    try {
      if (expense.id != null) {
        await collection.doc(expense.id).update(expense.toFirestore());
        debugPrint('Expense updated successfully');
      }
    } catch (e) {
      debugPrint('Error updating expense: $e');
      rethrow;
    }
  }

  // Delete
  Future<void> deleteExpense(String id) async {
    final collection = _expensesCollection;
    if (collection == null) {
      throw StateError('Firestore is not initialized. Cannot delete expense.');
    }

    try {
      await collection.doc(id).delete();
      debugPrint('Expense deleted successfully');
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      rethrow;
    }
  }
}
