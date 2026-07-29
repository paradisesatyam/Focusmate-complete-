import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import 'notification_service.dart';

class TaskService {
  final _db = FirebaseFirestore.instance;
  final _notifs = NotificationService();

  CollectionReference<Map<String, dynamic>> get _ref {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('tasks').doc(uid).collection('userTasks');
  }

  Stream<List<Task>> stream() => _ref
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Task.fromFirestore).toList());

  Future<void> add(Task task) async {
    final doc = await _ref.add(task.toMap());
    await _notifs.scheduleTask(taskId: doc.id, title: task.title, deadline: task.deadline);
  }

  Future<void> toggle(Task task) async {
    final done = !task.isDone;
    await _ref.doc(task.id).update({'isDone': done});
    if (done) {
      await _notifs.cancelTask(task.id);
    } else {
      await _notifs.scheduleTask(taskId: task.id, title: task.title, deadline: task.deadline);
    }
  }

  Future<void> delete(String id) async {
    await _ref.doc(id).delete();
    await _notifs.cancelTask(id);
  }
}
