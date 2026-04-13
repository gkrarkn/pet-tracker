class WeightRecord {
  final String id;
  final String petId;
  final double weightKg;
  final DateTime recordedAt;
  final String? notes;

  WeightRecord({
    required this.id,
    required this.petId,
    required this.weightKg,
    required this.recordedAt,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'petId': petId,
        'weightKg': weightKg,
        'recordedAt': recordedAt.toIso8601String(),
        'notes': notes,
      };

  factory WeightRecord.fromMap(Map<String, dynamic> map) => WeightRecord(
        id: map['id'] as String,
        petId: map['petId'] as String,
        weightKg: (map['weightKg'] as num).toDouble(),
        recordedAt: DateTime.parse(map['recordedAt'] as String),
        notes: map['notes'] as String?,
      );
}
