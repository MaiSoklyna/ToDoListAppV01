import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/cache_service.dart';
import '../services/notification_service.dart';
import '../services/streak_service.dart';

class TaskViewModel extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  final CacheService _cacheService = CacheService();
  final NotificationService _notificationService = NotificationService();
  final StreakService _streakService = StreakService();

  /// Callback triggered when a task is completed (for confetti)
  VoidCallback? onTaskCompleted;

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _streamSub;
  String? _currentUserId;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Task> get completedTasks =>
      _tasks.where((t) => t.isCompleted).toList();
  List<Task> get activeTasks => _tasks.where((t) => !t.isCompleted).toList();

  List<Task> getTasksByCategory(String category) =>
      _tasks.where((t) => t.category == category).toList();

  List<Task> getTasksByProject(String? projectId) =>
      _tasks.where((t) => t.projectId == projectId).toList();

  List<Task> getTasksByLabel(String labelId) =>
      _tasks.where((t) => t.labelIds.contains(labelId)).toList();

  List<Task> getTasksForDate(DateTime date) {
    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == date.year &&
          t.dueDate!.month == date.month &&
          t.dueDate!.day == date.day;
    }).toList();
  }

  /// Tasks completed on a specific date (uses completedAt)
  List<Task> getCompletedOnDate(DateTime date) {
    return _tasks.where((t) {
      if (!t.isCompleted || t.completedAt == null) return false;
      return t.completedAt!.year == date.year &&
          t.completedAt!.month == date.month &&
          t.completedAt!.day == date.day;
    }).toList();
  }

  Map<DateTime, List<Task>> get tasksByDate {
    final map = <DateTime, List<Task>>{};
    for (final task in _tasks) {
      if (task.dueDate != null) {
        final dateKey = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        map.putIfAbsent(dateKey, () => []).add(task);
      }
    }
    return map;
  }

  /// Start real-time sync with Firestore
  void startRealTimeSync(String userId) {
    _currentUserId = userId;
    _streamSub?.cancel();
    _streamSub = _taskService.streamTasks(userId).listen(
      (tasks) {
        _tasks = tasks;
        _isLoading = false;
        _error = null;
        _cacheService.cacheTasks(_tasks);
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Task stream error: $e');
        if (_tasks.isEmpty) {
          _error = 'Failed to sync tasks.';
        }
        _isLoading = false;
        notifyListeners();
        // Retry after delay
        Future.delayed(const Duration(seconds: 5), () {
          if (_currentUserId != null) {
            startRealTimeSync(_currentUserId!);
          }
        });
      },
    );
  }

  Future<void> loadTasks(String userId) async {
    _isLoading = true;
    _error = null;
    _currentUserId = userId;
    notifyListeners();

    // Load cached data first for fast display
    try {
      final cached = await _cacheService.getCachedTasks();
      if (cached.isNotEmpty && _tasks.isEmpty) {
        _tasks = cached;
        _isLoading = false;
        notifyListeners();
      }
    } catch (_) {}

    // Sync any pending offline operations
    await _syncPendingOperations();

    // Then start real-time sync
    startRealTimeSync(userId);
  }

  /// Sync pending offline operations when back online
  Future<void> _syncPendingOperations() async {
    try {
      final pendingOps = await _cacheService.getPendingOperations();
      if (pendingOps.isEmpty) return;

      for (final op in pendingOps) {
        try {
          switch (op.type) {
            case OperationType.add:
              if (op.taskData != null) {
                await _taskService.addTask(Task.fromJson(op.taskData!));
              }
            case OperationType.update:
              if (op.taskData != null) {
                await _taskService.updateTask(Task.fromJson(op.taskData!));
              }
            case OperationType.delete:
              await _taskService.deleteTask(op.taskId);
            case OperationType.toggleComplete:
              final isCompleted = op.taskData?['isCompleted'] as bool? ?? false;
              await _taskService.toggleComplete(op.taskId, isCompleted);
          }
        } catch (_) {
          // Skip failed individual ops, continue with rest
        }
      }
      await _cacheService.clearPendingOperations();
    } catch (_) {}
  }

  /// Called by ConnectivityService when connection is restored
  Future<void> onReconnected() async {
    if (_currentUserId == null) return;
    await _syncPendingOperations();
    startRealTimeSync(_currentUserId!);
  }

  Future<void> addTask(Task task) async {
    try {
      _tasks.insert(0, task);
      notifyListeners();
      await _taskService.addTask(task);
      await _cacheService.cacheTasks(_tasks);
      if (task.dueDate != null) {
        await _notificationService.scheduleTaskReminder(task);
      }
    } catch (e) {
      // Queue for offline sync
      await _cacheService.queueOperation(PendingOperation(
        type: OperationType.add,
        taskId: task.id,
        taskData: task.toJson(),
      ));
      await _cacheService.cacheTasks(_tasks);
    }
  }

  Future<void> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;
    try {
      _tasks[index] = task;
      notifyListeners();
      await _taskService.updateTask(task);
      await _cacheService.cacheTasks(_tasks);
      if (task.dueDate != null) {
        await _notificationService.scheduleTaskReminder(task);
      }
    } catch (e) {
      // Queue for offline sync instead of reverting
      await _cacheService.queueOperation(PendingOperation(
        type: OperationType.update,
        taskId: task.id,
        taskData: task.toJson(),
      ));
      await _cacheService.cacheTasks(_tasks);
    }
  }

  Future<void> deleteTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    try {
      _tasks.removeAt(index);
      notifyListeners();
      await _taskService.deleteTask(taskId);
      await _cacheService.cacheTasks(_tasks);
      await _notificationService.cancelTaskReminder(taskId);
    } catch (e) {
      await _cacheService.queueOperation(PendingOperation(
        type: OperationType.delete,
        taskId: taskId,
      ));
      await _cacheService.cacheTasks(_tasks);
    }
  }

  Future<void> toggleComplete(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = _tasks[index];
    task.isCompleted = !task.isCompleted;
    task.completedAt = task.isCompleted ? DateTime.now() : null;
    notifyListeners();

    try {
      await _taskService.toggleComplete(taskId, task.isCompleted);
      // Also update completedAt in Firestore
      await _taskService.updateTask(task);
      await _cacheService.cacheTasks(_tasks);

      if (task.isCompleted) {
        await _notificationService.cancelTaskReminder(taskId);
        await _streakService.recordCompletion();
        onTaskCompleted?.call();
        // Handle recurring task: create next occurrence
        if (task.recurrenceRule != null && task.dueDate != null) {
          await _createNextRecurrence(task);
        }
      }
    } catch (e) {
      await _cacheService.queueOperation(PendingOperation(
        type: OperationType.toggleComplete,
        taskId: taskId,
        taskData: {'isCompleted': task.isCompleted},
      ));
      await _cacheService.cacheTasks(_tasks);
    }
  }

  /// Create the next occurrence of a recurring task
  Future<void> _createNextRecurrence(Task completedTask) async {
    final nextDate =
        completedTask.recurrenceRule!.nextOccurrence(completedTask.dueDate!);
    if (nextDate == null) return;

    final nextTask = completedTask.copyWith(
      id: const Uuid().v4(),
      isCompleted: false,
      dueDate: nextDate,
      createdAt: DateTime.now(),
      clearCompletedAt: true,
    );
    await addTask(nextTask);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}
