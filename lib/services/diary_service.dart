import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/diary_entry.dart';

class DiaryService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ref {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('diary').doc(uid).collection('entries');
  }

  Stream<List<DiaryEntry>> stream() => _ref
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map(DiaryEntry.fromFirestore).toList());

  Future<void> save(DiaryEntry e) async {
    if (e.id.isEmpty) {
      await _ref.add(e.toMap());
    } else {
      await _ref.doc(e.id).update(e.toMap());
    }
  }

  Future<void> delete(String id) async => await _ref.doc(id).delete();
}
