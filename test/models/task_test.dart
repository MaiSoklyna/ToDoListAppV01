import 'package:flutter_test/flutter_test.dart';
import 'package:todolistapp/models/recurrence.dart';
import 'package:todolistapp/models/reminder.dart';
import 'package:todolistapp/models/task.dart';

void main() {
  group('Task.fromJson backward compatibility', () {
    test('legacy payload (no reminders/emoji/estimatedMinutes) deserializes '
        'with safe defaults', () {
      // This is the shape every existing Firestore doc has today. Adding
      // optional fields must not break it.
      final legacy = <String, dynamic>{
        'id': 'task_legacy',
        'title': 'Buy milk',
        'description': '',
        'category': 'Shopping',
        'priority': 2,
        'isCompleted': false,
        'subTasks': const [],
        'isRecurring': false,
        'createdAt': '2025-01-01T08:00:00.000Z',
        'userId': 'uid_abc',
        'labelIds': const [],
        'attachments': const [],
      };

      final task = Task.fromJson(legacy);

      expect(task.id, 'task_legacy');
      expect(task.title, 'Buy milk');
      expect(task.reminders, isEmpty);
      expect(task.emoji, isNull);
      expect(task.estimatedMinutes, isNull);
      expect(task.completionNote, isNull);
      // Existing fields keep working too.
      expect(task.priority, 2);
      expect(task.userId, 'uid_abc');
    });

    test('new fields round-trip through toJson/fromJson', () {
      final original = Task(
        id: 'task_new',
        title: 'Prep slides',
        userId: 'uid_xyz',
        priority: 3,
        dueDate: DateTime.utc(2026, 5, 1, 9),
        reminders: [
          TaskReminder(
            id: 'r1',
            fireAt: DateTime.utc(2026, 5, 1, 8),
            offsetMinutesBeforeDue: 60,
          ),
          TaskReminder(
            id: 'r2',
            fireAt: DateTime.utc(2026, 4, 30, 9),
            offsetMinutesBeforeDue: 1440,
            snoozedUntil: DateTime.utc(2026, 4, 30, 10),
          ),
        ],
        emoji: '🎯',
        estimatedMinutes: 45,
        completionNote: 'Done early',
        recurrenceRule: const RecurrenceRule(
          type: RecurrenceType.weekly,
          interval: 1,
          daysOfWeek: [1, 3, 5],
        ),
      );

      final round = Task.fromJson(original.toJson());

      expect(round.reminders.length, 2);
      expect(round.reminders[0].id, 'r1');
      expect(round.reminders[0].offsetMinutesBeforeDue, 60);
      expect(round.reminders[0].snoozedUntil, isNull);
      expect(round.reminders[1].snoozedUntil, isNotNull);
      expect(round.reminders[1].snoozedUntil!.toUtc(),
          DateTime.utc(2026, 4, 30, 10));
      expect(round.emoji, '🎯');
      expect(round.estimatedMinutes, 45);
      expect(round.completionNote, 'Done early');
      // Recurrence still survives the round-trip.
      expect(round.recurrenceRule, isNotNull);
      expect(round.recurrenceRule!.type, RecurrenceType.weekly);
      expect(round.recurrenceRule!.daysOfWeek, [1, 3, 5]);
    });

    test('toJson omits empty/null new fields so legacy docs round-trip '
        'without bloat', () {
      final task = Task(
        id: 'task_minimal',
        title: 'Hello',
      );

      final json = task.toJson();

      // Every required/legacy key is present.
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('title'), isTrue);
      expect(json.containsKey('subTasks'), isTrue);
      // New optional keys are NOT serialized when empty/null.
      expect(json.containsKey('reminders'), isFalse);
      expect(json.containsKey('emoji'), isFalse);
      expect(json.containsKey('estimatedMinutes'), isFalse);
      expect(json.containsKey('completionNote'), isFalse);
    });

    test('toJson includes new fields when set', () {
      final task = Task(
        id: 'task_decorated',
        title: 'Hello',
        emoji: '⭐',
        estimatedMinutes: 15,
        reminders: [
          TaskReminder(
            id: 'r1',
            fireAt: DateTime.utc(2026, 6, 1),
          ),
        ],
      );

      final json = task.toJson();

      expect(json['emoji'], '⭐');
      expect(json['estimatedMinutes'], 15);
      expect((json['reminders'] as List).length, 1);
    });
  });

  group('Task.copyWith new field flags', () {
    test('clearEmoji wipes emoji even when emoji arg is null', () {
      final t = Task(id: 'a', title: 't', emoji: '🚀');
      final cleared = t.copyWith(clearEmoji: true);
      expect(cleared.emoji, isNull);
    });

    test('clearEstimatedMinutes wipes the value', () {
      final t = Task(id: 'a', title: 't', estimatedMinutes: 30);
      final cleared = t.copyWith(clearEstimatedMinutes: true);
      expect(cleared.estimatedMinutes, isNull);
    });

    test('reminders replacement does not affect other fields', () {
      final t = Task(
        id: 'a',
        title: 't',
        priority: 3,
        emoji: '🔥',
      );
      final updated = t.copyWith(
        reminders: [
          TaskReminder(id: 'r', fireAt: DateTime.utc(2026, 1, 1)),
        ],
      );
      expect(updated.reminders.length, 1);
      expect(updated.priority, 3);
      expect(updated.emoji, '🔥');
    });
  });
}
