import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../utils/app_localizations.dart';
import '../../viewmodels/task_viewmodel.dart';

class KanbanScreen extends StatelessWidget {
  const KanbanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final taskVM = context.watch<TaskViewModel>();

    // Split tasks into 3 columns
    final todoTasks =
        taskVM.tasks.where((t) => !t.isCompleted && !_isInProgress(t)).toList();
    final inProgressTasks =
        taskVM.tasks.where((t) => !t.isCompleted && _isInProgress(t)).toList();
    final doneTasks = taskVM.completedTasks;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.get('kanbanBoard')),
      ),
      body: Row(
        children: [
          // To Do column
          _KanbanColumn(
            title: l.get('toDo'),
            color: Colors.blue,
            tasks: todoTasks,
            theme: theme,
            onAccept: (task) {
              if (task.isCompleted) {
                taskVM.toggleComplete(task.id);
              }
            },
            onToggle: (id) => taskVM.toggleComplete(id),
          ),
          // In Progress column
          _KanbanColumn(
            title: l.get('inProgress'),
            color: Colors.orange,
            tasks: inProgressTasks,
            theme: theme,
            onAccept: (task) {
              if (task.isCompleted) {
                taskVM.toggleComplete(task.id);
              }
            },
            onToggle: (id) => taskVM.toggleComplete(id),
          ),
          // Done column
          _KanbanColumn(
            title: l.get('done'),
            color: Colors.green,
            tasks: doneTasks,
            theme: theme,
            onAccept: (task) {
              if (!task.isCompleted) {
                taskVM.toggleComplete(task.id);
              }
            },
            onToggle: (id) => taskVM.toggleComplete(id),
          ),
        ],
      ),
    );
  }

  /// A task is "in progress" if:
  /// - It has subtasks and some (but not all) are completed, OR
  /// - Its due date is today or in the past (actively working on it)
  bool _isInProgress(Task task) {
    if (task.subTasks.isNotEmpty) {
      final completedSubs = task.subTasks.where((s) => s.isCompleted).length;
      if (completedSubs > 0 && completedSubs < task.subTasks.length) return true;
    }
    if (task.dueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      if (!due.isAfter(today)) return true;
    }
    return false;
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final Color color;
  final List<Task> tasks;
  final ThemeData theme;
  final void Function(Task) onAccept;
  final void Function(String) onToggle;

  const _KanbanColumn({
    required this.title,
    required this.color,
    required this.tasks,
    required this.theme,
    required this.onAccept,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DragTarget<Task>(
        onAcceptWithDetails: (details) => onAccept(details.data),
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isHovering
                  ? color.withValues(alpha: 0.08)
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: isHovering
                  ? Border.all(color: color, width: 2)
                  : null,
            ),
            child: Column(
              children: [
                // Column header
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${tasks.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Task cards
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                          child: Text(
                            '—',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(6),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return Draggable<Task>(
                              data: task,
                              feedback: Material(
                                elevation: 6,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 140,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    task.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: _KanbanTaskCard(
                                    task: task, theme: theme, color: color),
                              ),
                              child: _KanbanTaskCard(
                                  task: task, theme: theme, color: color),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KanbanTaskCard extends StatelessWidget {
  final Task task;
  final ThemeData theme;
  final Color color;

  const _KanbanTaskCard({
    required this.task,
    required this.theme,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColors = {1: Colors.green, 2: Colors.orange, 3: Colors.red};

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: task.taskColor ??
                        priorityColors[task.priority] ??
                        Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
            if (task.dueDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.schedule, size: 10,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 2),
                  Text(
                    '${task.dueDate!.day}/${task.dueDate!.month}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
            if (task.subTasks.isNotEmpty) ...[
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: task.subTasks.where((s) => s.isCompleted).length /
                    task.subTasks.length,
                minHeight: 3,
                borderRadius: BorderRadius.circular(2),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
