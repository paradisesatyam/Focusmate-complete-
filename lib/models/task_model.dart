import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime deadline;
  final bool isDone;
  final int priority; // 0=Low 1=Medium 2=High
  final DateTime createdAt;

  const Task({
    required this.id, required this.title, this.description,
    required this.deadline, required this.isDone,
    required this.priority, required this.createdAt,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id, title: d['title'] ?? '',
      description: d['description'],
      deadline: (d['deadline'] as Timestamp).toDate(),
      isDone: d['isDone'] ?? false,
      priority: d['priority'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title, 'description': description,
    'deadline': Timestamp.fromDate(deadline),
    'isDone': isDone, 'priority': priority,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  Task copyWith({bool? isDone}) => Task(
    id: id, title: title, description: description,
    deadline: deadline, isDone: isDone ?? this.isDone,
    priority: priority, createdAt: createdAt,
  );

  String get priorityLabel => ['Low','Medium','High'][priority];
}
