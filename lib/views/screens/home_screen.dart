import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/app_localizations.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../../models/task.dart';
import '../widgets/task_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _filter = 'all'; // all, active, completed
  String _sortBy = 'created'; // created, priority, dueDate, name
  String _searchQuery = '';
  bool _isSearching = false;
  // Batch mode
  bool _isBatchMode = false;
  final Set<String> _selectedIds = {};

  List<Task> _getFilteredTasks(TaskViewModel taskVM) {
    List<Task> tasks;
    switch (_filter) {
      case 'active':
        tasks = taskVM.activeTasks;
        break;
      case 'completed':
        tasks = taskVM.completedTasks;
        break;
      default:
        tasks = List.from(taskVM.tasks);
    }

    if (_searchQuery.isNotEmpty) {
      tasks = tasks
          .where((t) =>
              t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Sort
    switch (_sortBy) {
      case 'priority':
        tasks.sort((a, b) => b.priority.compareTo(a.priority));
        break;
      case 'dueDate':
        tasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case 'name':
        tasks.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      default: // 'created' - newest first (default from Firestore)
        break;
    }

    return tasks;
  }

  void _exitBatchMode() {
    setState(() {
      _isBatchMode = false;
      _selectedIds.clear();
    });
  }

  void _batchComplete() {
    final taskVM = context.read<TaskViewModel>();
    for (final id in _selectedIds) {
      try {
        final task = taskVM.tasks.firstWhere((t) => t.id == id);
        if (!task.isCompleted) {
          taskVM.toggleComplete(id);
        }
      } catch (_) {
        // Task may have been deleted elsewhere, skip it
      }
    }
    _exitBatchMode();
  }

  void _batchDelete() {
    final l = AppLocalizations.of(context);
    final taskVM = context.read<TaskViewModel>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.get('deleteTask')),
        content: Text(
            '${l.get('batchDeleteConfirm')} ${_selectedIds.length} ${l.get('tasks')}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.get('cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              for (final id in _selectedIds) {
                taskVM.deleteTask(id);
              }
              _exitBatchMode();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l.get('deleteConfirm')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskVM = context.watch<TaskViewModel>();
    final tasks = _getFilteredTasks(taskVM);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Column(
      children: [
        // Batch mode toolbar
        if (_isBatchMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.primaryContainer,
            child: Row(
              children: [
                Text(
                  '${_selectedIds.length} ${l.get('selected')}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.check_circle),
                  tooltip: l.get('markComplete'),
                  onPressed:
                      _selectedIds.isNotEmpty ? _batchComplete : null,
                ),
                IconButton(
                  icon: Icon(Icons.delete,
                      color: theme.colorScheme.error),
                  tooltip: l.get('deleteConfirm'),
                  onPressed:
                      _selectedIds.isNotEmpty ? _batchDelete : null,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _exitBatchMode,
                ),
              ],
            ),
          ),

        // Search bar
        if (_isSearching)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: l.get('searchTasks'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                  }),
                ),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

        // Filter chips + sort + search + batch toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              FilterChip(
                label: Text(l.get('all')),
                selected: _filter == 'all',
                onSelected: (_) => setState(() => _filter = 'all'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(l.get('active')),
                selected: _filter == 'active',
                onSelected: (_) => setState(() => _filter = 'active'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(l.get('done')),
                selected: _filter == 'completed',
                onSelected: (_) => setState(() => _filter = 'completed'),
              ),
              const Spacer(),
              // Sort button
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort, size: 20),
                tooltip: l.get('sortBy'),
                onSelected: (v) => setState(() => _sortBy = v),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'created',
                    child: _sortMenuItem(
                        Icons.access_time, l.get('sortCreated'), 'created'),
                  ),
                  PopupMenuItem(
                    value: 'priority',
                    child: _sortMenuItem(
                        Icons.flag, l.get('sortPriority'), 'priority'),
                  ),
                  PopupMenuItem(
                    value: 'dueDate',
                    child: _sortMenuItem(
                        Icons.calendar_today, l.get('sortDueDate'), 'dueDate'),
                  ),
                  PopupMenuItem(
                    value: 'name',
                    child: _sortMenuItem(
                        Icons.sort_by_alpha, l.get('sortName'), 'name'),
                  ),
                ],
              ),
              if (!_isSearching)
                IconButton(
                  icon: const Icon(Icons.search, size: 20),
                  onPressed: () => setState(() => _isSearching = true),
                ),
              // Batch mode toggle
              IconButton(
                icon: Icon(
                  _isBatchMode ? Icons.checklist : Icons.checklist_outlined,
                  size: 20,
                ),
                tooltip: l.get('batchMode'),
                onPressed: () => setState(() {
                  _isBatchMode = !_isBatchMode;
                  _selectedIds.clear();
                }),
              ),
            ],
          ),
        ),

        // Task summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${taskVM.activeTasks.length} ${l.get('active').toLowerCase()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${taskVM.completedTasks.length} ${l.get('completed').toLowerCase()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Task list
        Expanded(
          child: taskVM.isLoading
              ? const Center(child: CircularProgressIndicator())
              : tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.task_outlined,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text(
                            _filter == 'completed'
                                ? l.get('noCompletedTasks')
                                : l.get('noTasksYet'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        final authVM = context.read<AuthViewModel>();
                        final userId = authVM.user?.uid;
                        if (userId != null) {
                          await context.read<TaskViewModel>().loadTasks(userId);
                        }
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];

                          if (_isBatchMode) {
                            final isSelected = _selectedIds.contains(task.id);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer
                                  : null,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedIds.remove(task.id);
                                    } else {
                                      _selectedIds.add(task.id);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 12),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (_) {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedIds.remove(task.id);
                                            } else {
                                              _selectedIds.add(task.id);
                                            }
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          task.title,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: TaskCard(
                              key: ValueKey(task.id),
                              task: task,
                              onToggle: () => taskVM.toggleComplete(task.id),
                              onTap: () => _showTaskDetail(context, task),
                              onDelete: () =>
                                  _undoableDelete(context, task),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _sortMenuItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
        if (_sortBy == value) ...[
          const Spacer(),
          Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary),
        ],
      ],
    );
  }

  void _showTaskDetail(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _TaskDetailSheet(task: task),
    );
  }

  void _undoableDelete(BuildContext context, Task task) {
    final l = AppLocalizations.of(context);
    final taskVM = context.read<TaskViewModel>();
    taskVM.deleteTask(task.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${task.title} ${l.get('deleted')}'),
        action: SnackBarAction(
          label: l.get('undo'),
          onPressed: () => taskVM.addTask(task),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

class _TaskDetailSheet extends StatelessWidget {
  final Task task;
  const _TaskDetailSheet({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final priorityLabels = {
      1: l.get('low'),
      2: l.get('medium'),
      3: l.get('high'),
    };
    final priorityColors = {
      1: Colors.green,
      2: Colors.orange,
      3: Colors.red,
    };

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scrollCtrl) => SingleChildScrollView(
        controller: scrollCtrl,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (task.taskColor != null) ...[
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: task.taskColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColors[task.priority]!
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    priorityLabels[task.priority]!,
                    style: TextStyle(
                      color: priorityColors[task.priority],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (task.description.isNotEmpty) ...[
              Text(task.description, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.category, size: 16),
                  label: Text(task.category),
                ),
                if (task.dueDate != null)
                  Chip(
                    avatar: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                    ),
                  ),
                Chip(
                  avatar: Icon(
                    task.isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 16,
                  ),
                  label: Text(task.isCompleted
                      ? l.get('completed')
                      : l.get('active')),
                ),
                if (task.recurrenceRule != null)
                  Chip(
                    avatar: const Icon(Icons.repeat, size: 16),
                    label: Text(task.recurrenceRule!.toDisplayString()),
                  ),
              ],
            ),
            if (task.subTasks.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(l.get('subtasks'),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...task.subTasks.map((sub) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      sub.isCompleted
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 20,
                    ),
                    title: Text(
                      sub.title,
                      style: TextStyle(
                        decoration: sub.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  )),
            ],
            if (task.attachments.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(l.get('attachments'),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...task.attachments.map((att) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      att.startsWith('http') ? Icons.link : Icons.note,
                      size: 20,
                    ),
                    title:
                        Text(att, maxLines: 2, overflow: TextOverflow.ellipsis),
                  )),
            ],
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/add-task', extra: task);
                    },
                    icon: const Icon(Icons.edit),
                    label: Text(l.get('editTask')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final priorityNames = {
                        1: l.get('low'),
                        2: l.get('medium'),
                        3: l.get('high'),
                      };
                      final text =
                          '${task.title}\n${task.description.isNotEmpty ? '${task.description}\n' : ''}${l.get('priority')}: ${priorityNames[task.priority]}\n${l.get('category')}: ${task.category}';
                      SharePlus.instance.share(ShareParams(text: text));
                    },
                    icon: const Icon(Icons.share),
                    label: Text(l.get('shareTask')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
