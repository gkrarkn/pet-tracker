class CareTask {
  final String id;
  final String petId;
  final String type;
  final String title;
  final String frequency;
  final String? notes;
  final bool reminderEnabled;
  final String? reminderTime;
  final bool isActive;
  final DateTime startDate;
  final DateTime? lastCompletedAt;
  final DateTime? skippedUntil;

  const CareTask({
    required this.id,
    required this.petId,
    required this.type,
    required this.title,
    required this.frequency,
    this.notes,
    required this.reminderEnabled,
    this.reminderTime,
    required this.isActive,
    required this.startDate,
    this.lastCompletedAt,
    this.skippedUntil,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'petId': petId,
        'type': type,
        'title': title,
        'frequency': frequency,
        'notes': notes,
        'reminderEnabled': reminderEnabled ? 1 : 0,
        'reminderTime': reminderTime,
        'isActive': isActive ? 1 : 0,
        'startDate': startDate.toIso8601String(),
        'lastCompletedAt': lastCompletedAt?.toIso8601String(),
        'skippedUntil': skippedUntil?.toIso8601String(),
      };

  factory CareTask.fromMap(Map<String, dynamic> map) => CareTask(
        id: map['id'] as String,
        petId: map['petId'] as String,
        type: map['type'] as String,
        title: map['title'] as String,
        frequency: map['frequency'] as String,
        notes: map['notes'] as String?,
        reminderEnabled: (map['reminderEnabled'] as int? ?? 0) == 1,
        reminderTime: map['reminderTime'] as String?,
        isActive: (map['isActive'] as int? ?? 1) == 1,
        startDate: DateTime.parse(map['startDate'] as String),
        lastCompletedAt: map['lastCompletedAt'] != null
            ? DateTime.parse(map['lastCompletedAt'] as String)
            : null,
        skippedUntil: map['skippedUntil'] != null
            ? DateTime.parse(map['skippedUntil'] as String)
            : null,
      );

  CareTask copyWith({
    String? id,
    String? petId,
    String? type,
    String? title,
    String? frequency,
    String? notes,
    bool? reminderEnabled,
    String? reminderTime,
    bool? isActive,
    DateTime? startDate,
    DateTime? lastCompletedAt,
    DateTime? skippedUntil,
  }) =>
      CareTask(
        id: id ?? this.id,
        petId: petId ?? this.petId,
        type: type ?? this.type,
        title: title ?? this.title,
        frequency: frequency ?? this.frequency,
        notes: notes ?? this.notes,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderTime: reminderTime ?? this.reminderTime,
        isActive: isActive ?? this.isActive,
        startDate: startDate ?? this.startDate,
        lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
        skippedUntil: skippedUntil ?? this.skippedUntil,
      );
}
