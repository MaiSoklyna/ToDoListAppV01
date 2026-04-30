import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/invite.dart';
import '../models/shared_list.dart';

class SharedListService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _ref => _firestore.collection('sharedLists');
  CollectionReference get _invitesRef => _firestore.collection('invites');

  Stream<List<SharedList>> streamForUser(String userId) {
    return _ref
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snap) {
      final lists =
          snap.docs.map((doc) => SharedList.fromFirestore(doc)).toList();
      lists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return lists;
    });
  }

  Future<List<SharedList>> getForUser(String userId) async {
    final snap = await _ref.where('memberIds', arrayContains: userId).get();
    final lists =
        snap.docs.map((doc) => SharedList.fromFirestore(doc)).toList();
    lists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return lists;
  }

  Future<SharedList> create({
    required String name,
    required String ownerId,
  }) async {
    final doc = _ref.doc();
    final code = _generateInviteCode();
    final list = SharedList(
      id: doc.id,
      name: name,
      ownerId: ownerId,
      inviteCode: code,
    );

    final batch = _firestore.batch();
    batch.set(doc, list.toJson());
    batch.set(_invitesRef.doc(code), Invite(
      code: code,
      listId: list.id,
      ownerId: ownerId,
    ).toJson());
    await batch.commit();

    return list;
  }

  Future<void> rename(String listId, String name) async {
    await _ref.doc(listId).update({'name': name});
  }

  Future<void> delete(SharedList list) async {
    final batch = _firestore.batch();
    batch.delete(_ref.doc(list.id));
    if (list.inviteCode != null) {
      batch.delete(_invitesRef.doc(list.inviteCode));
    }
    await batch.commit();
  }

  Future<String> regenerateInviteCode(SharedList list) async {
    final newCode = _generateInviteCode();
    final batch = _firestore.batch();
    if (list.inviteCode != null) {
      batch.delete(_invitesRef.doc(list.inviteCode));
    }
    batch.set(_invitesRef.doc(newCode), Invite(
      code: newCode,
      listId: list.id,
      ownerId: list.ownerId,
    ).toJson());
    batch.update(_ref.doc(list.id), {'inviteCode': newCode});
    await batch.commit();
    return newCode;
  }

  Future<void> revokeInviteCode(SharedList list) async {
    if (list.inviteCode == null) return;
    final batch = _firestore.batch();
    batch.delete(_invitesRef.doc(list.inviteCode));
    batch.update(_ref.doc(list.id), {'inviteCode': null});
    await batch.commit();
  }

  /// Resolve a share code to its target list id. Returns null if not found.
  Future<String?> resolveInviteCode(String code) async {
    final snap = await _invitesRef.doc(code.toUpperCase()).get();
    if (!snap.exists) return null;
    final data = snap.data() as Map<String, dynamic>;
    return data['listId'] as String?;
  }

  /// Join a shared list using a share code. Returns the joined list, or null
  /// if the code is invalid.
  Future<SharedList?> joinByInviteCode({
    required String code,
    required String userId,
  }) async {
    final listId = await resolveInviteCode(code);
    if (listId == null) return null;

    await _ref.doc(listId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
      'roles.$userId': SharedListRole.editor.value,
    });

    final snap = await _ref.doc(listId).get();
    if (!snap.exists) return null;
    return SharedList.fromFirestore(snap);
  }

  Future<void> setRole({
    required String listId,
    required String userId,
    required SharedListRole role,
  }) async {
    await _ref.doc(listId).update({'roles.$userId': role.value});
  }

  Future<void> removeMember({
    required String listId,
    required String userId,
  }) async {
    await _ref.doc(listId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'roles.$userId': FieldValue.delete(),
    });
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
