import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/note.dart';
import '../../models/task.dart';
import '../../viewmodels/note_viewmodel.dart';
import '../../viewmodels/task_viewmodel.dart';

/// Cross-collection search across tasks and notes. Pure client-side filter
/// over the in-memory viewmodel data — no Firestore round-trip, so it
/// responds on every keystroke.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskVM = context.watch<TaskViewModel>();
    final noteVM = context.watch<NoteViewModel>();

    final q = _query.trim().toLowerCase();
    final tasks = q.isEmpty
        ? const <Task>[]
        : taskVM.tasks
            .where((t) =>
                t.title.toLowerCase().contains(q) ||
                t.description.toLowerCase().contains(q))
            .toList();
    final notes = q.isEmpty
        ? const <Note>[]
        : noteVM.notes
            .where((n) =>
                n.title.toLowerCase().contains(q) ||
                n.body.toLowerCase().contains(q))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search tasks and notes',
            border: InputBorder.none,
          ),
          style: theme.textTheme.titleMedium,
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _ctrl.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: q.isEmpty
          ? _EmptyHint()
          : (tasks.isEmpty && notes.isEmpty)
              ? _NoResults(query: _query)
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    if (tasks.isNotEmpty) ...[
                      _SectionLabel(label: 'Tasks', count: tasks.length),
                      ...tasks.map((t) => _TaskResultTile(
                            task: t,
                            query: q,
                            onTap: () => context.push('/add-task', extra: t),
                          )),
                    ],
                    if (notes.isNotEmpty) ...[
                      _SectionLabel(label: 'Notes', count: notes.length),
                      ...notes.map((n) => _NoteResultTile(
                            note: n,
                            query: q,
                            // Notes are managed inline on the Notes screen;
                            // sending the user there scoped to their query
                            // would need a query param on /notes — for now
                            // just open the screen.
                            onTap: () => context.push('/notes'),
                          )),
                    ],
                  ],
                ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search,
              size: 64, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'Start typing to search',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off,
                size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No results for "$query"',
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

class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;
  const _SectionLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        '$label · $count',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _TaskResultTile extends StatelessWidget {
  final Task task;
  final String query;
  final VoidCallback onTap;

  const _TaskResultTile({
    required this.task,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
        child: Icon(
          task.isCompleted ? Icons.check_circle : Icons.task_alt,
          color: theme.colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: _Highlighted(
        text: task.emoji != null ? '${task.emoji}  ${task.title}' : task.title,
        query: query,
        baseStyle: theme.textTheme.bodyLarge?.copyWith(
          decoration:
              task.isCompleted ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: task.description.isEmpty
          ? null
          : _Highlighted(
              text: task.description,
              query: query,
              maxLines: 2,
              baseStyle: theme.textTheme.bodySmall,
            ),
      onTap: onTap,
    );
  }
}

class _NoteResultTile extends StatelessWidget {
  final Note note;
  final String query;
  final VoidCallback onTap;

  const _NoteResultTile({
    required this.note,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Color(note.colorValue).withValues(alpha: 0.5),
        child: const Icon(Icons.sticky_note_2_outlined,
            color: Colors.black87, size: 20),
      ),
      title: _Highlighted(
        text: note.title.isEmpty ? '(Untitled note)' : note.title,
        query: query,
        baseStyle: theme.textTheme.bodyLarge,
      ),
      subtitle: note.body.isEmpty
          ? null
          : _Highlighted(
              text: note.body,
              query: query,
              maxLines: 2,
              baseStyle: theme.textTheme.bodySmall,
            ),
      onTap: onTap,
    );
  }
}

/// Renders [text] with case-insensitive matches of [query] highlighted in
/// the primary color. Falls back to plain [text] when [query] is empty
/// or when the text contains no matches.
class _Highlighted extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? baseStyle;
  final int? maxLines;

  const _Highlighted({
    required this.text,
    required this.query,
    this.baseStyle,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    if (q.isEmpty || !lower.contains(q)) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
      );
    }

    final spans = <TextSpan>[];
    int i = 0;
    while (i < text.length) {
      final idx = lower.indexOf(q, i);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(i)));
        break;
      }
      if (idx > i) {
        spans.add(TextSpan(text: text.substring(i, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + q.length),
        style: TextStyle(
          backgroundColor:
              theme.colorScheme.primary.withValues(alpha: 0.15),
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ));
      i = idx + q.length;
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
    );
  }
}
