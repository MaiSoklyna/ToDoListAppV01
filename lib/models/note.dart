import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  String title;
  String body;
  int colorValue;
  bool pinned;
  String? userId;
  DateTime createdAt;
  DateTime updatedAt;

  Note({
    required this.id,
    this.title = '',
    this.body = '',
    this.colorValue = 0xFFFFF59D, // Soft yellow default
    this.pinned = false,
    this.userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'colorValue': colorValue,
        'pinned': pinned,
        'userId': userId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        colorValue: json['colorValue'] as int? ?? 0xFFFFF59D,
        pinned: json['pinned'] as bool? ?? false,
        userId: json['userId'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );

  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return Note.fromJson(data);
  }

  Note copyWith({
    String? title,
    String? body,
    int? colorValue,
    bool? pinned,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      colorValue: colorValue ?? this.colorValue,
      pinned: pinned ?? this.pinned,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  static const List<int> presetColors = [
    0xFFFFF59D, // Yellow
    0xFFFFCC80, // Orange
    0xFFEF9A9A, // Red
    0xFFCE93D8, // Purple
    0xFF90CAF9, // Blue
    0xFF80DEEA, // Cyan
    0xFFA5D6A7, // Green
    0xFFE0E0E0, // Grey
  ];
}
