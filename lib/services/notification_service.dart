import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize notification service
  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _handleNotificationResponse,
    );

    await _requestPermissions();
  }

  /// Ask notification permission
  Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Schedule reminder
  Future<void> scheduleReminder(Task task) async {
    if (task.reminderDate == null ||
        task.completed ||
        !task.reminderDate!.isAfter(DateTime.now())) {
      await cancelReminder(task);
      return;
    }

    final notificationDetails = NotificationDetails(
      android: const AndroidNotificationDetails(
        'task_reminders', // Channel ID
        'Task Reminders', // Channel Name
        channelDescription: 'Reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'snooze',
            'Snooze 10 min',
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id: _notificationId(task),
  title: 'Task Reminder',
  body: task.title,
  scheduledDate: tz.TZDateTime.from(task.reminderDate!, tz.local),
  notificationDetails: notificationDetails,
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload:
          '${task.id}|${task.title}|${task.reminderDate!.toIso8601String()}',
    );
  }

  /// Cancel one reminder
Future<void> cancelReminder(Task task) async {
  await _plugin.cancel(
    id: _notificationId(task),
  );
}

  /// Cancel all reminders
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Generate notification id
  int _notificationId(Task task) {
    return task.id.hashCode;
  }

  /// Notification click handler
  @pragma('vm:entry-point')
  static Future<void> _handleNotificationResponse(
      NotificationResponse response) async {
    final payload = response.payload;

    if (payload == null || payload.isEmpty) {
      return;
    }

    final parts = payload.split('|');

    if (parts.length < 3) {
      return;
    }

    final taskId = parts[0];
    final title = parts[1];

    if (response.actionId == 'snooze') {
      final snoozeTime =
          DateTime.now().add(const Duration(minutes: 10));

      await NotificationService.instance.scheduleReminder(
        Task(
          id: taskId,
          title: title,
          reminderDate: snoozeTime,
        ),
      );
    }
  }
}