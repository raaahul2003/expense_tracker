import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ExpensePage extends StatefulWidget {
  @override
  _ExpensePageState createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController _amountController = TextEditingController();
  TextEditingController _noteController = TextEditingController();
  TextEditingController _customCategoryController = TextEditingController();
  String _selectedCategory = "Food";
  DateTime _selectedDate = DateTime.now();
  bool _isCustomCategory = false;

  List<Map<String, dynamic>> expenseCategories = [
    {"name": "Food", "icon": Icons.fastfood, "color": Colors.red},
    {"name": "Travel", "icon": Icons.directions_car, "color": Colors.blue},
    {"name": "Groceries", "icon": Icons.shopping_cart, "color": Colors.green},
    {"name": "Bills", "icon": Icons.receipt, "color": Colors.orange},
    {"name": "Custom", "icon": Icons.edit, "color": Colors.purple},
  ];

  Future<void> _addExpense(BuildContext context) async {
    if (_amountController.text.isEmpty) {
      print("🚨 Amount is empty. Cannot add expense.");
      return;
    }

    double amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      print("🚨 Invalid amount: $amount");
      return;
    }

    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      print("🚨 User ID is empty. Cannot add expense.");
      return;
    }

    String category = _isCustomCategory ? _customCategoryController.text.trim() : _selectedCategory;
    if (category.isEmpty) {
      print("🚨 Category is empty.");
      return;
    }

    print("✅ Adding expense: Amount: ₹$amount, Category: $category, Note: ${_noteController.text}");

    try {
      await _firestore.collection('users').doc(userId).collection('expenses').add({
        'amount': amount,
        'category': category,
        'note': _noteController.text,
        'date': _selectedDate,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("✅ Expense added to Firestore!");

      if (mounted) {
        Navigator.pop(context); // ✅ Ensure the dialog is closed after Firestore operation
      }

      // ✅ Clear fields after closing
      _amountController.clear();
      _noteController.clear();
      _customCategoryController.clear();

      setState(() {
        _isCustomCategory = false;
        _selectedCategory = "Food"; // Reset to default
      });

      print("✅ Fields cleared and UI updated.");
    } catch (e) {
      print("🚨 Error adding expense: $e");
    }
  }

  void _showAddExpenseDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental closing
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Add Expense", style: TextStyle(color: Colors.greenAccent)),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Amount",
                      labelStyle: TextStyle(color: Colors.greenAccent),
                      prefixIcon: Icon(Icons.attach_money, color: Colors.greenAccent),
                    ),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    dropdownColor: Colors.black,
                    items: expenseCategories.map<DropdownMenuItem<String>>((category) {
                      return DropdownMenuItem<String>(
                        value: category['name'],
                        child: Row(
                          children: [
                            Icon(category['icon'], color: category['color']),
                            SizedBox(width: 10),
                            Text(category['name'], style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() {
                        _selectedCategory = value!;
                        _isCustomCategory = value == "Custom";
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Category",
                      labelStyle: TextStyle(color: Colors.greenAccent),
                      prefixIcon: Icon(Icons.category, color: Colors.greenAccent),
                    ),
                  ),
                  if (_isCustomCategory) ...[
                    SizedBox(height: 10),
                    TextField(
                      controller: _customCategoryController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Enter Custom Category",
                        labelStyle: TextStyle(color: Colors.greenAccent),
                        prefixIcon: Icon(Icons.edit, color: Colors.greenAccent),
                      ),
                    ),
                  ],
                  SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Note (optional)",
                      labelStyle: TextStyle(color: Colors.greenAccent),
                      prefixIcon: Icon(Icons.edit, color: Colors.greenAccent),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2022),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setStateDialog(() => _selectedDate = picked);
                      }
                    },
                    child: Text(
                      "Date: ${DateFormat.yMMMd().format(_selectedDate)}",
                      style: TextStyle(color: Colors.greenAccent),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);  // ✅ Close the dialog when canceling
              },
              child: Text("Cancel", style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              onPressed: () => _addExpense(context),  // ✅ Calls _addExpense
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
              child: Text("Add", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }
  Widget _buildExpenseList() {
    String userId = _auth.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: Colors.greenAccent));

        var expenses = snapshot.data!.docs;

        if (expenses.isEmpty) {
          return Center(child: Text("No expenses added yet", style: TextStyle(color: Colors.white70)));
        }

        return ListView.builder(
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            var data = expenses[index].data() as Map<String, dynamic>;
            String categoryName = data['category'];

            var categoryData = expenseCategories.firstWhere(
                  (category) => category['name'] == categoryName,
              orElse: () => {"icon": Icons.category, "color": Colors.grey},
            );

            return Dismissible(
              key: Key(expenses[index].id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                color: Colors.red,
                padding: EdgeInsets.only(right: 20),
                child: Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) {
                _firestore.collection('users').doc(userId).collection('expenses').doc(expenses[index].id).delete();
              },
              child: Card(
                color: Colors.black,
                elevation: 2,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(categoryData['icon'], color: categoryData['color']),
                  title: Text("$categoryName - ₹${data['amount']}", style: TextStyle(color: Colors.white, fontSize: 16)),
                  subtitle: Text(DateFormat.yMMMd().format((data['date'] as Timestamp).toDate()), style: TextStyle(color: Colors.white70)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("Expenses", style: TextStyle(color: Colors.greenAccent)), backgroundColor: Colors.black),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => _showAddExpenseDialog(context),
            child: Text("Add Expense"),
          ),
          Expanded(child: _buildExpenseList()),
        ],
      ),
    );
  }
}