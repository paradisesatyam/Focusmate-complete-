import 'package:cloud_firestore/cloud_firestore.dart';

class FocusSession {
  final String id;
  final int durationMinutes;
  final DateTime date;

  const FocusSession({required this.id, required this.durationMinutes, required this.date});

  factory FocusSession.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FocusSession(
      id: doc.id,
      durationMinutes: d['durationMinutes'] ?? 0,
      date: (d['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'durationMinutes': durationMinutes,
    'date': Timestamp.fromDate(date),
  };
}
