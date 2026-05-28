import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

class StreakService {
  static const _boxPrefix = 'streak_data';

  // Singleton: shared across dashboard/profile/statistics/task VM so they
  // all see the same scoped userId.
  static final StreakService _instance = StreakService._internal();
  factory StreakService() => _instance;
  StreakService._internal();

  String? _userId;

  void setUserId(String? userId) {
    _userId = userId;
  }

  String get _boxName => '${_boxPrefix}_${_userId ?? 'anon'}';

  Future<Box> _getBox() async => Hive.openBox(_boxName);

  Future<void> clear() async {
    if (_userId == null) return;
    final box = await _getBox();
    await box.clear();
  }

  /// Record that the user completed a task today
  Future<void> recordCompletion() async {
    final box = await _getBox();
    final today = _dateKey(DateTime.now());
    final count = (box.get(today, defaultValue: 0) as int) + 1;
    await box.put(today, count);
    await _updateStreak(box);
  }

  /// Get current streak (consecutive days with at least 1 completion)
  Future<int> getCurrentStreak() async {
    final box = await _getBox();
    return box.get('currentStreak', defaultValue: 0) as int;
  }

  /// Get best streak ever
  Future<int> getBestStreak() async {
    final box = await _getBox();
    return box.get('bestStreak', defaultValue: 0) as int;
  }

  /// Get completions for last 7 days
  Future<Map<String, int>> getWeeklyCompletions() async {
    final box = await _getBox();
    final result = <String, int>{};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = _dateKey(date);
      result[key] = box.get(key, defaultValue: 0) as int;
    }
    return result;
  }

  /// Get total completions ever
  Future<int> getTotalCompletions() async {
    final box = await _getBox();
    return box.get('totalCompletions', defaultValue: 0) as int;
  }

  /// Calculate productivity score (0-100)
  Future<int> getProductivityScore(List<Task> tasks) async {
    if (tasks.isEmpty) return 0;

    final completed = tasks.where((t) => t.isCompleted).length;
    final total = tasks.length;
    final completionRate = completed / total;

    // Factor in streak
    final streak = await getCurrentStreak();
    final streakBonus = (streak * 2).clamp(0, 20);

    // Factor in overdue tasks (penalty)
    final now = DateTime.now();
    final overdue = tasks.where((t) =>
        !t.isCompleted &&
        t.dueDate != null &&
        t.dueDate!.isBefore(now)).length;
    final overduePenalty = (overdue * 5).clamp(0, 30);

    final score =
        ((completionRate * 80) + streakBonus - overduePenalty).round();
    return score.clamp(0, 100);
  }

  Future<void> _updateStreak(Box box) async {
    final now = DateTime.now();
    int streak = 0;

    // Count consecutive days backwards from today
    for (int i = 0; i < 365; i++) {
      final date = now.subtract(Duration(days: i));
      final key = _dateKey(date);
      final count = box.get(key, defaultValue: 0) as int;
      if (count > 0) {
        streak++;
      } else {
        break;
      }
    }

    await box.put('currentStreak', streak);

    // Update total completions
    final total = (box.get('totalCompletions', defaultValue: 0) as int) + 1;
    await box.put('totalCompletions', total);

    // Update best streak
    final best = box.get('bestStreak', defaultValue: 0) as int;
    if (streak > best) {
      await box.put('bestStreak', streak);
    }
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
