import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/comment.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _ref(String taskId) =>
      _firestore.collection('tasks').doc(taskId).collection('comments');

  Stream<List<Comment>> stream(String taskId) {
    return _ref(taskId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Comment.fromFirestore(doc, taskId))
            .toList());
  }

  Future<Comment> add({
    required String taskId,
    required String authorId,
    required String body,
  }) async {
    final doc = _ref(taskId).doc();
    final comment = Comment(
      id: doc.id,
      taskId: taskId,
      authorId: authorId,
      body: body,
    );
    await doc.set(comment.toJson());
    return comment;
  }

  Future<void> update({
    required String taskId,
    required String commentId,
    required String body,
  }) async {
    await _ref(taskId).doc(commentId).update({
      'body': body,
      'editedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> delete({required String taskId, required String commentId}) {
    return _ref(taskId).doc(commentId).delete();
  }
}
