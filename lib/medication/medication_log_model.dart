class MedicationLog {
  final String id;
  final String medicationId;
  final String petId;
  final DateTime scheduledDate;
  final String status;
  final DateTime? takenAt;
  final String? note;

  const MedicationLog({
    required this.id,
    required this.medicationId,
    required this.petId,
    required this.scheduledDate,
    required this.status,
    this.takenAt,
    this.note,
  });

  bool get isTaken => status == 'taken';
  bool get isMissed => status == 'missed';

  Map<String, dynamic> toMap() => {
        'id': id,
        'medicationId': medicationId,
        'petId': petId,
        'scheduledDate': scheduledDate.toIso8601String(),
        'status': status,
        'takenAt': takenAt?.toIso8601String(),
        'note': note,
      };

  factory MedicationLog.fromMap(Map<String, dynamic> map) => MedicationLog(
        id: map['id'] as String,
        medicationId: map['medicationId'] as String,
        petId: map['petId'] as String,
        scheduledDate: DateTime.parse(map['scheduledDate'] as String),
        status: map['status'] as String,
        takenAt: map['takenAt'] != null
            ? DateTime.parse(map['takenAt'] as String)
            : null,
        note: map['note'] as String?,
      );
}
