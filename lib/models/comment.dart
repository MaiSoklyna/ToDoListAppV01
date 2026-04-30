import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String taskId;
  final String authorId;
  String body;
  final DateTime createdAt;
  DateTime? editedAt;

  Comment({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.body,
    DateTime? createdAt,
    this.editedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'authorId': authorId,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'editedAt': editedAt?.toIso8601String(),
      };

  factory Comment.fromFirestore(DocumentSnapshot doc, String taskId) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      taskId: taskId,
      authorId: data['authorId'] as String? ?? '',
      body: data['body'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : null,
      editedAt: data['editedAt'] != null
          ? DateTime.parse(data['editedAt'] as String)
          : null,
    );
  }
}
