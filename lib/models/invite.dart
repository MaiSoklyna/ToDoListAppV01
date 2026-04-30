import 'package:cloud_firestore/cloud_firestore.dart';

/// Public lookup record so non-members can resolve a share code to a list.
/// Doc id is the invite code itself.
class Invite {
  final String code;
  final String listId;
  final String ownerId;
  final DateTime createdAt;

  Invite({
    required this.code,
    required this.listId,
    required this.ownerId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'code': code,
        'listId': listId,
        'ownerId': ownerId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Invite.fromJson(Map<String, dynamic> json) => Invite(
        code: json['code'] as String,
        listId: json['listId'] as String,
        ownerId: json['ownerId'] as String,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );

  factory Invite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['code'] = doc.id;
    return Invite.fromJson(data);
  }
}
