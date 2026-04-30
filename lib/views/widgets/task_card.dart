import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../utils/app_localizations.dart';
import '../../viewmodels/user_profile_viewmodel.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onToggle,
    this.onDelete,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final priorityColors = {
      1: Colors.green,
      2: Colors.orange,
      3: Colors.red,
    };

    // Use task's custom color or fall back to priority color
    final indicatorColor =
        task.taskColor ?? priorityColors[task.priority] ?? Colors.grey;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        // Tint the card with user-chosen color
        color: task.taskColor != null
            ? Color.lerp(
                theme.colorScheme.surface, task.taskColor, 0.08)
            : null,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) => onToggle?.call(),
                  shape: const CircleBorder(),
                  activeColor: task.taskColor,
                ),
                // Color + Priority indicator
                Container(
                  width: 4,
                  height: 36,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.emoji != null
                            ? '${task.emoji}  ${task.title}'
                            : task.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isCompleted
                              ? theme.colorScheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                      if (task.description.isNotEmpty)
                        Text(
                          task.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _TagChip(label: task.category, theme: theme),
                          if (task.dueDate != null) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.calendar_today,
                                size: 12,
                                color: _isOverdue(task.dueDate!)
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 2),
                            Text(
                              _formatDate(task.dueDate!, l),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _isOverdue(task.dueDate!)
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (task.subTasks.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.checklist,
                                size: 12,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 2),
                            Text(
                              '${task.subTasks.where((s) => s.isCompleted).length}/${task.subTasks.length}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (task.recurrenceRule != null) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.repeat,
                                size: 12,
                                color: theme.colorScheme.primary),
                          ],
                          if (task.reminders.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.notifications_active,
                                size: 12,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 2),
                            Text(
                              '${task.reminders.length}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                          if (task.attachments.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.attach_file,
                                size: 12,
                                color: theme.colorScheme.onSurfaceVariant),
                          ],
                          if (task.assigneeId != null) ...[
                            const SizedBox(width: 6),
                            _AssigneeAvatar(uid: task.assigneeId!),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isOverdue(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isBefore(today) && !task.isCompleted;
  }

  String _formatDate(DateTime date, AppLocalizations l) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(date.year, date.month, date.day);

    String dayLabel;
    if (taskDate == today) {
      dayLabel = l.get('today');
    } else if (taskDate == tomorrow) {
      dayLabel = l.get('tomorrow');
    } else {
      dayLabel = '${date.day}/${date.month}';
    }

    // Append the time when the user actually picked one. Tasks created
    // with a date-only picker have hour=0 minute=0; the only false positive
    // is tasks deliberately set to midnight, which is rare enough to not
    // justify a separate "hasTime" flag on the model.
    final hasTime = date.hour != 0 || date.minute != 0;
    if (!hasTime) return dayLabel;
    return '$dayLabel · ${DateFormat.jm().format(date)}';
  }
}

class _AssigneeAvatar extends StatelessWidget {
  final String uid;
  const _AssigneeAvatar({required this.uid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileVM = context.watch<UserProfileViewModel>();
    return Tooltip(
      message: profileVM.displayName(uid),
      child: CircleAvatar(
        radius: 9,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          profileVM.initials(uid),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _TagChip({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
