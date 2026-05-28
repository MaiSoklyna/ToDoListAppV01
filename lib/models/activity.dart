import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  created,
  edited,
  completed,
  uncompleted,
  assigned,
  unassigned,
  deleted,
}

extension ActivityTypeX on ActivityType {
  String get value => name;

  static ActivityType fromString(String? raw) {
    for (final t in ActivityType.values) {
      if (t.name == raw) return t;
    }
    return ActivityType.edited;
  }
}

class Activity {
  final String id;
  final String listId;
  final String actorId;
  final ActivityType type;
  final String taskId;

  /// Denormalized so the feed still reads sensibly after a task is deleted.
  final String taskTitle;

  /// Free-form context — for `assigned`/`unassigned` we put `assigneeId` here.
  final Map<String, dynamic> meta;

  final DateTime timestamp;

  Activity({
    required this.id,
    required this.listId,
    required this.actorId,
    required this.type,
    required this.taskId,
    required this.taskTitle,
    this.meta = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'actorId': actorId,
        'type': type.value,
        'taskId': taskId,
        'taskTitle': taskTitle,
        'meta': meta,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Activity.fromFirestore(DocumentSnapshot doc, String listId) {
    final data = doc.data() as Map<String, dynamic>;
    return Activity(
      id: doc.id,
      listId: listId,
      actorId: data['actorId'] as String? ?? '',
      type: ActivityTypeX.fromString(data['type'] as String?),
      taskId: data['taskId'] as String? ?? '',
      taskTitle: data['taskTitle'] as String? ?? '',
      meta: (data['meta'] as Map<String, dynamic>?) ?? const {},
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'] as String)
          : null,
    );
  }
}
