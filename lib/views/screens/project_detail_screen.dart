import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../utils/app_localizations.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../widgets/task_card.dart';

class ProjectDetailScreen extends StatelessWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final project = context.watch<ProjectViewModel>().getById(projectId);
    final taskVM = context.watch<TaskViewModel>();

    if (project == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l.get('projectNotFound'))),
      );
    }

    final tasks = taskVM.getTasksByProject(projectId);
    final activeTasks = tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = tasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: project.color,
                shape: BoxShape.circle,
              ),
            ),
            Text(project.name),
          ],
        ),
      ),
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open,
                      size: 64, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(l.get('noTasksYet'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary
                Row(
                  children: [
                    Text(
                      '${activeTasks.length} ${l.get('active').toLowerCase()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${completedTasks.length} ${l.get('completed').toLowerCase()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Active tasks
                ...activeTasks.map((task) => TaskCard(
                      key: ValueKey(task.id),
                      task: task,
                      onToggle: () => taskVM.toggleComplete(task.id),
                      onTap: () {},
                      onDelete: () => taskVM.deleteTask(task.id),
                    )),
                // Completed tasks
                if (completedTasks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(l.get('completed'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                  const SizedBox(height: 8),
                  ...completedTasks.map((task) => TaskCard(
                        key: ValueKey(task.id),
                        task: task,
                        onToggle: () => taskVM.toggleComplete(task.id),
                        onTap: () {},
                        onDelete: () => taskVM.deleteTask(task.id),
                      )),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-task', extra: Task(
          id: '',
          title: '',
          projectId: projectId,
        )),
        child: const Icon(Icons.add),
      ),
    );
  }
}
