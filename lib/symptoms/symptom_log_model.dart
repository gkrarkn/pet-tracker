class SymptomLog {
  final String id;
  final String petId;
  final String symptom;
  final String severity;
  final String? note;
  final DateTime observedAt;

  const SymptomLog({
    required this.id,
    required this.petId,
    required this.symptom,
    required this.severity,
    this.note,
    required this.observedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'petId': petId,
        'symptom': symptom,
        'severity': severity,
        'note': note,
        'observedAt': observedAt.toIso8601String(),
      };

  factory SymptomLog.fromMap(Map<String, dynamic> map) => SymptomLog(
        id: map['id'] as String,
        petId: map['petId'] as String,
        symptom: map['symptom'] as String,
        severity: map['severity'] as String? ?? 'orta',
        note: map['note'] as String?,
        observedAt: DateTime.parse(map['observedAt'] as String),
      );
}
