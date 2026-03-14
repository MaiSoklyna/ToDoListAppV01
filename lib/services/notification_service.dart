import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionGranted = false;

  bool get permissionGranted => _permissionGranted;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );
    _initialized = true;

    // Request permission on Android 13+
    await requestPermission();
  }

  Future<bool> requestPermission() async {
    if (!_initialized) await init();

    // Android 13+ permission
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      _permissionGranted =
          await androidPlugin.requestNotificationsPermission() ?? false;
    } else {
      // iOS/macOS - permissions requested during init
      _permissionGranted = true;
    }
    return _permissionGranted;
  }

  Future<void> showTaskReminder(Task task) async {
    if (!_initialized) await init();
    if (!_permissionGranted) return;

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Reminders for upcoming tasks',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _notifications.show(
      task.id.hashCode,
      'Task Reminder',
      task.title,
      details,
      payload: task.id,
    );
  }

  Future<void> scheduleTaskReminder(Task task) async {
    if (!_initialized) await init();
    if (!_permissionGranted) return;
    if (task.dueDate == null) return;

    // Schedule 1 hour before due date
    final scheduledTime = task.dueDate!.subtract(const Duration(hours: 1));
    if (scheduledTime.isBefore(DateTime.now())) {
      // If already past the reminder time but task isn't due yet, show immediately
      if (task.dueDate!.isAfter(DateTime.now())) {
        await showTaskReminder(task);
      }
      return;
    }

    // Calculate delay and schedule
    final delay = scheduledTime.difference(DateTime.now());

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Reminders for upcoming tasks',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    // Use delayed show since zonedSchedule requires timezone package
    Future.delayed(delay, () {
      _notifications.show(
        task.id.hashCode,
        'Upcoming Task',
        '${task.title} is due soon!',
        details,
        payload: task.id,
      );
    });
  }

  /// Show a notification when Pomodoro timer completes
  Future<void> showPomodoroComplete({required bool isBreak}) async {
    if (!_initialized) await init();
    if (!_permissionGranted) return;

    const androidDetails = AndroidNotificationDetails(
      'pomodoro_timer',
      'Pomodoro Timer',
      channelDescription: 'Pomodoro timer notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _notifications.show(
      999999, // Fixed ID for pomodoro
      isBreak ? 'Break is over!' : 'Focus session complete!',
      isBreak ? 'Time to get back to work.' : 'Great job! Take a break.',
      details,
    );
  }

  Future<void> cancelTaskReminder(String taskId) async {
    await _notifications.cancel(taskId.hashCode);
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
