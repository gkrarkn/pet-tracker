import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import 'caregiver_access_model.dart';

class CaregiverRepository {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<List<CaregiverAccess>> getByPetId(String petId) async {
    final db = await _db;
    final rows = await db.query(
      'caregiver_access',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'lastActiveAt DESC',
    );
    return rows.map(CaregiverAccess.fromMap).toList();
  }

  Future<void> add(CaregiverAccess caregiver) async {
    final db = await _db;
    await db.insert(
      'caregiver_access',
      caregiver.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(CaregiverAccess caregiver) async {
    final db = await _db;
    await db.update(
      'caregiver_access',
      caregiver.toMap(),
      where: 'id = ?',
      whereArgs: [caregiver.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('caregiver_access', where: 'id = ?', whereArgs: [id]);
  }
}
