import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../profile/services/user_service.dart';
import '../../tasks/models/task.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _exactAlarmPermissionRequested = false;

  // --------------------------------------------------
  // INITIALIZE
  // --------------------------------------------------

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);

    final preferences = await UserService().loadPreferences();
    if (preferences.notificationsEnabled) {
      await _requestPermissions();
    }

    _initialized = true;
  }

  // --------------------------------------------------
  // PERMISSIONS
  // --------------------------------------------------

  Future<void> _requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await android?.requestNotificationsPermission();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // --------------------------------------------------
  // SCHEDULE TASK REMINDER
  // --------------------------------------------------

  Future<void> scheduleReminder(Task task) async {
    await initialize();

    final preferences = await UserService().loadPreferences();
    if (!preferences.notificationsEnabled ||
        !preferences.reminderEnabled ||
        !task.reminderEnabled ||
        task.reminderDate == null ||
        task.completed) {
      await cancelReminder(task);
      return;
    }

    final reminder = task.reminderDate!;

    if (!reminder.isAfter(DateTime.now())) {
      await cancelReminder(task);
      return;
    }

    await _requestExactAlarmsPermission();

    final notificationId = _notificationId(task);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'task_reminders',
        'Task Reminders',
        channelDescription: 'Notifications for task reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      id: notificationId,
      title: 'Task Reminder',
      body: task.title,
      scheduledDate: tz.TZDateTime.from(reminder, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: task.id,
    );
  }

  Future<void> _requestExactAlarmsPermission() async {
    if (_exactAlarmPermissionRequested) return;
    _exactAlarmPermissionRequested = true;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestExactAlarmsPermission();
  }

  // --------------------------------------------------
  // CANCEL ONE REMINDER
  // --------------------------------------------------

  Future<void> cancelReminder(Task task) async {
    await initialize();

    await _plugin.cancel(id: _notificationId(task));
  }

  // --------------------------------------------------
  // CANCEL ALL
  // --------------------------------------------------

  Future<void> cancelAll() async {
    await initialize();

    await _plugin.cancelAll();
  }

  Future<Set<String>> pendingReminderTaskIds() async {
    await initialize();
    final requests = await _plugin.pendingNotificationRequests();
    return requests
        .map((request) => request.payload)
        .whereType<String>()
        .toSet();
  }

  // --------------------------------------------------
  // GENERATE NOTIFICATION ID
  // --------------------------------------------------

  int _notificationId(Task task) {
    return task.id.hashCode & 0x7FFFFFFF;
  }
}
