import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit_model.dart';
import 'notification_service.dart';

class HabitService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ref {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('habits').doc(uid).collection('userHabits');
  }

  Stream<List<Habit>> stream() => _ref
      .orderBy('title')
      .snapshots()
      .map((s) => s.docs.map(Habit.fromFirestore).toList());

  Future<void> add(Habit habit) async {
    final doc = await _ref.add(habit.toMap());
    if (habit.isActive) {
      await NotificationService().scheduleHabit(
        habitId: doc.id,
        title: habit.title,
        hour: habit.reminderHour,
        minute: habit.reminderMinute,
      );
    }
  }

  Future<void> toggleActive(Habit habit) async {
    final active = !habit.isActive;
    await _ref.doc(habit.id).update({'isActive': active});
    if (active) {
      await NotificationService().scheduleHabit(
        habitId: habit.id,
        title: habit.title,
        hour: habit.reminderHour,
        minute: habit.reminderMinute,
      );
    } else {
      await NotificationService().cancelHabit(habit.id);
    }
  }

  Future<void> markDone(Habit habit) async {
    final today =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    await _ref.doc(habit.id).update({'lastCompletedDate': today});
  }

  Future<void> delete(String id) async {
    await _ref.doc(id).delete();
    await NotificationService().cancelHabit(id);
  }
}
