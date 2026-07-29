import 'package:cloud_firestore/cloud_firestore.dart';

class Alarm {
  final String id;
  final String label;
  final int hour;      // 24h format
  final int minute;
  final bool isActive;
  final List<int> repeatDays; // 1=Mon .. 7=Sun, empty = once

  const Alarm({
    required this.id,
    required this.label,
    required this.hour,
    required this.minute,
    required this.isActive,
    this.repeatDays = const [],
  });

  String get timeLabel {
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $suffix';
  }

  String get repeatLabel {
    if (repeatDays.isEmpty) return 'Once';
    if (repeatDays.length == 7) return 'Every day';
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return repeatDays.map((d) => names[d]).join(', ');
  }

  factory Alarm.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Alarm(
      id: doc.id,
      label: d['label'] ?? 'Alarm',
      hour: d['hour'] ?? 7,
      minute: d['minute'] ?? 0,
      isActive: d['isActive'] ?? true,
      repeatDays: List<int>.from(d['repeatDays'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'label': label,
        'hour': hour,
        'minute': minute,
        'isActive': isActive,
        'repeatDays': repeatDays,
      };

  Alarm copyWith({bool? isActive}) => Alarm(
        id: id, label: label, hour: hour, minute: minute,
        isActive: isActive ?? this.isActive, repeatDays: repeatDays,
      );
}
