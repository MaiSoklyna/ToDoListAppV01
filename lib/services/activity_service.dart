import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity.dart';

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _ref(String listId) =>
      _firestore.collection('sharedLists').doc(listId).collection('activity');

  /// Stream activity for a list, newest first, capped at [limit].
  Stream<List<Activity>> stream(String listId, {int limit = 100}) {
    return _ref(listId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Activity.fromFirestore(doc, listId))
            .toList());
  }

  /// Log an activity. Never throws — logging failures must not break the
  /// caller's primary operation.
  Future<void> log({
    required String listId,
    required String actorId,
    required ActivityType type,
    required String taskId,
    required String taskTitle,
    Map<String, dynamic> meta = const {},
  }) async {
    try {
      final doc = _ref(listId).doc();
      await doc.set(Activity(
        id: doc.id,
        listId: listId,
        actorId: actorId,
        type: type,
        taskId: taskId,
        taskTitle: taskTitle,
        meta: meta,
      ).toJson());
    } catch (_) {
      // Swallow — activity feed is non-critical telemetry.
    }
  }
}
