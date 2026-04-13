class Medication {
  final String id;
  final String petId;
  final String name;
  final String dosage;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final bool isActive;
  final String? reminderTime;
  final bool reminderEnabled;

  Medication({
    required this.id,
    required this.petId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.notes,
    required this.isActive,
    this.reminderTime,
    this.reminderEnabled = false,
  });

  bool get isOngoing => endDate == null || endDate!.isAfter(DateTime.now());

  int? get daysRemaining =>
      endDate?.difference(DateTime.now()).inDays;

  bool get isScheduledToday {
    final today = _today;
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = endDate == null
        ? null
        : DateTime(endDate!.year, endDate!.month, endDate!.day);
    return isActive &&
        !today.isBefore(start) &&
        (end == null || !today.isAfter(end));
  }

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'petId': petId,
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'notes': notes,
        'isActive': isActive ? 1 : 0,
        'reminderTime': reminderTime,
        'reminderEnabled': reminderEnabled ? 1 : 0,
      };

  factory Medication.fromMap(Map<String, dynamic> map) => Medication(
        id: map['id'] as String,
        petId: map['petId'] as String,
        name: map['name'] as String,
        dosage: map['dosage'] as String,
        frequency: map['frequency'] as String,
        startDate: DateTime.parse(map['startDate'] as String),
        endDate: map['endDate'] != null
            ? DateTime.parse(map['endDate'] as String)
            : null,
        notes: map['notes'] as String?,
        isActive: (map['isActive'] as int) == 1,
        reminderTime: map['reminderTime'] as String?,
        reminderEnabled: (map['reminderEnabled'] as int? ?? 0) == 1,
      );

  Medication copyWith({
    String? name,
    String? dosage,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    bool? isActive,
    String? reminderTime,
    bool? reminderEnabled,
  }) =>
      Medication(
        id: id,
        petId: petId,
        name: name ?? this.name,
        dosage: dosage ?? this.dosage,
        frequency: frequency ?? this.frequency,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        notes: notes ?? this.notes,
        isActive: isActive ?? this.isActive,
        reminderTime: reminderTime ?? this.reminderTime,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      );
}
