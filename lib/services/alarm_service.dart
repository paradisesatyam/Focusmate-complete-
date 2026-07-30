import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/alarm_model.dart';
import 'notification_service.dart';

class AlarmService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ref {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('alarms').doc(uid).collection('userAlarms');
  }

  Stream<List<Alarm>> stream() {
    return _ref
        .orderBy('hour')
        .snapshots()
        .map((s) => s.docs.map(Alarm.fromFirestore).toList());
  }

  Future<void> add(Alarm alarm) async {
    // 1. Save to Firestore — always happens
    final doc = await _ref.add(alarm.toMap());
    debugPrint('✅ Alarm saved: ${doc.id}');

    // 2. Schedule notification — non-blocking
    if (!kIsWeb && alarm.isActive) {
      try {
        await NotificationService().scheduleAlarm(
          alarmId: doc.id,
          label: alarm.label,
          hour: alarm.hour,
          minute: alarm.minute,
          repeatDays: alarm.repeatDays,
        );
      } catch (e) {
        debugPrint('⚠️ Alarm notification failed: $e');
      }
    }
  }

  Future<void> toggle(Alarm alarm) async {
    final active = !alarm.isActive;
    await _ref.doc(alarm.id).update({'isActive': active});

    if (!kIsWeb) {
      try {
        if (active) {
          await NotificationService().scheduleAlarm(
            alarmId: alarm.id,
            label: alarm.label,
            hour: alarm.hour,
            minute: alarm.minute,
            repeatDays: alarm.repeatDays,
          );
        } else {
          await NotificationService().cancelAlarm(alarm.id);
        }
      } catch (e) {
        debugPrint('⚠️ Alarm toggle notification failed: $e');
      }
    }
  }

  Future<void> delete(String id) async {
    await _ref.doc(id).delete();
    if (!kIsWeb) {
      try { await NotificationService().cancelAlarm(id); } catch (_) {}
    }
  }
}
