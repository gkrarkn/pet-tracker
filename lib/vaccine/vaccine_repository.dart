import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import 'vaccine_model.dart';

class VaccineRepository {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<List<Vaccine>> getByPetId(String petId) async {
    final db = await _db;
    final rows = await db.query(
      'vaccines',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'administeredDate DESC',
    );
    return rows.map(Vaccine.fromMap).toList();
  }

  Future<List<Vaccine>> getUpcoming() async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final rows = await db.query(
      'vaccines',
      where: 'nextDueDate IS NOT NULL AND nextDueDate >= ?',
      whereArgs: [now],
      orderBy: 'nextDueDate ASC',
    );
    return rows.map(Vaccine.fromMap).toList();
  }

  Future<List<Vaccine>> getUpcomingForPet(
    String petId, {
    int withinDays = 30,
  }) async {
    final db = await _db;
    final until = DateTime.now().add(Duration(days: withinDays)).toIso8601String();
    final rows = await db.query(
      'vaccines',
      where: 'petId = ? AND nextDueDate IS NOT NULL AND nextDueDate <= ?',
      whereArgs: [petId, until],
      orderBy: 'nextDueDate ASC',
    );
    return rows.map(Vaccine.fromMap).toList();
  }

  Future<void> add(Vaccine vaccine) async {
    final db = await _db;
    await db.insert('vaccines', vaccine.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(Vaccine vaccine) async {
    final db = await _db;
    await db.update('vaccines', vaccine.toMap(),
        where: 'id = ?', whereArgs: [vaccine.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('vaccines', where: 'id = ?', whereArgs: [id]);
  }
}
