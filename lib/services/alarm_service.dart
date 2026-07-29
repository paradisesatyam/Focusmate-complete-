import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/alarm_model.dart';
import 'notification_service.dart';

class AlarmService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ref {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('alarms').doc(uid).collection('userAlarms');
  }

  Stream<List<Alarm>> stream() => _ref
      .orderBy('hour')
      .snapshots()
      .map((s) => s.docs.map(Alarm.fromFirestore).toList());

  Future<void> add(Alarm alarm) async {
    final doc = await _ref.add(alarm.toMap());
    if (alarm.isActive) {
      await NotificationService().scheduleAlarm(
        alarmId: doc.id,
        label: alarm.label,
        hour: alarm.hour,
        minute: alarm.minute,
        repeatDays: alarm.repeatDays,
      );
    }
  }

  Future<void> toggle(Alarm alarm) async {
    final active = !alarm.isActive;
    await _ref.doc(alarm.id).update({'isActive': active});
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
  }

  Future<void> delete(String id) async {
    await _ref.doc(id).delete();
    await NotificationService().cancelAlarm(id);
  }
}
