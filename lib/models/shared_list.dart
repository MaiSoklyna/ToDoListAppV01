import 'package:cloud_firestore/cloud_firestore.dart';

enum SharedListRole { owner, editor, viewer }

extension SharedListRoleX on SharedListRole {
  String get value => name;

  static SharedListRole fromString(String? raw) {
    switch (raw) {
      case 'owner':
        return SharedListRole.owner;
      case 'viewer':
        return SharedListRole.viewer;
      case 'editor':
      default:
        return SharedListRole.editor;
    }
  }
}

class SharedList {
  final String id;
  String name;
  final String ownerId;
  List<String> memberIds;
  Map<String, SharedListRole> roles;
  String? inviteCode;
  DateTime createdAt;

  SharedList({
    required this.id,
    required this.name,
    required this.ownerId,
    List<String>? memberIds,
    Map<String, SharedListRole>? roles,
    this.inviteCode,
    DateTime? createdAt,
  })  : memberIds = memberIds ?? [ownerId],
        roles = roles ?? {ownerId: SharedListRole.owner},
        createdAt = createdAt ?? DateTime.now();

  bool isMember(String userId) => memberIds.contains(userId);

  SharedListRole roleOf(String userId) =>
      roles[userId] ?? SharedListRole.viewer;

  bool canEdit(String userId) {
    final role = roleOf(userId);
    return role == SharedListRole.owner || role == SharedListRole.editor;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ownerId': ownerId,
        'memberIds': memberIds,
        'roles': roles.map((k, v) => MapEntry(k, v.value)),
        'inviteCode': inviteCode,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SharedList.fromJson(Map<String, dynamic> json) {
    final rawRoles = (json['roles'] as Map<String, dynamic>?) ?? {};
    return SharedList(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['ownerId'] as String,
      memberIds: (json['memberIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      roles: rawRoles.map(
        (k, v) => MapEntry(k, SharedListRoleX.fromString(v as String?)),
      ),
      inviteCode: json['inviteCode'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  factory SharedList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return SharedList.fromJson(data);
  }

  SharedList copyWith({
    String? name,
    List<String>? memberIds,
    Map<String, SharedListRole>? roles,
    String? inviteCode,
    bool clearInviteCode = false,
  }) {
    return SharedList(
      id: id,
      name: name ?? this.name,
      ownerId: ownerId,
      memberIds: memberIds ?? this.memberIds,
      roles: roles ?? this.roles,
      inviteCode: clearInviteCode ? null : (inviteCode ?? this.inviteCode),
      createdAt: createdAt,
    );
  }
}
