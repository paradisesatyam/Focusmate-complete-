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
    if (kIsWeb) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ));
    // Request Android 13+ notification permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ─── Notification detail presets ────────────────────────────────
  NotificationDetails get _taskDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_channel', 'Task Reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      );

  NotificationDetails get _habitDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_channel', 'Daily Habits',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      );

  NotificationDetails get _alarmDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel', 'Alarms',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          icon: '@mipmap/ic_launcher',
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      );

  NotificationDetails get _checkInDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          'checkin_channel', 'Daily Check-In',
          importance: Importance.defaultImportance,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      );

  // ─── Helper: next occurrence of HH:MM ───────────────────────────
  tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // ─── Task notifications ──────────────────────────────────────────
  Future<void> scheduleTask({
    required String taskId,
    required String title,
    required DateTime deadline,
  }) async {
    if (kIsWeb) return;
    if (deadline.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      taskId.hashCode.abs() % 100000,
      '⏰ Task Reminder',
      title,
      tz.TZDateTime.from(deadline, tz.local),
      _taskDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelTask(String taskId) async {
    if (kIsWeb) return;
    await _plugin.cancel(taskId.hashCode.abs() % 100000);
  }

  // ─── Daily check-in ─────────────────────────────────────────────
  Future<void> scheduleDailyCheckIn() async {
    if (kIsWeb) return;
    await _plugin.zonedSchedule(
      99990,
      '📋 FocusMate Check-In',
      'Have you completed your tasks for today?',
      _nextInstance(20, 0),
      _checkInDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ─── Habit notifications ─────────────────────────────────────────
  Future<void> scheduleHabit({
    required String habitId,
    required String title,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;
    await _plugin.zonedSchedule(
      // Use a distinct ID range 200000+ for habits
      200000 + (habitId.hashCode.abs() % 100000),
      '🌟 Daily Habit',
      title,
      _nextInstance(hour, minute),
      _habitDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
    );
  }

  Future<void> cancelHabit(String habitId) async {
    if (kIsWeb) return;
    await _plugin.cancel(200000 + (habitId.hashCode.abs() % 100000));
  }

  // ─── Alarm notifications ─────────────────────────────────────────
  Future<void> scheduleAlarm({
    required String alarmId,
    required String label,
    required int hour,
    required int minute,
    required List<int> repeatDays,
  }) async {
    if (kIsWeb) return;
    final id = 300000 + (alarmId.hashCode.abs() % 100000);

    if (repeatDays.isEmpty) {
      // One-time alarm
      await _plugin.zonedSchedule(
        id,
        '⏰ $label',
        'Your alarm is ringing!',
        _nextInstance(hour, minute),
        _alarmDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else {
      // Repeating alarm — schedule for each selected day
      await _plugin.zonedSchedule(
        id,
        '⏰ $label',
        'Your alarm is ringing!',
        _nextInstance(hour, minute),
        _alarmDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelAlarm(String alarmId) async {
    if (kIsWeb) return;
    await _plugin.cancel(300000 + (alarmId.hashCode.abs() % 100000));
  }

  // ─── Cancel all ──────────────────────────────────────────────────
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }
}
