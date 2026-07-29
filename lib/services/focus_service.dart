import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/focus_session.dart';

class FocusService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ref {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('focus').doc(uid).collection('sessions');
  }

  Stream<List<FocusSession>> stream() => _ref
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map(FocusSession.fromFirestore).toList());

  Future<void> save(int minutes) async => await _ref.add(
    FocusSession(id: '', durationMinutes: minutes, date: DateTime.now()).toMap(),
  );
}
