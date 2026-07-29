import 'package:cloud_firestore/cloud_firestore.dart';

const kCategories = [
  'Food & Drinks', 'Transport', 'Education',
  'Entertainment', 'Shopping', 'Health', 'Bills', 'Other',
];

const kCategoryIcons = ['🍕','🚗','📚','🎮','🛍️','💊','🧾','💰'];

class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;

  const Expense({
    required this.id, required this.title, required this.amount,
    required this.category, required this.date, this.note,
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id, title: d['title'] ?? '',
      amount: (d['amount'] as num).toDouble(),
      category: d['category'] ?? 'Other',
      date: (d['date'] as Timestamp).toDate(),
      note: d['note'],
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title, 'amount': amount,
    'category': category,
    'date': Timestamp.fromDate(date),
    'note': note,
  };
}
