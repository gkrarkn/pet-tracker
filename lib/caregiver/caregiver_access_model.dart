class CaregiverAccess {
  final String id;
  final String petId;
  final String name;
  final String role;
  final String inviteCode;
  final String status;
  final String? lastAction;
  final DateTime? lastActiveAt;

  const CaregiverAccess({
    required this.id,
    required this.petId,
    required this.name,
    required this.role,
    required this.inviteCode,
    this.status = 'active',
    this.lastAction,
    this.lastActiveAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'petId': petId,
        'name': name,
        'role': role,
        'inviteCode': inviteCode,
        'status': status,
        'lastAction': lastAction,
        'lastActiveAt': lastActiveAt?.toIso8601String(),
      };

  factory CaregiverAccess.fromMap(Map<String, dynamic> map) => CaregiverAccess(
        id: map['id'] as String,
        petId: map['petId'] as String,
        name: map['name'] as String,
        role: map['role'] as String,
        inviteCode: map['inviteCode'] as String,
        status: map['status'] as String? ?? 'active',
        lastAction: map['lastAction'] as String?,
        lastActiveAt: map['lastActiveAt'] == null
            ? null
            : DateTime.parse(map['lastActiveAt'] as String),
      );

  CaregiverAccess copyWith({
    String? id,
    String? petId,
    String? name,
    String? role,
    String? inviteCode,
    String? status,
    String? lastAction,
    DateTime? lastActiveAt,
  }) {
    return CaregiverAccess(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      name: name ?? this.name,
      role: role ?? this.role,
      inviteCode: inviteCode ?? this.inviteCode,
      status: status ?? this.status,
      lastAction: lastAction ?? this.lastAction,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}
