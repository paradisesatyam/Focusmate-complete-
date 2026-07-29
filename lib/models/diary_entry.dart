import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryEntry {
  final String id;
  final String content;
  final String mood;   // emoji string
  final DateTime date;

  const DiaryEntry({
    required this.id, required this.content,
    required this.mood, required this.date,
  });

  factory DiaryEntry.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DiaryEntry(
      id: doc.id, content: d['content'] ?? '',
      mood: d['mood'] ?? '😊',
      date: (d['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'content': content, 'mood': mood,
    'date': Timestamp.fromDate(date),
  };
}
