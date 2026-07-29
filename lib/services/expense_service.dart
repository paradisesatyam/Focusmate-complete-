import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ref {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('expenses').doc(uid).collection('userExpenses');
  }

  Stream<List<Expense>> stream() => _ref
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Expense.fromFirestore).toList());

  Future<void> add(Expense e) async => await _ref.add(e.toMap());
  Future<void> delete(String id) async => await _ref.doc(id).delete();
}
