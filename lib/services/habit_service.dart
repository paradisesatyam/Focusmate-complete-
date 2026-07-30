import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/habit_model.dart';
import 'notification_service.dart';

class HabitService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ref {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('habits').doc(uid).collection('userHabits');
  }

  Stream<List<Habit>> stream() {
    return _ref
        .orderBy('title')
        .snapshots()
        .map((s) => s.docs.map(Habit.fromFirestore).toList());
  }

  Future<void> add(Habit habit) async {
    // 1. Save to Firestore first — this must always succeed
    final doc = await _ref.add(habit.toMap());
    debugPrint('✅ Habit saved: ${doc.id}');

    // 2. Schedule notification separately — failure here is non-blocking
    if (!kIsWeb && habit.isActive) {
      try {
        await NotificationService().scheduleHabit(
          habitId: doc.id,
          title: habit.title,
          hour: habit.reminderHour,
          minute: habit.reminderMinute,
        );
      } catch (e) {
        debugPrint('⚠️ Habit notification scheduling failed: $e');
      }
    }
  }

  Future<void> toggleActive(Habit habit) async {
    final active = !habit.isActive;
    await _ref.doc(habit.id).update({'isActive': active});

    if (!kIsWeb) {
      try {
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
      } catch (e) {
        debugPrint('⚠️ Habit notification toggle failed: $e');
      }
    }
  }

  Future<void> markDone(Habit habit) async {
    final today = _dateKey(DateTime.now());
    await _ref.doc(habit.id).update({'lastCompletedDate': today});
    debugPrint('✅ Habit marked done: ${habit.title}');
  }

  Future<void> delete(String id) async {
    await _ref.doc(id).delete();
    if (!kIsWeb) {
      try { await NotificationService().cancelHabit(id); } catch (_) {}
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
