import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../../utils/app_localizations.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../../models/task.dart';
import '../../services/notification_service.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Pomodoro settings
  static const int _workMinutes = 25;
  static const int _shortBreakMinutes = 5;
  static const int _longBreakMinutes = 15;
  static const String _boxName = 'pomodoro_state';

  int _totalSeconds = _workMinutes * 60;
  int _remainingSeconds = _workMinutes * 60;
  bool _isRunning = false;
  bool _isBreak = false;
  int _completedPomodoros = 0;
  Timer? _timer;
  Task? _selectedTask;
  DateTime? _timerStartedAt;

  /// Per-task focus session counts. Keyed by task id; persisted under
  /// 'taskCounts' in the same Hive box as the rest of pomodoro state.
  Map<String, int> _taskCounts = {};

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _restoreState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pulseController.dispose();
    _saveState();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveState();
    } else if (state == AppLifecycleState.resumed) {
      _restoreState();
    }
  }

  Future<void> _saveState() async {
    final box = await Hive.openBox(_boxName);
    await box.putAll({
      'totalSeconds': _totalSeconds,
      'remainingSeconds': _remainingSeconds,
      'isRunning': _isRunning,
      'isBreak': _isBreak,
      'completedPomodoros': _completedPomodoros,
      'timerStartedAt': _timerStartedAt?.toIso8601String(),
      'selectedTaskId': _selectedTask?.id,
      // Persist as a JSON-friendly map<String,int>.
      // Hive boxes accept Map<String, int> directly — no manual serialization.
      'taskCounts': Map<String, int>.from(_taskCounts),
    });
  }

  Future<void> _restoreState() async {
    try {
      final box = await Hive.openBox(_boxName);
      final wasRunning = box.get('isRunning', defaultValue: false) as bool;
      final savedCompleted =
          box.get('completedPomodoros', defaultValue: 0) as int;
      final savedBreak = box.get('isBreak', defaultValue: false) as bool;
      final savedTotal =
          box.get('totalSeconds', defaultValue: _workMinutes * 60) as int;
      final savedRemaining =
          box.get('remainingSeconds', defaultValue: _workMinutes * 60) as int;
      final startedAtStr = box.get('timerStartedAt') as String?;

      if (mounted) {
        setState(() {
          _completedPomodoros = savedCompleted;
          _isBreak = savedBreak;
          _totalSeconds = savedTotal;
        });
      }

      if (wasRunning && startedAtStr != null) {
        final startedAt = DateTime.parse(startedAtStr);
        final elapsed = DateTime.now().difference(startedAt).inSeconds;
        final remaining = savedRemaining - elapsed;

        if (remaining > 0) {
          if (mounted) {
            setState(() {
              _remainingSeconds = remaining;
            });
          }
          _startTimer();
        } else {
          // Timer completed while app was backgrounded
          _onTimerComplete();
        }
      } else {
        if (mounted) {
          setState(() {
            _remainingSeconds = savedRemaining;
          });
        }
      }

      // Restore selected task
      final taskId = box.get('selectedTaskId') as String?;
      if (taskId != null && mounted) {
        final taskVM = context.read<TaskViewModel>();
        try {
          _selectedTask = taskVM.activeTasks.firstWhere((t) => t.id == taskId);
        } catch (_) {}
      }

      // Restore per-task counts. Hive returns the inner map as
      // Map<dynamic, dynamic>, so we re-cast key/value types defensively.
      final raw = box.get('taskCounts');
      if (raw is Map) {
        _taskCounts = {
          for (final e in raw.entries)
            if (e.key is String && e.value is int)
              e.key as String: e.value as int,
        };
      }
    } catch (_) {}
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _timerStartedAt = DateTime.now();
    });
    _pulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _onTimerComplete();
      }
    });
    _saveState();
  }

  void _pauseTimer() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _isRunning = false;
      _timerStartedAt = null;
    });
    _saveState();
  }

  void _resetTimer() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _isRunning = false;
      _timerStartedAt = null;
      _remainingSeconds = _totalSeconds;
    });
    _saveState();
  }

  void _onTimerComplete() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    // Send notification
    NotificationService().showPomodoroComplete(isBreak: _isBreak);

    if (!_isBreak) {
      setState(() {
        _completedPomodoros++;
        // Credit the focus session to the selected task, if any.
        final taskId = _selectedTask?.id;
        if (taskId != null) {
          _taskCounts[taskId] = (_taskCounts[taskId] ?? 0) + 1;
        }
        _isBreak = true;
        _totalSeconds = (_completedPomodoros % 4 == 0)
            ? _longBreakMinutes * 60
            : _shortBreakMinutes * 60;
        _remainingSeconds = _totalSeconds;
        _isRunning = false;
        _timerStartedAt = null;
      });
    } else {
      setState(() {
        _isBreak = false;
        _totalSeconds = _workMinutes * 60;
        _remainingSeconds = _totalSeconds;
        _isRunning = false;
        _timerStartedAt = null;
      });
    }
    _saveState();
  }

  void _skipToNext() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    _onTimerComplete();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress {
    if (_totalSeconds == 0) return 0;
    return 1.0 - (_remainingSeconds / _totalSeconds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final taskVM = context.watch<TaskViewModel>();
    final activeTasks = taskVM.activeTasks;

    final timerColor = _isBreak ? Colors.green : theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.get('pomodoro')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Session info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (_isBreak ? Colors.green : timerColor)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isBreak ? l.get('breakTime') : l.get('focusTime'),
                      style: TextStyle(
                        color: _isBreak ? Colors.green : timerColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Focused-task banner — only when something is selected and we
              // aren't on a break (breaks aren't credited to a task).
              if (_selectedTask != null && !_isBreak) ...[
                const SizedBox(height: 16),
                _FocusedTaskBanner(
                  task: _selectedTask!,
                  sessionsForThisTask:
                      _taskCounts[_selectedTask!.id] ?? 0,
                  tone: timerColor,
                ),
              ],
              const SizedBox(height: 32),

              // Timer circle
              ScaleTransition(
                scale: _isRunning
                    ? _pulseAnimation
                    : const AlwaysStoppedAnimation(1.0),
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background circle
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 10,
                          color: timerColor.withValues(alpha: 0.12),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      // Progress circle
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(pi),
                          child: CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 10,
                            color: timerColor,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                      ),
                      // Timer text
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(_remainingSeconds),
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.w300,
                              color: timerColor,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${l.get('session')} ${_completedPomodoros + 1}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset
                  IconButton.outlined(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh),
                    iconSize: 28,
                  ),
                  const SizedBox(width: 16),
                  // Play/Pause
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: FilledButton(
                      onPressed: _isRunning ? _pauseTimer : _startTimer,
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: timerColor,
                      ),
                      child: Icon(
                        _isRunning ? Icons.pause : Icons.play_arrow,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Skip
                  IconButton.outlined(
                    onPressed: _skipToNext,
                    icon: const Icon(Icons.skip_next),
                    iconSize: 28,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Completed pomodoros
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final isDone = i < (_completedPomodoros % 4);
                  return Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? timerColor
                          : timerColor.withValues(alpha: 0.2),
                    ),
                    child: isDone
                        ? const Icon(Icons.check,
                            size: 10, color: Colors.white)
                        : null,
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                '$_completedPomodoros ${l.get('pomodorosCompleted')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Task selector
              if (activeTasks.isNotEmpty) ...[
                Text(l.get('focusOn'),
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedTask?.id,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.task_alt),
                    hintText: l.get('selectTask'),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l.get('noTaskSelected')),
                    ),
                    ...activeTasks.map((t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(
                            t.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                  onChanged: (id) {
                    setState(() {
                      _selectedTask = id != null
                          ? activeTasks.firstWhere((t) => t.id == id)
                          : null;
                    });
                    _saveState();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusedTaskBanner extends StatelessWidget {
  final Task task;
  final int sessionsForThisTask;
  final Color tone;

  const _FocusedTaskBanner({
    required this.task,
    required this.sessionsForThisTask,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.center_focus_strong, color: tone, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Focusing on',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  task.emoji != null
                      ? '${task.emoji}  ${task.title}'
                      : task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (sessionsForThisTask > 0) ...[
            const SizedBox(width: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                sessionsForThisTask == 1
                    ? '1 session'
                    : '$sessionsForThisTask sessions',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
