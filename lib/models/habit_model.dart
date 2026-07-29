import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  final String id;
  final String title;
  final String icon;
  final int reminderHour;   // 24h format
  final int reminderMinute;
  final bool isActive;
  final String? lastCompletedDate; // 'yyyy-MM-dd' string

  const Habit({
    required this.id,
    required this.title,
    required this.icon,
    required this.reminderHour,
    required this.reminderMinute,
    required this.isActive,
    this.lastCompletedDate,
  });

  /// Whether this habit is already done today
  bool get isDoneToday {
    final today = _dateKey(DateTime.now());
    return lastCompletedDate == today;
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get timeLabel {
    final h = reminderHour;
    final m = reminderMinute.toString().padLeft(2, '0');
    final suffix = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $suffix';
  }

  factory Habit.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Habit(
      id: doc.id,
      title: d['title'] ?? '',
      icon: d['icon'] ?? '⭐',
      reminderHour: d['reminderHour'] ?? 8,
      reminderMinute: d['reminderMinute'] ?? 0,
      isActive: d['isActive'] ?? true,
      lastCompletedDate: d['lastCompletedDate'],
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'icon': icon,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'isActive': isActive,
        'lastCompletedDate': lastCompletedDate,
      };

  Habit copyWith({bool? isActive, String? lastCompletedDate}) => Habit(
        id: id,
        title: title,
        icon: icon,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
        isActive: isActive ?? this.isActive,
        lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      );
}

const kHabitIcons = [
  '💧', '🏃', '📚', '🧘', '🍎', '😴', '✍️', '🎯',
  '💪', '🎵', '🧹', '🌞', '🙏', '💊', '🚶', '🧠',
];
