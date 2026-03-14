import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'recurrence.dart';

class Task {
  final String id;
  String title;
  String description;
  DateTime? dueDate;
  String category;
  int priority; // 1 = Low, 2 = Medium, 3 = High
  bool isCompleted;
  List<SubTask> subTasks;
  bool isRecurring;
  DateTime createdAt;
  DateTime? completedAt;
  String? userId;
  int? colorValue;

  // Production fields
  String? projectId;
  List<String> labelIds;
  RecurrenceRule? recurrenceRule;
  List<String> attachments;
  String? sharedListId;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.category = 'General',
    this.priority = 2,
    this.isCompleted = false,
    this.subTasks = const [],
    this.isRecurring = false,
    this.userId,
    this.colorValue,
    this.projectId,
    this.labelIds = const [],
    this.recurrenceRule,
    this.attachments = const [],
    this.sharedListId,
    this.completedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Color? get taskColor => colorValue != null ? Color(colorValue!) : null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'category': category,
      'priority': priority,
      'isCompleted': isCompleted,
      'subTasks': subTasks.map((s) => s.toJson()).toList(),
      'isRecurring': isRecurring,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'userId': userId,
      'colorValue': colorValue,
      'projectId': projectId,
      'labelIds': labelIds,
      'recurrenceRule': recurrenceRule?.toJson(),
      'attachments': attachments,
      'sharedListId': sharedListId,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      category: json['category'] as String? ?? 'General',
      priority: json['priority'] as int? ?? 2,
      isCompleted: json['isCompleted'] as bool? ?? false,
      subTasks: (json['subTasks'] as List<dynamic>?)
              ?.map((s) => SubTask.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      isRecurring: json['isRecurring'] as bool? ?? false,
      userId: json['userId'] as String?,
      colorValue: json['colorValue'] as int?,
      projectId: json['projectId'] as String?,
      labelIds: (json['labelIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      recurrenceRule: json['recurrenceRule'] != null
          ? RecurrenceRule.fromJson(
              json['recurrenceRule'] as Map<String, dynamic>)
          : null,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      sharedListId: json['sharedListId'] as String?,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return Task.fromJson(data);
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? category,
    int? priority,
    bool? isCompleted,
    List<SubTask>? subTasks,
    bool? isRecurring,
    String? userId,
    int? colorValue,
    bool clearColor = false,
    DateTime? createdAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    String? projectId,
    bool clearProject = false,
    List<String>? labelIds,
    RecurrenceRule? recurrenceRule,
    bool clearRecurrence = false,
    List<String>? attachments,
    String? sharedListId,
    bool clearSharedList = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      subTasks: subTasks ?? this.subTasks,
      isRecurring: isRecurring ?? this.isRecurring,
      userId: userId ?? this.userId,
      colorValue: clearColor ? null : (colorValue ?? this.colorValue),
      createdAt: createdAt ?? this.createdAt,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
      projectId: clearProject ? null : (projectId ?? this.projectId),
      labelIds: labelIds ?? this.labelIds,
      recurrenceRule:
          clearRecurrence ? null : (recurrenceRule ?? this.recurrenceRule),
      attachments: attachments ?? this.attachments,
      sharedListId:
          clearSharedList ? null : (sharedListId ?? this.sharedListId),
    );
  }
}

class SubTask {
  final String id;
  String title;
  bool isCompleted;

  SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
