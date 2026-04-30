import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/task.dart';
import '../../utils/app_localizations.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../widgets/task_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

enum _DayView { agenda, timeline }

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  _DayView _viewMode = _DayView.timeline;

  @override
  Widget build(BuildContext context) {
    final taskVM = context.watch<TaskViewModel>();
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final selectedTasks = taskVM.getTasksForDate(_selectedDay);

    return Stack(
      children: [
        Column(
      children: [
        TableCalendar<Task>(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() => _calendarFormat = format);
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: (day) => taskVM.getTasksForDate(day),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
            ),
            selectedDecoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: theme.colorScheme.tertiary,
              shape: BoxShape.circle,
            ),
            markerSize: 6,
            markersMaxCount: 3,
          ),
          headerStyle: HeaderStyle(
            formatButtonDecoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(16),
            ),
            titleCentered: true,
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                _formatSelectedDate(l),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Text(
                '· ${selectedTasks.length} ${selectedTasks.length == 1 ? l.get('task') : l.get('tasks')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // View toggle: Agenda (flat list) vs Timeline (24-hour grid).
              SegmentedButton<_DayView>(
                segments: const [
                  ButtonSegment(
                    value: _DayView.agenda,
                    icon: Icon(Icons.list_alt, size: 16),
                  ),
                  ButtonSegment(
                    value: _DayView.timeline,
                    icon: Icon(Icons.view_timeline_outlined, size: 16),
                  ),
                ],
                selected: {_viewMode},
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity:
                      VisualDensity(horizontal: -2, vertical: -2),
                ),
                onSelectionChanged: (s) =>
                    setState(() => _viewMode = s.first),
              ),
            ],
          ),
        ),
        Expanded(
          child: _viewMode == _DayView.agenda
              ? _buildAgenda(context, theme, l, taskVM, selectedTasks)
              : _DayTimeline(
                  day: _selectedDay,
                  tasks: selectedTasks,
                  onToggle: (t) => taskVM.toggleComplete(t.id),
                  onTapTask: (t) => context.push('/add-task', extra: t),
                  onTapEmpty: (when) => context.push(
                    '/add-task',
                    extra: Task(id: '', title: '', dueDate: when),
                  ),
                ),
        ),
      ],
    ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'calendar_fab',
            onPressed: () => context.push('/add-task', extra: Task(
              id: '',
              title: '',
              dueDate: _selectedDay,
            )),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildAgenda(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l,
    TaskViewModel taskVM,
    List<Task> selectedTasks,
  ) {
    if (selectedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              l.get('noTasksForDay'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: selectedTasks.length,
      itemBuilder: (context, index) {
        final task = selectedTasks[index];
        return TaskCard(
          task: task,
          onToggle: () => taskVM.toggleComplete(task.id),
        );
      },
    );
  }

  String _formatSelectedDate(AppLocalizations l) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);

    if (selected == today) return l.get('today');
    if (selected == today.add(const Duration(days: 1))) {
      return l.get('tomorrow');
    }
    if (selected == today.subtract(const Duration(days: 1))) {
      return l.get('yesterday');
    }

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${_selectedDay.day} ${months[_selectedDay.month - 1]} ${_selectedDay.year}';
  }
}

/// 24-hour day grid with tasks bucketed by [Task.dueDate.hour]. Tasks
/// without an explicit time (hour=0 minute=0) appear in an "All day"
/// strip at the top so they don't get misfiled into midnight.
class _DayTimeline extends StatefulWidget {
  final DateTime day;
  final List<Task> tasks;
  final void Function(Task) onToggle;
  final void Function(Task) onTapTask;
  final void Function(DateTime when) onTapEmpty;

  const _DayTimeline({
    required this.day,
    required this.tasks,
    required this.onToggle,
    required this.onTapTask,
    required this.onTapEmpty,
  });

  @override
  State<_DayTimeline> createState() => _DayTimelineState();
}

class _DayTimelineState extends State<_DayTimeline> {
  static const double _hourHeight = 64;
  static const double _hourLabelWidth = 56;
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    // For today, scroll so the current hour sits ~2 rows from the top.
    // The frame callback runs after layout so the controller has a viewport.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final now = DateTime.now();
      if (!_isSameDay(widget.day, now)) return;
      final target = ((now.hour - 2).clamp(0, 23)) * _hourHeight;
      _scrollCtrl.jumpTo(target.toDouble());
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allDay = widget.tasks.where(_isAllDay).toList();
    final byHour = <int, List<Task>>{};
    for (final task in widget.tasks) {
      if (_isAllDay(task)) continue;
      final h = task.dueDate!.hour;
      byHour.putIfAbsent(h, () => []).add(task);
    }
    // Earliest minute first within each hour.
    for (final list in byHour.values) {
      list.sort((a, b) => a.dueDate!.minute.compareTo(b.dueDate!.minute));
    }

