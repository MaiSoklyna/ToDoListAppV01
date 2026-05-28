import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/project.dart';
import '../../utils/app_localizations.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final projectVM = context.watch<ProjectViewModel>();
    final taskVM = context.watch<TaskViewModel>();

    if (projectVM.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final projects = projectVM.projects;

    return Column(
      children: [
        // Add project button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showProjectDialog(context),
              icon: const Icon(Icons.add),
              label: Text(l.get('addProject')),
            ),
          ),
        ),

        // Inbox (no project) section
        _buildProjectTile(
          context,
          icon: Icons.inbox,
          color: theme.colorScheme.primary,
          name: l.get('inbox'),
          count: taskVM.getTasksByProject(null).length,
          onTap: () {}, // Already visible on home
        ),

        const Divider(indent: 16, endIndent: 16),

        // Projects list
        Expanded(
          child: projects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(
                        l.get('noProjectsYet'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    final taskCount =
                        taskVM.getTasksByProject(project.id).length;
                    final activeCount = taskVM
                        .getTasksByProject(project.id)
                        .where((t) => !t.isCompleted)
                        .length;

                    return Dismissible(
                      key: ValueKey(project.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: theme.colorScheme.error,
                        child: Icon(Icons.delete,
                            color: theme.colorScheme.onError),
                      ),
                      confirmDismiss: (_) => _confirmDeleteProject(
                          context, project, taskCount),
                      onDismissed: (_) =>
                          projectVM.deleteProject(project.id),
                      child: _buildProjectTile(
                        context,
                        icon: Icons.folder,
                        color: project.color,
                        name: project.name,
                        count: activeCount,
                        onTap: () => context.push('/project/${project.id}'),
                        onLongPress: () =>
                            _showProjectDialog(context, project: project),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProjectTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String name,
    required int count,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(name),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('$count', style: theme.textTheme.bodySmall),
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  Future<bool?> _confirmDeleteProject(
      BuildContext context, Project project, int taskCount) async {
    final l = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.get('deleteProject')),
        content: Text(taskCount > 0
            ? '${l.get('deleteProjectConfirm')} ($taskCount ${l.get('tasks')})'
            : l.get('deleteProjectConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.get('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l.get('deleteConfirm')),
          ),
        ],
      ),
    );
  }

  void _showProjectDialog(BuildContext context, {Project? project}) {
    final l = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: project?.name ?? '');
    int selectedColor = project?.colorValue ?? Project.presetColors[4];
    final isEditing = project != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? l.get('editProject') : l.get('addProject')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: l.get('projectName'),
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Project.presetColors.map((colorVal) {
                  final isSelected = selectedColor == colorVal;
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => selectedColor = colorVal),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(colorVal),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.get('cancel')),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                final projectVM = context.read<ProjectViewModel>();
                final authVM = context.read<AuthViewModel>();

                if (isEditing) {
                  project.name = name;
                  project.colorValue = selectedColor;
                  projectVM.updateProject(project);
                } else {
                  projectVM.addProject(Project(
                    id: const Uuid().v4(),
                    name: name,
                    colorValue: selectedColor,
                    userId: authVM.user?.uid,
                  ));
                }
                Navigator.pop(ctx);
              },
              child: Text(l.get('save')),
            ),
          ],
        ),
      ),
    );
  }
}
