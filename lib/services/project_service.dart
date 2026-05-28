import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _ref => _firestore.collection('projects');

  Stream<List<Project>> streamProjects(String userId) {
    return _ref
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Project.fromFirestore(doc)).toList());
  }

  Future<List<Project>> getProjects(String userId) async {
    final snap = await _ref
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((doc) => Project.fromFirestore(doc)).toList();
  }

  Future<void> addProject(Project project) async {
    await _ref.doc(project.id).set(project.toJson());
  }

  Future<void> updateProject(Project project) async {
    await _ref.doc(project.id).update(project.toJson());
  }

  Future<void> deleteProject(String projectId) async {
    await _ref.doc(projectId).delete();
  }
}
