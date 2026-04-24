import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../models/user_model.dart';
import '../repositories/expense_repository.dart';
import '../repositories/user_repository.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expenseToEdit;
  const AddExpenseScreen({super.key, this.expenseToEdit});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  String _transactionType = 'expense';

  final Map<String, String> _defaultExpenseCategories = {
    'Food': '🍕',
    'Transport': '🚌',
    'Rent': '🏠',
    'Leisure': '🎮',
    'Health': '🏥',
    'Shopping': '🛍️',
    'Travel': '✈️',
    'Bills': '📄',
    'Others': '✨',
  };

  final Map<String, String> _defaultIncomeCategories = {
    'Salary': '💰',
    'Freelance': '💻',
    'Investment': '📈',
    'Gift': '🎁',
    'Refund': '🔄',
    'Sales': '🏷️',
    'Bonus': '🎊',
    'Rental': '🔑',
    'Others': '✨',
  };

  @override
  void initState() {
    super.initState();
    if (widget.expenseToEdit != null) {
      final e = widget.expenseToEdit!;
      _nameController.text = e.name;
      _amountController.text = e.amount.toString();
      _descriptionController.text = e.description;
      _selectedCategory = e.category;
      _selectedDate = e.date;
      _transactionType = e.type;
    }
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      final repository = ExpenseRepository();
      final expenseData = Expense(
        id: widget.expenseToEdit?.id,
        name: _nameController.text.isEmpty ? _selectedCategory : _nameController.text,
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        description: _descriptionController.text,
        date: _selectedDate,
        type: _transactionType,
      );

      if (widget.expenseToEdit != null) {
        await repository.updateExpense(expenseData);
      } else {
        await repository.addExpense(expenseData);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _showAddCategoryDialog(UserModel? user) {
    final nameController = TextEditingController();
    final emojiController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Custom ${_transactionType == 'expense' ? 'Expense' : 'Income'} Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Category Name', hintText: 'e.g. Gym'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emojiController,
              decoration: const InputDecoration(labelText: 'Emoji', hintText: 'Use your keyboard emoji'),
              maxLength: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && emojiController.text.isNotEmpty && user != null) {
                final updatedExpenseCats = Map<String, String>.from(user.customExpenseCategories);
                final updatedIncomeCats = Map<String, String>.from(user.customIncomeCategories);

                if (_transactionType == 'expense') {
                  updatedExpenseCats[nameController.text] = emojiController.text;
                } else {
                  updatedIncomeCats[nameController.text] = emojiController.text;
                }

                final updatedUser = UserModel(
                  uid: user.uid,
                  name: user.name,
                  gender: user.gender,
                  birthday: user.birthday,
                  country: user.country,
                  currencyCode: user.currencyCode,
                  profilePicUrl: user.profilePicUrl,
                  coverPicUrl: user.coverPicUrl,
                  customExpenseCategories: updatedExpenseCats,
                  customIncomeCategories: updatedIncomeCats,
                );

                await UserRepository().saveUserData(updatedUser);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: UserRepository().getUserData(),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final currency = user?.currencyCode ?? r'$';
        
        Map<String, String> currentCategories = {};
        if (_transactionType == 'expense') {
          currentCategories.addAll(_defaultExpenseCategories);
          if (user != null) currentCategories.addAll(user.customExpenseCategories);
        } else {
          currentCategories.addAll(_defaultIncomeCategories);
          if (user != null) currentCategories.addAll(user.customIncomeCategories);
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(widget.expenseToEdit != null 
              ? 'Edit ${_transactionType == 'expense' ? 'Expense' : 'Income'}'
              : 'Add ${_transactionType == 'expense' ? 'Expense' : 'Income'}'),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Amount Field
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currency,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 200,
                              child: TextFormField(
                                controller: _amountController,
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  hintText: '0.00',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  fillColor: Colors.transparent,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Enter amount';
                                  if (double.tryParse(value) == null) return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Type Selector
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              _buildTypeButton('expense', 'Expense', Icons.remove_circle_outline),
                              _buildTypeButton('income', 'Income', Icons.add_circle_outline),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title Input
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'What was this for?',
                      prefixIcon: Icon(Icons.edit_note),
                      labelText: 'Title (Optional)',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category Grid Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Category',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => _showAddCategoryDialog(user),
                        icon: const Icon(Icons.add_circle),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Category Grid (3x3)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: currentCategories.length,
                    itemBuilder: (context, index) {
                      final name = currentCategories.keys.elementAt(index);
                      final emoji = currentCategories.values.elementAt(index);
                      final isSelected = _selectedCategory == name;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = name),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              if (!isSelected)
                                BoxShadow(
                                  color: Colors.black.withAlpha(5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 28)),
                              const SizedBox(height: 4),
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Date and Description
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.calendar_today, size: 20),
                          ),
                          title: Text(
                            DateFormat('MMM dd, yyyy').format(_selectedDate),
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: _presentDatePicker,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Add a note...',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submitData,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        widget.expenseToEdit != null ? 'Update Record' : 'Save ${_transactionType == 'expense' ? 'Expense' : 'Income'}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeButton(String type, String label, IconData icon) {
    final isSelected = _transactionType == type;
    final color = type == 'expense' ? const Color(0xFFFF9B9B) : const Color(0xFF6DE8C3);
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _transactionType = type;
            _selectedCategory = type == 'expense' 
                ? _defaultExpenseCategories.keys.first 
                : _defaultIncomeCategories.keys.first;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.black54,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
