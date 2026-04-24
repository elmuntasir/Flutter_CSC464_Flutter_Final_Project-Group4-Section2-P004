import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String? id;
  final String name;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final DateTime? createdAt;
  final String type; // 'income' or 'expense'

  Expense({
    this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.createdAt,
    this.type = 'expense',
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      name: data['name'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      type: data['type'] ?? 'expense',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'amount': amount,
      'category': category,
      'description': description,
      'date': Timestamp.fromDate(date),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'type': type,
    };
  }

  bool get isIncome => type == 'income';
}
