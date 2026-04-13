class Vaccine {
  final String id;
  final String petId;
  final String name;
  final DateTime administeredDate;
  final DateTime? nextDueDate;
  final String? notes;
  final String? vetName;
  final String? reminderTime;
  final bool reminderEnabled;
  final int reminderDaysBefore;

  Vaccine({
    required this.id,
    required this.petId,
    required this.name,
    required this.administeredDate,
    this.nextDueDate,
    this.notes,
    this.vetName,
    this.reminderTime,
    this.reminderEnabled = false,
    this.reminderDaysBefore = 3,
  });

  bool get hasNextDose => nextDueDate != null;

  bool get isUpcoming =>
      nextDueDate != null &&
      !isOverdue &&
      daysUntilDue != null &&
      daysUntilDue! <= 7;

  bool get isOverdue =>
      nextDueDate != null && _startOfDay(nextDueDate!).isBefore(_today);

  int? get daysUntilDue =>
      nextDueDate == null ? null : _startOfDay(nextDueDate!).difference(_today).inDays;

  bool get isDueToday => daysUntilDue == 0;

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Map<String, dynamic> toMap() => {
        'id': id,
        'petId': petId,
        'name': name,
        'administeredDate': administeredDate.toIso8601String(),
        'nextDueDate': nextDueDate?.toIso8601String(),
        'notes': notes,
        'vetName': vetName,
        'reminderTime': reminderTime,
        'reminderEnabled': reminderEnabled ? 1 : 0,
        'reminderDaysBefore': reminderDaysBefore,
      };

  factory Vaccine.fromMap(Map<String, dynamic> map) => Vaccine(
        id: map['id'] as String,
        petId: map['petId'] as String,
        name: map['name'] as String,
        administeredDate: DateTime.parse(map['administeredDate'] as String),
        nextDueDate: map['nextDueDate'] != null
            ? DateTime.parse(map['nextDueDate'] as String)
            : null,
        notes: map['notes'] as String?,
        vetName: map['vetName'] as String?,
        reminderTime: map['reminderTime'] as String?,
        reminderEnabled: (map['reminderEnabled'] as int? ?? 0) == 1,
        reminderDaysBefore: map['reminderDaysBefore'] as int? ?? 3,
      );

  Vaccine copyWith({
    String? id,
    String? petId,
    String? name,
    DateTime? administeredDate,
    DateTime? nextDueDate,
    String? notes,
    String? vetName,
    String? reminderTime,
    bool? reminderEnabled,
    int? reminderDaysBefore,
  }) =>
      Vaccine(
        id: id ?? this.id,
        petId: petId ?? this.petId,
        name: name ?? this.name,
        administeredDate: administeredDate ?? this.administeredDate,
        nextDueDate: nextDueDate ?? this.nextDueDate,
        notes: notes ?? this.notes,
        vetName: vetName ?? this.vetName,
        reminderTime: reminderTime ?? this.reminderTime,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      );
}
