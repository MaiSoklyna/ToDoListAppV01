import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/note.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/note_viewmodel.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notesVM = context.watch<NoteViewModel>();
    final notes = notesVM.notes;

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: notesVM.isLoading && notes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : notes.isEmpty
              ? const _EmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: notes.length,
                  itemBuilder: (_, i) => _NoteCard(
                    note: notes[i],
                    onTap: () => openEditor(context, notes[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openEditor(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  static Future<void> openEditor(BuildContext context, Note? existing) async {
    final uid = context.read<AuthViewModel>().user?.uid;
    if (uid == null) return;
    final result = await Navigator.of(context).push<Note>(
      MaterialPageRoute(
        builder: (_) => _NoteEditorScreen(
          note: existing,
          userId: uid,
        ),
      ),
    );
    if (result == null) return;
    if (!context.mounted) return;
    final notesVM = context.read<NoteViewModel>();
    if (existing == null) {
      await notesVM.addNote(result);
    } else {
      await notesVM.updateNote(result);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sticky_note_2_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No notes yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to capture a quick thought.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  const _NoteCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final notesVM = context.read<NoteViewModel>();
    final color = Color(note.colorValue);
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _confirmDelete(context, notesVM),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? 'Untitled' : note.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      note.pinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      size: 18,
                      color: Colors.black87,
                    ),
                    onPressed: () => notesVM.togglePin(note.id),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  note.body,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                  overflow: TextOverflow.fade,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat.yMMMd().format(note.updatedAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    NoteViewModel notesVM,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await notesVM.deleteNote(note.id);
  }
}

class _NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final String userId;
  const _NoteEditorScreen({required this.note, required this.userId});

  @override
  State<_NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<_NoteEditorScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late int _colorValue;
  late bool _pinned;

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    _titleCtrl = TextEditingController(text: n?.title ?? '');
    _bodyCtrl = TextEditingController(text: n?.body ?? '');
    _colorValue = n?.colorValue ?? Note.presetColors.first;
    _pinned = n?.pinned ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty && body.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final n = widget.note;
    final saved = n == null
        ? Note(
            id: const Uuid().v4(),
            title: title,
            body: body,
            colorValue: _colorValue,
            pinned: _pinned,
            userId: widget.userId,
          )
        : n.copyWith(
            title: title,
            body: body,
            colorValue: _colorValue,
            pinned: _pinned,
          );
    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(_colorValue),
      appBar: AppBar(
        backgroundColor: Color(_colorValue),
        // Note backgrounds are pastel in both themes — force dark
        // foreground so the back/pin/save icons stay readable in dark mode.
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_pinned ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: () => setState(() => _pinned = !_pinned),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _titleCtrl,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _bodyCtrl,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Note',
                  border: InputBorder.none,
                ),
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: Note.presetColors.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = Note.presetColors[i];
                  final selected = c == _colorValue;
                  return GestureDetector(
                    onTap: () => setState(() => _colorValue = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? Colors.black87
                              : Colors.black.withValues(alpha: 0.1),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              size: 18, color: Colors.black87)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
