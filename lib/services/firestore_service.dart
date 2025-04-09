import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add an expense
  Future<void> addExpense(String category, double amount, DateTime date) async {
    await _db.collection("expenses").add({
      "category": category,
      "amount": amount,
      "date": date.toIso8601String(),
    });
  }

  // Retrieve expenses
  Stream<List<Map<String, dynamic>>> getExpenses() {
    return _db.collection("expenses").orderBy("date", descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Delete an expense
  Future<void> deleteExpense(String docId) async {
    await _db.collection("expenses").doc(docId).delete();
  }
}
