import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:todolistapp/models/category.dart';
import 'package:todolistapp/models/label.dart';
import 'package:todolistapp/models/note.dart';
import 'package:todolistapp/models/project.dart';
import 'package:todolistapp/models/task.dart';
import 'package:todolistapp/services/export_service.dart';

/// In-memory fakes for the add-* callbacks, so we can assert what the
/// restore actually attempted to write without touching Firestore.
class _Recorder {
  final List<Task> tasks = [];
  final List<Project> projects = [];
  final List<Label> labels = [];
  final List<Note> notes = [];
  final List<TaskCategory> categories = [];
}

Future<File> _writeBackup(Map<String, dynamic> payload) async {
  final dir = await Directory.systemTemp.createTemp('backup_test_');
  final file = File('${dir.path}/backup.json');
  await file.writeAsString(jsonEncode(payload));
  return file;
}

void main() {
  late ExportService service;
  late _Recorder rec;

  setUp(() {
    service = ExportService();
    rec = _Recorder();
  });

  group('restoreFromBackupJson — happy path', () {
    test('v2 backup with all entity types adds them and re-stamps userId',
        () async {
      final file = await _writeBackup({
        'schemaVersion': 2,
        'exportedAt': '2026-04-01T00:00:00.000Z',
        'projects': [
          {
            'id': 'p1',
            'name': 'Work',
            'colorValue': 0xFF2196F3,
            'userId': 'someone_else',
            'createdAt': '2026-01-01T00:00:00.000Z',
          }
        ],
        'labels': [
          {
            'id': 'l1',
            'name': 'urgent',
            'colorValue': 0xFFFF0000,
            'userId': 'someone_else',
          }
        ],
        'tasks': [
          {
            'id': 't1',
            'title': 'Ship it',
            'description': '',
            'category': 'Work',
            'priority': 2,
            'isCompleted': false,
            'subTasks': const [],
            'isRecurring': false,
            'createdAt': '2026-01-01T00:00:00.000Z',
            'userId': 'someone_else',
            'labelIds': const [],
            'attachments': const [],
            'sharedListId': 'shared_xyz',
            'assigneeId': 'other_user',
          }
        ],
        'notes': [
          {
            'id': 'n1',
            'title': 'Reminder',
            'body': 'Do the thing',
            'colorValue': 0xFFFFF59D,
            'pinned': false,
            'userId': 'someone_else',
            'createdAt': '2026-01-01T00:00:00.000Z',
            'updatedAt': '2026-01-01T00:00:00.000Z',
          }
        ],
        'categories': [
          {
            'id': 'c1',
            'name': 'Side project',
            'iconCodePoint': 0xe865, // Icons.work codepoint family-agnostic
            'colorValue': 0xFF00BCD4,
            'userId': 'someone_else',
          }
        ],
      });

      final result = await service.restoreFromBackupJson(
        path: file.path,
        userId: 'current_uid',
        addTask: (t) async => rec.tasks.add(t),
        addProject: (p) async => rec.projects.add(p),
        addLabel: (l) async => rec.labels.add(l),
        addNote: (n) async => rec.notes.add(n),
        addCategory: (c) async => rec.categories.add(c),
        existingTaskIds: const {},
        existingProjectIds: const {},
        existingLabelIds: const {},
        existingNoteIds: const {},
        existingCategoryIds: const {},
      );

      // Counts.
      expect(result.tasksAdded, 1);
      expect(result.projectsAdded, 1);
      expect(result.labelsAdded, 1);
      expect(result.notesAdded, 1);
      expect(result.categoriesAdded, 1);
      expect(result.totalSkipped, 0);
      expect(result.totalFailed, 0);

      // Re-stamping.
      expect(rec.tasks.single.userId, 'current_uid');
      expect(rec.projects.single.userId, 'current_uid');
      expect(rec.labels.single.userId, 'current_uid');
      expect(rec.notes.single.userId, 'current_uid');
      expect(rec.categories.single.userId, 'current_uid');

      // Tasks lose sharedListId/assigneeId on restore so they don't try to
      // write to a shared list the new account isn't a member of.
      expect(rec.tasks.single.sharedListId, isNull);
      expect(rec.tasks.single.assigneeId, isNull);
    });
  });

  group('restoreFromBackupJson — skip + filter behavior', () {
    test('entities whose ids are already present are skipped', () async {
      final file = await _writeBackup({
        'schemaVersion': 2,
        'tasks': [
          _minimalTaskJson('t_existing'),
          _minimalTaskJson('t_new'),
        ],
        'categories': [
          _minimalCategoryJson('c_existing'),
          _minimalCategoryJson('c_new'),
        ],
      });

      final result = await service.restoreFromBackupJson(
        path: file.path,
        userId: 'uid',
        addTask: (t) async => rec.tasks.add(t),
        addProject: (_) async {},
        addLabel: (_) async {},
        addNote: (_) async {},
        addCategory: (c) async => rec.categories.add(c),
        existingTaskIds: const {'t_existing'},
        existingProjectIds: const {},
        existingLabelIds: const {},
        existingNoteIds: const {},
        existingCategoryIds: const {'c_existing', 'general'},
      );

      expect(result.tasksAdded, 1);
      expect(result.tasksSkipped, 1);
      expect(rec.tasks.single.id, 't_new');

      expect(result.categoriesAdded, 1);
      expect(result.categoriesSkipped, 1);
      expect(rec.categories.single.id, 'c_new');
    });

    test('summary text mentions added counts', () async {
      final file = await _writeBackup({
        'schemaVersion': 2,
        'tasks': [_minimalTaskJson('t1')],
        'notes': [_minimalNoteJson('n1')],
      });

      final result = await service.restoreFromBackupJson(
        path: file.path,
        userId: 'uid',
        addTask: (_) async {},
        addProject: (_) async {},
        addLabel: (_) async {},
        addNote: (_) async {},
        addCategory: (_) async {},
        existingTaskIds: const {},
        existingProjectIds: const {},
        existingLabelIds: const {},
        existingNoteIds: const {},
        existingCategoryIds: const {},
      );

      expect(result.summary(), contains('1 tasks'));
      expect(result.summary(), contains('1 notes'));
    });
  });

  group('restoreFromBackupJson — version compatibility', () {
    test('v1 backup (no categories key) restores tasks/projects/labels/notes',
        () async {
      // v1 had no `categories` field. The restore should treat the missing
      // key as an empty list — no error, no failure count.
      final file = await _writeBackup({
        'schemaVersion': 1,
        'tasks': [_minimalTaskJson('t1')],
        'projects': const [],
        'labels': const [],
        'notes': const [],
      });

      final result = await service.restoreFromBackupJson(
        path: file.path,
        userId: 'uid',
        addTask: (t) async => rec.tasks.add(t),
        addProject: (_) async {},
        addLabel: (_) async {},
        addNote: (_) async {},
        addCategory: (_) async {},
        existingTaskIds: const {},
        existingProjectIds: const {},
        existingLabelIds: const {},
        existingNoteIds: const {},
        existingCategoryIds: const {},
      );

      expect(result.tasksAdded, 1);
      expect(result.categoriesAdded, 0);
      expect(result.totalFailed, 0);
    });

    test('payload with future schemaVersion is rejected', () async {
      final file = await _writeBackup({
        'schemaVersion': 999,
        'tasks': const [],
      });

      expect(
        () => service.restoreFromBackupJson(
          path: file.path,
          userId: 'uid',
          addTask: (_) async {},
          addProject: (_) async {},
          addLabel: (_) async {},
          addNote: (_) async {},
          addCategory: (_) async {},
          existingTaskIds: const {},
          existingProjectIds: const {},
          existingLabelIds: const {},
          existingNoteIds: const {},
          existingCategoryIds: const {},
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('non-object payload is rejected', () async {
      final dir = await Directory.systemTemp.createTemp('backup_test_');
      final file = File('${dir.path}/bad.json');
      await file.writeAsString(jsonEncode(['not', 'an', 'object']));

      expect(
        () => service.restoreFromBackupJson(
          path: file.path,
          userId: 'uid',
          addTask: (_) async {},
          addProject: (_) async {},
          addLabel: (_) async {},
          addNote: (_) async {},
          addCategory: (_) async {},
          existingTaskIds: const {},
          existingProjectIds: const {},
          existingLabelIds: const {},
          existingNoteIds: const {},
          existingCategoryIds: const {},
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('restoreFromBackupJson — failure isolation', () {
    test('one failing add does not block other entities', () async {
      final file = await _writeBackup({
        'schemaVersion': 2,
        'tasks': [
          _minimalTaskJson('t_ok'),
          _minimalTaskJson('t_boom'),
          _minimalTaskJson('t_also_ok'),
        ],
      });

      final result = await service.restoreFromBackupJson(
        path: file.path,
        userId: 'uid',
        addTask: (t) async {
          if (t.id == 't_boom') throw Exception('simulated firestore error');
          rec.tasks.add(t);
        },
        addProject: (_) async {},
        addLabel: (_) async {},
        addNote: (_) async {},
        addCategory: (_) async {},
        existingTaskIds: const {},
        existingProjectIds: const {},
        existingLabelIds: const {},
        existingNoteIds: const {},
        existingCategoryIds: const {},
      );

      expect(result.tasksAdded, 2);
      expect(result.tasksFailed, 1);
      expect(rec.tasks.map((t) => t.id), containsAll(['t_ok', 't_also_ok']));
    });
  });
}

Map<String, dynamic> _minimalTaskJson(String id) => {
      'id': id,
      'title': 'Task $id',
      'description': '',
      'category': 'General',
      'priority': 2,
      'isCompleted': false,
      'subTasks': const [],
      'isRecurring': false,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'userId': 'someone_else',
      'labelIds': const [],
      'attachments': const [],
    };

Map<String, dynamic> _minimalCategoryJson(String id) => {
      'id': id,
      'name': 'Cat $id',
      'iconCodePoint': 0xe865,
      'colorValue': 0xFF2196F3,
      'userId': 'someone_else',
    };

Map<String, dynamic> _minimalNoteJson(String id) => {
      'id': id,
      'title': 'Note $id',
      'body': '',
      'colorValue': 0xFFFFF59D,
      'pinned': false,
      'userId': 'someone_else',
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-01T00:00:00.000Z',
    };
