import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IncomePage extends StatefulWidget {
  @override
  _IncomePageState createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedSource = 'Salary';
  bool _isCustomCategory = false;

  final List<Map<String, dynamic>> _sources = [
    {'name': 'Salary', 'icon': Icons.attach_money},
    {'name': 'Freelance', 'icon': Icons.work},
    {'name': 'Business', 'icon': Icons.business},
    {'name': 'Investment', 'icon': Icons.trending_up},
    {'name': 'Custom', 'icon': Icons.create}, // Allows custom category input
  ];

  Future<void> _addIncome() async {
    double amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount!')),
      );
      return;
    }

    String category = _isCustomCategory && _customCategoryController.text.isNotEmpty
        ? _customCategoryController.text
        : _selectedSource;

    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a category name!')),
      );
      return;
    }

    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in!')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('income')
          .add({
        'source': category,
        'amount': amount,
        'date': _selectedDate,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Income added successfully!')),
      );

      setState(() {
        _amountController.clear();
        _customCategoryController.clear();
        _selectedDate = DateTime.now();
        _selectedSource = 'Salary';
        _isCustomCategory = false;
      });
    } catch (e) {
      print("Error saving income: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add income. Try again!')),
      );
    }
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _deleteIncome(String docId) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('income')
        .doc(docId)
        .delete();
  }

  Widget _buildIncomeList() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Center(child: Text("User not logged in"));

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('income')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        return ListView(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: snapshot.data!.docs.map((doc) {
            return Dismissible(
              key: Key(doc.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20),
                color: Colors.red,
                child: Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) {
                _deleteIncome(doc.id);
              },
              child: Card(
                margin: EdgeInsets.symmetric(vertical: 5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: Icon(Icons.attach_money, color: Colors.green),
                  title: Text("${doc['source']}"),
                  subtitle: Text("₹${doc['amount']} - ${DateFormat.yMMMd().format(doc['date'].toDate())}"),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _deleteIncome(doc.id);
                    },
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Income Tracker'), backgroundColor: Colors.black),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Input Field (White Input Text)
              TextField(
                controller: _amountController,
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.attach_money, color: Colors.greenAccent),
                  hintText: 'Enter Amount',
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedSource,
                dropdownColor: Colors.black,
                icon: Icon(Icons.arrow_drop_down, color: Colors.greenAccent),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                style: TextStyle(color: Colors.white),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSource = newValue!;
                    _isCustomCategory = newValue == "Custom";
                  });
                },
                items: _sources.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['name'],
                    child: Row(children: [Icon(item['icon'], color: Colors.greenAccent), SizedBox(width: 10), Text(item['name'])]),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),

              // Custom Category Input (Only Visible When "Custom" is Selected)
              if (_isCustomCategory)
                TextField(
                  controller: _customCategoryController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter Custom Category',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              SizedBox(height: 16),

              // Date Picker Button
              TextButton.icon(
                icon: Icon(Icons.calendar_today, color: Colors.greenAccent),
                label: Text(DateFormat('yyyy-MM-dd').format(_selectedDate), style: TextStyle(color: Colors.white)),
                onPressed: _pickDate,
              ),
              SizedBox(height: 16),

              // Add Income Button
              ElevatedButton(
                onPressed: _addIncome,
                child: Text("Add Income"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
              ),

              SizedBox(height: 20),
              _buildIncomeList(),
            ],
          ),
        ),
      ),
    );
  }
}
