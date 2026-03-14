import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _tasksRef => _firestore.collection('tasks');

  /// Real-time stream of user's tasks
  Stream<List<Task>> streamTasks(String userId) {
    return _tasksRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final tasks =
          snap.docs.map((doc) => Task.fromFirestore(doc)).toList();
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    });
  }

  Future<List<Task>> getTasks(String userId) async {
    final snapshot = await _tasksRef
        .where('userId', isEqualTo: userId)
        .get();
    final tasks =
        snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  Future<void> addTask(Task task) async {
    await _tasksRef.doc(task.id).set(task.toJson());
  }

  Future<void> updateTask(Task task) async {
    await _tasksRef.doc(task.id).update(task.toJson());
  }

  Future<void> deleteTask(String taskId) async {
    await _tasksRef.doc(taskId).delete();
  }

  Future<List<Task>> getTasksByDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _tasksRef
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((doc) => Task.fromFirestore(doc))
        .where((task) {
      if (task.dueDate == null) return false;
      return !task.dueDate!.isBefore(startOfDay) &&
          task.dueDate!.isBefore(endOfDay);
    }).toList();
  }

  Future<void> toggleComplete(String taskId, bool isCompleted) async {
    await _tasksRef.doc(taskId).update({'isCompleted': isCompleted});
  }

  /// Get tasks by project
  Future<List<Task>> getTasksByProject(
      String userId, String projectId) async {
    final snapshot = await _tasksRef
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((doc) => Task.fromFirestore(doc))
        .where((task) => task.projectId == projectId)
        .toList();
  }
}
