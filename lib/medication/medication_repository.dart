import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../db/database_helper.dart';
import 'medication_model.dart';
import 'medication_log_model.dart';

class MedicationRepository {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<List<Medication>> getByPetId(String petId) async {
    final db = await _db;
    final rows = await db.query(
      'medications',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'isActive DESC, startDate DESC',
    );
    return rows.map(Medication.fromMap).toList();
  }

  Future<List<Medication>> getActive(String petId) async {
    final db = await _db;
    final rows = await db.query(
      'medications',
      where: 'petId = ? AND isActive = 1',
      whereArgs: [petId],
      orderBy: 'startDate DESC',
    );
    return rows.map(Medication.fromMap).toList();
  }

  Future<Medication?> getById(String id) async {
    final db = await _db;
    final rows = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Medication.fromMap(rows.first);
  }

  Future<List<Medication>> getAllActive() async {
    final db = await _db;
    final rows = await db.query(
      'medications',
      where: 'isActive = 1',
      orderBy: 'startDate DESC',
    );
    return rows.map(Medication.fromMap).toList();
  }

  Future<void> add(Medication med) async {
    final db = await _db;
    await db.insert('medications', med.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(Medication med) async {
    final db = await _db;
    await db.update('medications', med.toMap(),
        where: 'id = ?', whereArgs: [med.id]);
  }

  Future<void> setActive(String id, bool active) async {
    final db = await _db;
    await db.update('medications', {'isActive': active ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  Future<MedicationLog?> getLogForDate({
    required String medicationId,
    required DateTime scheduledDate,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'medication_logs',
      where: 'medicationId = ? AND scheduledDate = ?',
      whereArgs: [medicationId, _dateKey(scheduledDate)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return MedicationLog.fromMap(rows.first);
  }

  Future<List<MedicationLog>> getLogsByMedication(String medicationId) async {
    final db = await _db;
    final rows = await db.query(
      'medication_logs',
      where: 'medicationId = ?',
      whereArgs: [medicationId],
      orderBy: 'scheduledDate DESC',
    );
    return rows.map(MedicationLog.fromMap).toList();
  }

  Future<void> markMedicationStatus({
    required Medication medication,
    required DateTime scheduledDate,
    required bool taken,
    String? note,
  }) async {
    final db = await _db;
    final existing = await getLogForDate(
      medicationId: medication.id,
      scheduledDate: scheduledDate,
    );
    final log = MedicationLog(
      id: existing?.id ?? const Uuid().v4(),
      medicationId: medication.id,
      petId: medication.petId,
      scheduledDate: DateTime.parse(_dateKey(scheduledDate)),
      status: taken ? 'taken' : 'missed',
      takenAt: taken ? DateTime.now() : null,
      note: note,
    );
    await db.insert(
      'medication_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String();
  }
}