    final isToday = _isSameDay(widget.day, DateTime.now());
    final currentHour = DateTime.now().hour;

    return ListView(
      controller: _scrollCtrl,
      padding: EdgeInsets.zero,
      children: [
        if (allDay.isNotEmpty)
          _AllDayStrip(
            tasks: allDay,
            onToggle: widget.onToggle,
            onTapTask: widget.onTapTask,
          ),
        for (int hour = 0; hour < 24; hour++)
          _HourRow(
            hour: hour,
            isCurrentHour: isToday && hour == currentHour,
            tasks: byHour[hour] ?? const [],
            hourHeight: _hourHeight,
            labelWidth: _hourLabelWidth,
            onToggle: widget.onToggle,
            onTapTask: widget.onTapTask,
            onTapEmpty: () => widget.onTapEmpty(
              DateTime(
                widget.day.year,
                widget.day.month,
                widget.day.day,
                hour,
              ),
            ),
          ),
        // Bottom breathing room above the FAB.
        SizedBox(height: 96, child: ColoredBox(color: theme.colorScheme.surface)),
      ],
    );
  }

  bool _isAllDay(Task t) {
    final d = t.dueDate;
    if (d == null) return true;
    return d.hour == 0 && d.minute == 0;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _AllDayStrip extends StatelessWidget {
  final List<Task> tasks;
  final void Function(Task) onToggle;
  final void Function(Task) onTapTask;

  const _AllDayStrip({
    required this.tasks,
    required this.onToggle,
    required this.onTapTask,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All day',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          ...tasks.map((t) => _TimelineTaskTile(
                task: t,
                onToggle: () => onToggle(t),
                onTap: () => onTapTask(t),
              )),
        ],
      ),
    );
  }
}

class _HourRow extends StatelessWidget {
  final int hour;
  final bool isCurrentHour;
  final List<Task> tasks;
  final double hourHeight;
  final double labelWidth;
  final void Function(Task) onToggle;
  final void Function(Task) onTapTask;
  final VoidCallback onTapEmpty;

  const _HourRow({
    required this.hour,
    required this.isCurrentHour,
    required this.tasks,
    required this.hourHeight,
    required this.labelWidth,
    required this.onToggle,
    required this.onTapTask,
    required this.onTapEmpty,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hourLabel = DateFormat('h a').format(DateTime(2024, 1, 1, hour));
    final labelColor = isCurrentHour
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: hourHeight),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: labelWidth,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: Text(
                  hourLabel,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: labelColor,
                    fontWeight:
                        isCurrentHour ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isCurrentHour
                          ? theme.colorScheme.primary
                              .withValues(alpha: 0.4)
                          : theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.6),
                      width: isCurrentHour ? 1.5 : 0.5,
                    ),
                  ),
                ),
                child: tasks.isEmpty
                    ? InkWell(
                        onTap: onTapEmpty,
                        child: const SizedBox(width: double.infinity),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(0, 4, 12, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: tasks
                              .map((t) => _TimelineTaskTile(
                                    task: t,
                                    onToggle: () => onToggle(t),
                                    onTap: () => onTapTask(t),
                                  ))
                              .toList(),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineTaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _TimelineTaskTile({
    required this.task,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const priorityColors = {
      1: Colors.green,
      2: Colors.orange,
      3: Colors.red,
    };
    final stripeColor =
        task.taskColor ?? priorityColors[task.priority] ?? Colors.grey;
    final hasTime =
        task.dueDate != null && (task.dueDate!.hour != 0 || task.dueDate!.minute != 0);
    final timeLabel =
        hasTime ? DateFormat.jm().format(task.dueDate!) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  color: stripeColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          task.emoji != null
                              ? '${task.emoji}  ${task.title}'
                              : task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted
                                ? theme.colorScheme.onSurfaceVariant
                                : null,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (timeLabel != null)
                          Text(
                            timeLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    task.isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 22,
                    color: task.isCompleted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onToggle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
