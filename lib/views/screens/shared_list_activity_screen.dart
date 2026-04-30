import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/activity.dart';
import '../../services/activity_service.dart';
import '../../viewmodels/shared_list_viewmodel.dart';
import '../../viewmodels/user_profile_viewmodel.dart';

class SharedListActivityScreen extends StatefulWidget {
  final String listId;
  const SharedListActivityScreen({super.key, required this.listId});

  @override
  State<SharedListActivityScreen> createState() =>
      _SharedListActivityScreenState();
}

class _SharedListActivityScreenState extends State<SharedListActivityScreen> {
  final _service = ActivityService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list =
        context.watch<SharedListViewModel>().getById(widget.listId);

    return Scaffold(
      appBar: AppBar(
        title: Text(list != null ? '${list.name} • Activity' : 'Activity'),
      ),
      body: StreamBuilder<List<Activity>>(
        stream: _service.stream(widget.listId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load activity.',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            );
          }
          final events = snap.data ?? const [];
          if (events.isEmpty) {
            return _EmptyState();
          }

          // Resolve any actor uids we haven't cached yet.
          final profileVM = context.read<UserProfileViewModel>();
          final actors = events.map((e) => e.actorId).toSet();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            profileVM.ensureLoaded(actors);
          });

          return ListView.separated(
            itemCount: events.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) => _ActivityTile(event: events[i]),
          );
        },
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Activity event;
  const _ActivityTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileVM = context.watch<UserProfileViewModel>();
    final actorName = profileVM.displayName(event.actorId);

    final (icon, color) = _iconFor(event.type, theme);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: actorName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: ' ${_verb(event, profileVM)} '),
            TextSpan(
              text: event.taskTitle.isEmpty ? 'a task' : '"${event.taskTitle}"',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      subtitle: Text(
        _formatTimestamp(event.timestamp),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  (IconData, Color) _iconFor(ActivityType type, ThemeData theme) {
    switch (type) {
      case ActivityType.created:
        return (Icons.add_task, Colors.blue);
      case ActivityType.edited:
        return (Icons.edit_outlined, theme.colorScheme.primary);
      case ActivityType.completed:
        return (Icons.check_circle_outline, Colors.green);
      case ActivityType.uncompleted:
        return (Icons.unpublished_outlined, Colors.orange);
      case ActivityType.assigned:
        return (Icons.person_add_alt, Colors.purple);
      case ActivityType.unassigned:
        return (Icons.person_remove_alt_1, Colors.grey);
      case ActivityType.deleted:
        return (Icons.delete_outline, theme.colorScheme.error);
    }
  }

  String _verb(Activity event, UserProfileViewModel profileVM) {
    switch (event.type) {
      case ActivityType.created:
        return 'created';
      case ActivityType.edited:
        return 'edited';
      case ActivityType.completed:
        return 'completed';
      case ActivityType.uncompleted:
        return 'reopened';
      case ActivityType.assigned:
        final assigneeId = event.meta['assigneeId'] as String?;
        if (assigneeId == null) return 'assigned';
        return 'assigned ${profileVM.displayName(assigneeId)} to';
      case ActivityType.unassigned:
        return 'unassigned';
      case ActivityType.deleted:
        return 'deleted';
    }
  }

  String _formatTimestamp(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history,
                size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No activity yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Edits to tasks in this list will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
