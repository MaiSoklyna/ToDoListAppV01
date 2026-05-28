import 'dart:async';

import 'package:flutter/material.dart';

import '../models/shared_list.dart';
import '../services/shared_list_service.dart';

class SharedListViewModel extends ChangeNotifier {
  final SharedListService _service = SharedListService();

  List<SharedList> _lists = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _sub;
  String? _currentUserId;

  List<SharedList> get lists => _lists;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// IDs the current user is a member of — used by TaskViewModel to subscribe.
  List<String> get memberListIds => _lists.map((l) => l.id).toList();

  SharedList? getById(String id) {
    for (final l in _lists) {
      if (l.id == id) return l;
    }
    return null;
  }

  void listen(String userId) {
    _currentUserId = userId;
    _sub?.cancel();
    _isLoading = true;
    notifyListeners();

    _sub = _service.streamForUser(userId).listen(
      (lists) {
        _lists = lists;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load shared lists.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<SharedList?> create(String name) async {
    final uid = _currentUserId;
    if (uid == null) return null;
    try {
      return await _service.create(name: name.trim(), ownerId: uid);
    } catch (e) {
      _error = 'Failed to create list.';
      notifyListeners();
      return null;
    }
  }

  Future<void> rename(String listId, String name) async {
    try {
      await _service.rename(listId, name.trim());
    } catch (e) {
      _error = 'Failed to rename list.';
      notifyListeners();
    }
  }

  Future<void> delete(SharedList list) async {
    try {
      await _service.delete(list);
    } catch (e) {
      _error = 'Failed to delete list.';
      notifyListeners();
    }
  }

  Future<void> leave(SharedList list) async {
    final uid = _currentUserId;
    if (uid == null) return;
    try {
      await _service.removeMember(listId: list.id, userId: uid);
    } catch (e) {
      _error = 'Failed to leave list.';
      notifyListeners();
    }
  }

  Future<String?> regenerateInviteCode(SharedList list) async {
    try {
      return await _service.regenerateInviteCode(list);
    } catch (e) {
      _error = 'Failed to regenerate code.';
      notifyListeners();
      return null;
    }
  }

  /// Returns the joined list, or null if the code did not match anything.
  Future<SharedList?> joinByCode(String code) async {
    final uid = _currentUserId;
    if (uid == null) return null;
    try {
      return await _service.joinByInviteCode(code: code.trim(), userId: uid);
    } catch (e) {
      _error = 'Failed to join list.';
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void reset() {
    _sub?.cancel();
    _sub = null;
    _lists = [];
    _isLoading = false;
    _error = null;
    _currentUserId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
