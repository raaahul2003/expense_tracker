import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String selectedFilter = "Monthly"; // Default
  DateTimeRange? selectedDateRange;
  Map<String, double> categoryTotals = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserExpenses();
  }

  Future<void> _fetchUserExpenses() async {
    setState(() => isLoading = true);
    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    DateTime now = DateTime.now();
    DateTime startDate, endDate;

    if (selectedDateRange != null) {
      startDate = selectedDateRange!.start;
      endDate = selectedDateRange!.end;
    } else {
      if (selectedFilter == "Weekly") {
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = startDate.add(Duration(days: 6));
      } else if (selectedFilter == "Monthly") {
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
      } else {
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31);
      }
    }

    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();

    Map<String, double> tempTotals = {};

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String category = data['category'];
      double amount = (data['amount'] ?? 0).toDouble();

      if (tempTotals.containsKey(category)) {
        tempTotals[category] = tempTotals[category]! + amount;
      } else {
        tempTotals[category] = amount;
      }
    }

    setState(() {
      categoryTotals = tempTotals;
      isLoading = false;
    });
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Expense Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Category', 'Amount'],
              data: categoryTotals.entries.map((entry) {
                return [
                  entry.key,
                  "₹${entry.value.toStringAsFixed(2)}",
                ];
              }).toList(),
            ),
          ],
        ),
      ),
    );

    final output = await getExternalStorageDirectory();
    final file = File("${output!.path}/Expense_Report.pdf");

    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF saved: ${file.path}")));
    Printing.sharePdf(bytes: await pdf.save(), filename: 'Expense_Report.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Reports", style: TextStyle(color: Colors.greenAccent)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.date_range, color: Colors.greenAccent),
            onPressed: () async {
              DateTimeRange? picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2022),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => selectedDateRange = picked);
                _fetchUserExpenses();
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exportToPDF,
        label: Text("Export PDF"),
        icon: Icon(Icons.picture_as_pdf),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFilterButtons(),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator(color: Colors.greenAccent)
                : Expanded(
              child: Column(
                children: [
                  _buildPieChart(),
                  SizedBox(height: 20),
                  _buildCategoryList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ["Weekly", "Monthly", "Yearly"].map((filter) {
        return ElevatedButton(
          onPressed: () {
            setState(() {
              selectedFilter = filter;
              selectedDateRange = null;
            });
            _fetchUserExpenses();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedFilter == filter ? Colors.greenAccent : Colors.white.withOpacity(0.2),
          ),
          child: Text(filter, style: TextStyle(color: Colors.black)),
        );
      }).toList(),
    );
  }

  Widget _buildPieChart() {
    if (categoryTotals.isEmpty) {
      return Text("No data available", style: TextStyle(color: Colors.white70));
    }

    return Column(
      children: [
        Text("Expense Distribution", style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Container(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: categoryTotals.entries.map((entry) {
                return PieChartSectionData(
                  value: entry.value,
                  title: "${entry.key}\n₹${entry.value.toStringAsFixed(2)}",
                  color: _getCategoryColor(entry.key),
                  radius: 60,
                  titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                );
              }).toList(),
              centerSpaceRadius: 50,
              sectionsSpace: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList() {
    return Expanded(
      child: ListView.builder(
        itemCount: categoryTotals.length,
        itemBuilder: (context, index) {
          String category = categoryTotals.keys.elementAt(index);
          return ListTile(
            leading: Icon(Icons.category, color: _getCategoryColor(category)),
            title: Text(category, style: TextStyle(color: Colors.white)),
            trailing: Text('₹${categoryTotals[category]?.toStringAsFixed(2) ?? '0.00'}', style: TextStyle(color: Colors.greenAccent)),
          );
        },
      ),
    );
  }

  Color _getCategoryColor(String category) {
    return Colors.primaries[category.hashCode % Colors.primaries.length];
  }
}
