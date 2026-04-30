import 'dart:async';
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/note_service.dart';

class NoteViewModel extends ChangeNotifier {
  final NoteService _service = NoteService();

  List<Note> _notes = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Note? getById(String id) {
    try {
      return _notes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  void listenToNotes(String userId) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = _service.streamNotes(userId).listen(
      (notes) {
        _notes = notes;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load notes.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> loadNotes(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _notes = await _service.getNotes(userId);
    } catch (e) {
      _error = 'Failed to load notes.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNote(Note note) async {
    _notes.insert(0, note);
    _resort();
    notifyListeners();
    try {
      await _service.addNote(note);
    } catch (e) {
      _notes.removeWhere((n) => n.id == note.id);
      _error = 'Failed to add note.';
      notifyListeners();
    }
  }

  Future<void> updateNote(Note note) async {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx == -1) return;
    final old = _notes[idx];
    _notes[idx] = note;
    _resort();
    notifyListeners();
    try {
      await _service.updateNote(note);
    } catch (e) {
      _notes[idx] = old;
      _resort();
      _error = 'Failed to update note.';
      notifyListeners();
    }
  }

  Future<void> togglePin(String noteId) async {
    final note = getById(noteId);
    if (note == null) return;
    await updateNote(note.copyWith(pinned: !note.pinned));
  }

  Future<void> deleteNote(String noteId) async {
    final idx = _notes.indexWhere((n) => n.id == noteId);
    if (idx == -1) return;
    final removed = _notes[idx];
    _notes.removeAt(idx);
    notifyListeners();
    try {
      await _service.deleteNote(noteId);
    } catch (e) {
      _notes.insert(idx, removed);
      _resort();
      _error = 'Failed to delete note.';
      notifyListeners();
    }
  }

  void _resort() {
    _notes.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  void reset() {
    _subscription?.cancel();
    _subscription = null;
    _notes = [];
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
