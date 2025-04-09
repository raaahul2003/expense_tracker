import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import 'income_screen.dart';
import 'expense_screen.dart';
import 'settings_screen.dart';
import 'reports_screen.dart';
import 'profile_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 🔹 Stream for real-time profile updates
  Stream<DocumentSnapshot> _userProfileStream() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const Stream.empty();
    return FirebaseFirestore.instance.collection('users').doc(userId).snapshots();
  }

  /// 🔹 Combined Stream for income & expense
  Stream<Map<String, double>> getIncomeAndExpenseStream() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    Stream<QuerySnapshot> incomeStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('income')
        .orderBy('date', descending: true)
        .snapshots();

    Stream<QuerySnapshot> expenseStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots();

    return Rx.combineLatest2(
      incomeStream,
      expenseStream,
          (QuerySnapshot incomeSnap, QuerySnapshot expenseSnap) {
        double totalIncome = incomeSnap.docs.fold(
          0.0,
              (sum, doc) => sum + (doc['amount'] as num).toDouble(),
        );

        double totalExpense = expenseSnap.docs.fold(
          0.0,
              (sum, doc) => sum + (doc['amount'] as num).toDouble(),
        );

        return {
          "income": totalIncome,
          "expense": totalExpense,
        };
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Expense Tracker", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.greenAccent),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔹 Real-time Profile
            StreamBuilder<DocumentSnapshot>(
              stream: _userProfileStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildHeader("User", "assets/avatar_he.png");
                }
                var userDoc = snapshot.data!;
                String userName = userDoc['name'] ?? "User";
                String profilePic = userDoc['avatar'] == "he"
                    ? "assets/avatar_he.png"
                    : "assets/avatar_she.png";
                return _buildHeader(userName, profilePic);
              },
            ),
            SizedBox(height: 20),

            /// 🔹 Real-time Income & Expense
            StreamBuilder<Map<String, double>>(
              stream: getIncomeAndExpenseStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator(color: Colors.greenAccent);
                }

                double income = snapshot.data!['income']!;
                double expense = snapshot.data!['expense']!;
                double balance = income - expense;

                return Column(
                  children: [
                    _buildBalanceCard(balance),
                    SizedBox(height: 20),
                    _buildIncomeExpenseRow(income, expense),
                    SizedBox(height: 30),
                    _buildNavigationButtons(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String userName, String profilePic) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileSettingsScreen()),
            );
          },
          child: CircleAvatar(
            radius: 35,
            backgroundColor: Colors.transparent,
            child: ClipOval(
              child: Image.asset(
                profilePic,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hello,", style: TextStyle(color: Colors.white70, fontSize: 18)),
            Text(userName, style: TextStyle(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.greenAccent, Colors.blueAccent]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text("Total Balance", style: TextStyle(color: Colors.black87, fontSize: 18)),
          SizedBox(height: 5),
          Text("₹$balance", style: TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseRow(double income, double expense) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildIncomeExpenseCard("Income", income, Colors.green, Icons.arrow_upward),
        _buildIncomeExpenseCard("Expenses", expense, Colors.red, Icons.arrow_downward),
      ],
    );
  }

  Widget _buildIncomeExpenseCard(String title, double amount, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 5)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(height: 5),
            Text(title, style: TextStyle(color: Colors.white70, fontSize: 16)),
            SizedBox(height: 5),
            Text("₹$amount", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildIconButton(Icons.attach_money, "Income", Colors.greenAccent, IncomePage()),
        _buildIconButton(Icons.shopping_cart, "Expense", Colors.redAccent, ExpensePage()),
        _buildIconButton(Icons.bar_chart, "Reports", Colors.blueAccent, ReportsScreen()),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, String label, Color color, Widget page) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => page));
          },
          child: CircleAvatar(
            radius: 30,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        SizedBox(height: 5),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }
}
