import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note.dart';

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _ref => _firestore.collection('notes');

  /// Live stream of the user's notes — pinned notes first, then by most
  /// recently updated. Sort happens client-side so we don't need a composite
  /// Firestore index.
  Stream<List<Note>> streamNotes(String userId) {
    return _ref
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => _sort(snap.docs.map(Note.fromFirestore).toList()));
  }

  Future<List<Note>> getNotes(String userId) async {
    final snap = await _ref.where('userId', isEqualTo: userId).get();
    return _sort(snap.docs.map(Note.fromFirestore).toList());
  }

  Future<void> addNote(Note note) => _ref.doc(note.id).set(note.toJson());

  Future<void> updateNote(Note note) =>
      _ref.doc(note.id).update(note.toJson());

  Future<void> deleteNote(String noteId) => _ref.doc(noteId).delete();

  List<Note> _sort(List<Note> notes) {
    notes.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return notes;
  }
}
