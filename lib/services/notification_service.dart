import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive/hive.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';
import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _timezonesReady = false;
  bool _permissionGranted = false;

  bool get permissionGranted => _permissionGranted;

  static const _taskChannelId = 'task_reminders';
  static const _taskChannelName = 'Task Reminders';
  static const _pomodoroChannelId = 'pomodoro_timer';
  static const _pomodoroChannelName = 'Pomodoro Timer';

  // Reserved IDs that must never collide with task-derived hashes.
  static const int _pomodoroNotificationId = 999999;

  Future<void> init() async {
    if (_initialized) return;

    await _initTimezones();

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

    await requestPermission();
  }

  Future<void> _initTimezones() async {
    if (_timezonesReady) return;
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      // Fall back to UTC; scheduling still works, just at UTC offsets.
      debugPrint('Timezone resolution failed, using UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    _timezonesReady = true;
  }

  Future<bool> requestPermission() async {
    if (!_initialized) await init();

    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      _permissionGranted =
          await androidPlugin.requestNotificationsPermission() ?? false;
    } else {
      _permissionGranted = true;
    }
    return _permissionGranted;
  }

  // ---------------------------------------------------------------------------
  // Public API — preserved signatures (callers in viewmodels/screens unchanged)
  // ---------------------------------------------------------------------------

  /// Show a reminder immediately (used as a fallback when a scheduled time has
  /// already passed but the task is still in the future).
  Future<void> showTaskReminder(Task task) async {
    if (!_initialized) await init();
    if (!_permissionGranted) return;

    await _notifications.show(
      _legacyIdFor(task.id),
      'Task Reminder',
      task.title,
      _taskDetails(),
      payload: task.id,
    );
  }

  /// Schedule reminders for [task].
  ///
  /// If the task carries explicit [Task.reminders], each one is scheduled
  /// individually via [zonedSchedule] (survives app kills). Otherwise we fall
  /// back to the legacy "1 hour before due date" behavior so existing callers
  /// keep working unchanged.
  Future<void> scheduleTaskReminder(Task task) async {
    if (!_initialized) await init();
    if (!_permissionGranted) return;

    if (task.reminders.isNotEmpty) {
      for (final reminder in task.reminders) {
        await _scheduleOne(task, reminder);
      }
      return;
    }

    // Legacy fallback: schedule 1 hour before due, or fire immediately if the
    // window has already closed but the task is still upcoming.
    if (task.dueDate == null) return;
    final scheduledTime = task.dueDate!.subtract(const Duration(hours: 1));
    if (scheduledTime.isBefore(DateTime.now())) {
      if (task.dueDate!.isAfter(DateTime.now())) {
        await showTaskReminder(task);
      }
      return;
    }

    await _scheduleAt(
      id: _legacyIdFor(task.id),
      title: 'Upcoming Task',
      body: '${task.title} is due soon!',
      when: scheduledTime,
      payload: task.id,
    );
  }

  /// Cancel the legacy single-reminder slot for [taskId].
  ///
  /// For multi-reminder tasks, prefer [cancelRemindersForTask] which knows
  /// each reminder's id.
  Future<void> cancelTaskReminder(String taskId) async {
    await _notifications.cancel(_legacyIdFor(taskId));
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> showPomodoroComplete({required bool isBreak}) async {
    if (!_initialized) await init();
    if (!_permissionGranted) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _pomodoroChannelId,
        _pomodoroChannelName,
        channelDescription: 'Pomodoro timer notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );

    await _notifications.show(
      _pomodoroNotificationId,
      isBreak ? 'Break is over!' : 'Focus session complete!',
      isBreak ? 'Time to get back to work.' : 'Great job! Take a break.',
      details,
    );
  }

  // ---------------------------------------------------------------------------
  // Multi-reminder API
  // ---------------------------------------------------------------------------

  /// Cancel every scheduled notification for [task] — both the legacy slot
  /// and any per-reminder slots created from [Task.reminders].
  Future<void> cancelRemindersForTask(Task task) async {
    await _notifications.cancel(_legacyIdFor(task.id));
    for (final reminder in task.reminders) {
      await _notifications.cancel(_idFor(task.id, reminder.id));
    }
  }

  /// Snooze a single reminder. Cancels the existing slot and reschedules at
  /// `now + delta`, returning the updated reminder so the caller can persist
  /// it via `task.copyWith(reminders: ...)`.
  Future<TaskReminder> snoozeReminder({
    required Task task,
    required TaskReminder reminder,
    required Duration delta,
  }) async {
    await _notifications.cancel(_idFor(task.id, reminder.id));
    final snoozed = reminder.copyWith(
      snoozedUntil: DateTime.now().add(delta),
    );
    await _scheduleOne(task, snoozed);
    return snoozed;
  }

  /// One-shot reschedule pass — useful at boot to repopulate the OS scheduler
  /// after the device restarts or after migrating from the old delayed-future
  /// implementation. Idempotent: cancels old slots before re-scheduling.
  Future<void> rescheduleAllForUser(List<Task> tasks) async {
    if (!_initialized) await init();
    if (!_permissionGranted) return;
    for (final task in tasks) {
      if (task.isCompleted) continue;
      await cancelRemindersForTask(task);
      await scheduleTaskReminder(task);
    }
  }

  // ---------------------------------------------------------------------------
  // Legacy reminder migration
  //
  // The previous implementation scheduled reminders via Future.delayed which
  // does not survive an app kill. After upgrading to the zonedSchedule
  // implementation, existing reminders silently stop firing until each task
  // is edited. This one-shot migration re-arms every active task's reminders
  // through the new scheduler. Keyed per-user via a Hive flag so it runs
  // exactly once per account, never re-runs on subsequent launches.
  // ---------------------------------------------------------------------------

  static const String _migrationBoxName = 'notification_migration';

  /// Returns true if the migration actually ran (tasks were rescheduled and
  /// the flag was set). Returns false when:
  ///   - the migration already ran for this user, OR
  ///   - [tasks] is empty (cold cache; try again next launch when warmer).
  Future<bool> migrateLegacyRemindersIfNeeded({
    required String userId,
    required List<Task> tasks,
  }) async {
    if (tasks.isEmpty) return false;

    final box = await Hive.openBox(_migrationBoxName);
    final key = 'migrated_v2_$userId';
    if ((box.get(key, defaultValue: false) as bool)) return false;

    await rescheduleAllForUser(tasks);
    await box.put(key, true);
    return true;
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _scheduleOne(Task task, TaskReminder reminder) async {
    final fireAt = reminder.effectiveFireAt;
    if (fireAt.isBefore(DateTime.now())) return;
    await _scheduleAt(
      id: _idFor(task.id, reminder.id),
      title: 'Reminder: ${task.title}',
      body: task.description.isEmpty ? null : task.description,
      when: fireAt,
      payload: '${task.id}|${reminder.id}',
    );
  }

  Future<void> _scheduleAt({
    required int id,
    required String title,
    required String? body,
    required DateTime when,
    required String payload,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      _taskDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  NotificationDetails _taskDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _taskChannelId,
        _taskChannelName,
        channelDescription: 'Reminders for upcoming tasks',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // Notification IDs are 32-bit signed ints. Mask to a positive range so two
  // task ids with very different hashes never collide with the pomodoro slot.
  int _legacyIdFor(String taskId) => taskId.hashCode & 0x7fffffff;

  int _idFor(String taskId, String reminderId) =>
      Object.hash(taskId, reminderId) & 0x7fffffff;
}
