import 'dart:async';
import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/project_service.dart';

class ProjectViewModel extends ChangeNotifier {
  final ProjectService _service = ProjectService();

  List<Project> _projects = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Project? getById(String id) {
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void listenToProjects(String userId) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = _service.streamProjects(userId).listen(
      (projects) {
        _projects = projects;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load projects.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> loadProjects(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _projects = await _service.getProjects(userId);
    } catch (e) {
      _error = 'Failed to load projects.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProject(Project project) async {
    _projects.insert(0, project);
    notifyListeners();
    try {
      await _service.addProject(project);
    } catch (e) {
      _projects.removeWhere((p) => p.id == project.id);
      _error = 'Failed to add project.';
      notifyListeners();
    }
  }

  Future<void> updateProject(Project project) async {
    final idx = _projects.indexWhere((p) => p.id == project.id);
    if (idx == -1) return;
    final old = _projects[idx];
    _projects[idx] = project;
    notifyListeners();
    try {
      await _service.updateProject(project);
    } catch (e) {
      _projects[idx] = old;
      _error = 'Failed to update project.';
      notifyListeners();
    }
  }

  Future<void> deleteProject(String projectId) async {
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx == -1) return;
    final removed = _projects[idx];
    _projects.removeAt(idx);
    notifyListeners();
    try {
      await _service.deleteProject(projectId);
    } catch (e) {
      _projects.insert(idx, removed);
      _error = 'Failed to delete project.';
      notifyListeners();
    }
  }

  void reset() {
    _subscription?.cancel();
    _subscription = null;
    _projects = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
