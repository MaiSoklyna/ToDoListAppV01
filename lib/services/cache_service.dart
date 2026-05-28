import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/task.dart';

class CacheService {
  static const _tasksBoxPrefix = 'cached_tasks';
  static const _pendingOpsBoxPrefix = 'pending_operations';

  // Singleton: every instantiation site shares the same _userId so caches
  // can never accidentally read the wrong account's data.
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  /// Per-user box scoping. Set this on login so caches from a previous
  /// account never leak into a new session. Methods are no-ops until set.
  String? _userId;

  void setUserId(String? userId) {
    _userId = userId;
  }

  String get _tasksBoxName => '${_tasksBoxPrefix}_${_userId ?? 'anon'}';
  String get _pendingOpsBoxName =>
      '${_pendingOpsBoxPrefix}_${_userId ?? 'anon'}';

  Future<void> cacheTasks(List<Task> tasks) async {
    if (_userId == null) return;
    final box = await Hive.openBox(_tasksBoxName);
    final jsonList = tasks.map((t) => jsonEncode(t.toJson())).toList();
    await box.put('tasks', jsonList);
    await box.put('lastSync', DateTime.now().toIso8601String());
  }

  Future<List<Task>> getCachedTasks() async {
    if (_userId == null) return [];
    final box = await Hive.openBox(_tasksBoxName);
    final jsonList = box.get('tasks', defaultValue: <String>[]) as List;
    try {
      return jsonList
          .map((s) =>
              Task.fromJson(jsonDecode(s as String) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Corrupted cache, clear it
      await box.delete('tasks');
      return [];
    }
  }

  Future<DateTime?> getLastSyncTime() async {
    if (_userId == null) return null;
    final box = await Hive.openBox(_tasksBoxName);
    final timeStr = box.get('lastSync') as String?;
    if (timeStr == null) return null;
    return DateTime.parse(timeStr);
  }

  /// Clear caches for the current user. Used on signOut.
  Future<void> clearCache() async {
    if (_userId == null) return;
    final tasksBox = await Hive.openBox(_tasksBoxName);
    await tasksBox.clear();
    final opsBox = await Hive.openBox(_pendingOpsBoxName);
    await opsBox.clear();
  }

  // --- Pending Operations Queue (for offline changes) ---

  /// Queue an operation to be synced when back online
  Future<void> queueOperation(PendingOperation op) async {
    if (_userId == null) return;
    final box = await Hive.openBox(_pendingOpsBoxName);
    final ops = _getPendingOps(box);
    ops.add(op);
    await box.put('ops', ops.map((o) => jsonEncode(o.toJson())).toList());
  }

  /// Get all pending operations
  Future<List<PendingOperation>> getPendingOperations() async {
    if (_userId == null) return [];
    final box = await Hive.openBox(_pendingOpsBoxName);
    return _getPendingOps(box);
  }

  /// Clear all pending operations after successful sync
  Future<void> clearPendingOperations() async {
    if (_userId == null) return;
    final box = await Hive.openBox(_pendingOpsBoxName);
    await box.delete('ops');
  }

  List<PendingOperation> _getPendingOps(Box box) {
    final list = box.get('ops', defaultValue: <String>[]) as List;
    try {
      return list
          .map((s) => PendingOperation.fromJson(
              jsonDecode(s as String) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

enum OperationType { add, update, delete, toggleComplete }

class PendingOperation {
  final OperationType type;
  final String taskId;
  final Map<String, dynamic>? taskData;
  final DateTime timestamp;

  PendingOperation({
    required this.type,
    required this.taskId,
    this.taskData,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'taskId': taskId,
        'taskData': taskData,
        'timestamp': timestamp.toIso8601String(),
      };

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      type: OperationType.values.firstWhere((e) => e.name == json['type']),
      taskId: json['taskId'] as String,
      taskData: json['taskData'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
