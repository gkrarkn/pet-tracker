class VetVisit {
  final String id;
  final String petId;
  final DateTime visitDate;
  final String category;
  final String reason;
  final String? notes;
  final String? vetName;
  final String? clinicAddress;
  final String? clinicPhone;
  final String? reminderTime;
  final bool reminderEnabled;
  final int reminderDaysBefore;

  VetVisit({
    required this.id,
    required this.petId,
    required this.visitDate,
    required this.category,
    required this.reason,
    this.notes,
    this.vetName,
    this.clinicAddress,
    this.clinicPhone,
    this.reminderTime,
    this.reminderEnabled = false,
    this.reminderDaysBefore = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'visitDate': visitDate.toIso8601String(),
      'category': category,
      'reason': reason,
      'notes': notes,
      'vetName': vetName,
      'clinicAddress': clinicAddress,
      'clinicPhone': clinicPhone,
      'reminderTime': reminderTime,
      'reminderEnabled': reminderEnabled ? 1 : 0,
      'reminderDaysBefore': reminderDaysBefore,
    };
  }

  factory VetVisit.fromMap(Map<String, dynamic> map) {
    return VetVisit(
      id: map['id'] as String,
      petId: map['petId'] as String,
      visitDate: DateTime.parse(map['visitDate'] as String),
      category: map['category'] as String? ?? 'kontrol',
      reason: map['reason'] as String,
      notes: map['notes'] as String?,
      vetName: map['vetName'] as String?,
      clinicAddress: map['clinicAddress'] as String?,
      clinicPhone: map['clinicPhone'] as String?,
      reminderTime: map['reminderTime'] as String?,
      reminderEnabled: (map['reminderEnabled'] as int? ?? 0) == 1,
      reminderDaysBefore: map['reminderDaysBefore'] as int? ?? 1,
    );
  }

  VetVisit copyWith({
    String? id,
    String? petId,
    DateTime? visitDate,
    String? category,
    String? reason,
    String? notes,
    String? vetName,
    String? clinicAddress,
    String? clinicPhone,
    String? reminderTime,
    bool? reminderEnabled,
    int? reminderDaysBefore,
  }) {
    return VetVisit(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      visitDate: visitDate ?? this.visitDate,
      category: category ?? this.category,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      vetName: vetName ?? this.vetName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      clinicPhone: clinicPhone ?? this.clinicPhone,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
    );
  }
}
