import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';
import 'add_expense_screen.dart';
import 'profile_screen.dart';
import '../repositories/user_repository.dart';
import '../models/user_model.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final repository = ExpenseRepository();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: StreamBuilder<UserModel?>(
          stream: UserRepository().getUserData(),
          builder: (context, profileSnapshot) {
            final userProfile = profileSnapshot.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Expense Tracker',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  userProfile?.name.isNotEmpty == true
                      ? userProfile!.name
                      : (user.displayName?.isNotEmpty == true
                          ? user.displayName!
                          : user.email ?? ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer
                        .withAlpha(180),
                  ),
                ),
              ],
            );
          },
        ),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          StreamBuilder<UserModel?>(
            stream: UserRepository().getUserData(),
            builder: (context, snapshot) {
              final userProfile = snapshot.data;
              debugPrint('Home Screen - Profile Data: $userProfile');
              return IconButton(
                tooltip: 'Profile',
                icon: userProfile?.profilePicUrl != null
                    ? FutureBuilder<String>(
                        future: UserRepository().getLocalPath(userProfile!.profilePicUrl!),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return CircleAvatar(
                              radius: 14,
                              backgroundImage: FileImage(File(snapshot.data!)),
                            );
                          }
                          return const CircleAvatar(radius: 14);
                        },
                      )
                    : CircleAvatar(
                        radius: 14,
                        backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(50),
                        child: const Icon(Icons.person_outline, size: 18),
                      ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: UserRepository().getUserData(),
        builder: (context, profileSnapshot) {
          final userProfile = profileSnapshot.data;
          final currency = userProfile?.currencyCode ?? r'$';
          
          // Debugging (optional but helpful for the user to see in logs)
          debugPrint('User Profile Currency: ${userProfile?.currencyCode}');

          return StreamBuilder<List<Expense>>(
            stream: repository.getExpenses(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final expenses = snapshot.data ?? [];
              final totalExpense = expenses
                  .where((e) => e.type == 'expense')
                  .fold(0.0, (sum, item) => sum + item.amount);
              final totalIncome = expenses
                  .where((e) => e.type == 'income')
                  .fold(0.0, (sum, item) => sum + item.amount);

              return Column(
                children: [
                  _buildSummaryCard(context, totalIncome, totalExpense, user, expenses.length, userProfile),
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Recent Expenses',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Expanded(
                    child: expenses.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
                            itemCount: expenses.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final expense = expenses[index];
                              return TransactionCard(
                                expense: expense,
                                repository: repository,
                                currency: currency,
                                profile: userProfile,
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AddExpenseScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, double income, double expense, User user, int count, UserModel? profile) {
    final currency = profile?.currencyCode ?? r'$';
    final name = profile?.name ?? (user.displayName ?? user.email ?? 'My Account');
    final balance = income - expense;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withAlpha(77),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle_outlined,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(
                name,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Total Balance',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '$currency ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Income', income, Icons.arrow_upward, Colors.greenAccent),
              _buildSummaryItem('Expense', expense, Icons.arrow_downward, Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        Text(
          amount.toStringAsFixed(2),
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✨', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add one!',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class TransactionCard extends StatefulWidget {
  final Expense expense;
  final ExpenseRepository repository;
  final String currency;
  final UserModel? profile;

  const TransactionCard({
    super.key,
    required this.expense,
    required this.repository,
    required this.currency,
    this.profile,
  });

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
  bool _isExpanded = false;

  String _getEmoji(String category, UserModel? profile) {
    if (profile != null) {
      if (profile.customExpenseCategories.containsKey(category)) {
        return profile.customExpenseCategories[category]!;
      }
      if (profile.customIncomeCategories.containsKey(category)) {
        return profile.customIncomeCategories[category]!;
      }
    }
    final Map<String, String> emojiMap = {
      'Food': '🍕', 'Transport': '🚌', 'Rent': '🏠', 'Leisure': '🎮',
      'Health': '🏥', 'Shopping': '🛍️', 'Travel': '✈️', 'Bills': '📄',
      'Salary': '💰', 'Freelance': '💻', 'Investment': '📈', 'Gift': '🎁',
      'Refund': '🔄', 'Sales': '🏷️', 'Bonus': '🎊', 'Rental': '🔑', 'Others': '✨',
    };
    return emojiMap[category] ?? '✨';
  }

  @override
  Widget build(BuildContext context) {
    final expense = widget.expense;
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(_isExpanded ? 20 : 10),
              blurRadius: _isExpanded ? 12 : 8,
              offset: Offset(0, _isExpanded ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: expense.isIncome 
                      ? const Color(0xFF6DE8C3).withAlpha(40) 
                      : const Color(0xFFFF9B9B).withAlpha(40),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(_getEmoji(expense.category, widget.profile), style: const TextStyle(fontSize: 24)),
                ),
              ),
              title: Text(expense.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text(DateFormat('MMM dd, hh:mm a').format(expense.date), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${expense.isIncome ? '+' : '-'} ${widget.currency} ${expense.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16,
                      color: expense.isIncome ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(expense.category, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            ),
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddExpenseScreen(expenseToEdit: expense),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        _showDeleteDialog(context, widget.repository, expense);
                      },
                      icon: const Icon(Icons.delete_outline, size: 20),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ExpenseRepository repository, Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Transaction?'),
        content: Text('Are you sure you want to delete "${expense.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              repository.deleteExpense(expense.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
