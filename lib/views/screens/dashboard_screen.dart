import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../utils/app_localizations.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../../services/streak_service.dart';
import '../widgets/task_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StreakService _streakService = StreakService();
  int _currentStreak = 0;
  int _productivityScore = 0;

  static const List<String> _quotes = [
    "The secret of getting ahead is getting started.",
    "It always seems impossible until it's done.",
    "Small progress is still progress.",
    "Don't watch the clock; do what it does. Keep going.",
    "The only way to do great work is to love what you do.",
    "Focus on being productive instead of busy.",
    "Your future is created by what you do today.",
    "Done is better than perfect.",
    "One task at a time. One day at a time.",
    "Believe you can and you're halfway there.",
    "Success is the sum of small efforts repeated daily.",
    "Start where you are. Use what you have. Do what you can.",
  ];

  String get _dailyQuote {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return _quotes[dayOfYear % _quotes.length];
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final taskVM = context.read<TaskViewModel>();
    final results = await Future.wait([
      _streakService.getCurrentStreak(),
      _streakService.getProductivityScore(taskVM.tasks),
    ]);
    if (mounted) {
      setState(() {
        _currentStreak = results[0];
        _productivityScore = results[1];
      });
    }
  }

  String _getGreeting(AppLocalizations l) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l.get('goodMorning');
    if (hour < 17) return l.get('goodAfternoon');
    return l.get('goodEvening');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final taskVM = context.watch<TaskViewModel>();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayTasks = taskVM.tasks.where((t) {
      if (t.dueDate == null) return false;
      final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return d == today;
    }).toList();

    final overdueTasks = taskVM.tasks.where((t) {
      if (t.dueDate == null || t.isCompleted) return false;
      return t.dueDate!.isBefore(today);
    }).toList();

    final upcomingTasks = taskVM.tasks.where((t) {
      if (t.dueDate == null || t.isCompleted) return false;
      final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return d.isAfter(today) &&
          d.isBefore(today.add(const Duration(days: 7)));
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            _getGreeting(l),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _dailyQuote,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),

          // Quick stats row
          Row(
            children: [
              _QuickStatCard(
                icon: Icons.local_fire_department,
                iconColor: Colors.deepOrange,
                value: '$_currentStreak',
                label: l.get('streak'),
                theme: theme,
              ),
              const SizedBox(width: 12),
              _QuickStatCard(
                icon: Icons.speed,
                iconColor: _productivityScore >= 70
                    ? Colors.green
                    : _productivityScore >= 40
                        ? Colors.orange
                        : Colors.red,
                value: '$_productivityScore',
                label: l.get('score'),
                theme: theme,
              ),
              const SizedBox(width: 12),
              _QuickStatCard(
                icon: Icons.today,
                iconColor: theme.colorScheme.primary,
                value: '${todayTasks.length}',
                label: l.get('today'),
                theme: theme,
              ),
              const SizedBox(width: 12),
              _QuickStatCard(
                icon: Icons.warning_amber,
                iconColor: Colors.red,
                value: '${overdueTasks.length}',
                label: l.get('overdue'),
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick add templates
          Text(l.get('quickAdd'),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _TemplateChip(
                  icon: Icons.shopping_cart,
                  label: l.get('templateShopping'),
                  onTap: () => _createFromTemplate(
                      l.get('templateShopping'), 'Shopping', 2),
                ),
                const SizedBox(width: 8),
                _TemplateChip(
                  icon: Icons.fitness_center,
                  label: l.get('templateWorkout'),
                  onTap: () => _createFromTemplate(
                      l.get('templateWorkout'), 'Health', 2),
                ),
                const SizedBox(width: 8),
                _TemplateChip(
                  icon: Icons.book,
                  label: l.get('templateStudy'),
                  onTap: () => _createFromTemplate(
                      l.get('templateStudy'), 'Education', 3),
                ),
                const SizedBox(width: 8),
                _TemplateChip(
                  icon: Icons.meeting_room,
                  label: l.get('templateMeeting'),
                  onTap: () => _createFromTemplate(
                      l.get('templateMeeting'), 'Work', 3),
                ),
                const SizedBox(width: 8),
                _TemplateChip(
                  icon: Icons.call,
                  label: l.get('templateCall'),
                  onTap: () => _createFromTemplate(
                      l.get('templateCall'), 'Personal', 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Overdue tasks
          if (overdueTasks.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red, size: 20),
                const SizedBox(width: 6),
                Text(
                  '${l.get('overdue')} (${overdueTasks.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...overdueTasks.take(3).map((task) => TaskCard(
                  key: ValueKey(task.id),
                  task: task,
                  onToggle: () => taskVM.toggleComplete(task.id),
                  onTap: () {},
                  onDelete: () => _undoableDelete(context, task),
                )),
            const SizedBox(height: 16),
          ],

          // Today's tasks
          Row(
            children: [
              Icon(Icons.today, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 6),
              Text(
                '${l.get('todayTasks')} (${todayTasks.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (todayTasks.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 40,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text(l.get('noTasksToday'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          )),
                    ],
                  ),
                ),
              ),
            )
          else
            ...todayTasks.map((task) => TaskCard(
                  key: ValueKey(task.id),
                  task: task,
                  onToggle: () => taskVM.toggleComplete(task.id),
                  onTap: () {},
                  onDelete: () => _undoableDelete(context, task),
                )),

          // Projects overview
          Builder(
            builder: (context) {
              final projectVM = context.watch<ProjectViewModel>();
              final projects = projectVM.projects;
              if (projects.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(Icons.folder, color: theme.colorScheme.tertiary, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        l.get('projects'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: projects.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        final taskCount = taskVM.getTasksByProject(project.id)
                            .where((t) => !t.isCompleted)
                            .length;
                        return GestureDetector(
                          onTap: () => context.push('/project/${project.id}'),
                          child: Container(
                            width: 130,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: project.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: project.color.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: project.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        project.name,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$taskCount ${l.get('active').toLowerCase()}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),

          // Upcoming
          if (upcomingTasks.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.upcoming, color: Colors.blue, size: 20),
                const SizedBox(width: 6),
                Text(
                  '${l.get('upcoming')} (${upcomingTasks.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...upcomingTasks.take(5).map((task) => TaskCard(
                  key: ValueKey(task.id),
                  task: task,
                  onToggle: () => taskVM.toggleComplete(task.id),
                  onTap: () {},
                  onDelete: () => _undoableDelete(context, task),
                )),
          ],
        ],
      ),
    );
  }

  void _createFromTemplate(String title, String category, int priority) {
    context.push('/add-task', extra: Task(
      id: '',
      title: title,
      category: category,
      priority: priority,
    ));
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

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final ThemeData theme;

  const _QuickStatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(height: 4),
              Text(value,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TemplateChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
