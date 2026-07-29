import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) return; // Not supported on web
    tz_data.initializeTimeZones();
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ));
  }

  NotificationDetails get _taskChannel => const NotificationDetails(
    android: AndroidNotificationDetails(
      'task_reminders', 'Task Reminders',
      importance: Importance.high, priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  NotificationDetails get _checkInChannel => const NotificationDetails(
    android: AndroidNotificationDetails('daily_checkin', 'Daily Check-In'),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> scheduleTask({required String taskId, required String title, required DateTime deadline}) async {
    if (kIsWeb) return;
    if (deadline.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      taskId.hashCode.abs(), '⏰ Task Reminder', title,
      tz.TZDateTime.from(deadline, tz.local), _taskChannel,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelTask(String taskId) async {
    if (kIsWeb) return;
    await _plugin.cancel(taskId.hashCode.abs());
  }

  Future<void> scheduleDailyCheckIn() async {
    if (kIsWeb) return;
    var time = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 20, 0);
    if (time.isBefore(DateTime.now())) time = time.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      9999, '📋 FocusMate Check-In', 'Have you completed your tasks today?',
      tz.TZDateTime.from(time, tz.local), _checkInChannel,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }
}
