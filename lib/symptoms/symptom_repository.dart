import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import 'symptom_log_model.dart';

class SymptomRepository {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<List<SymptomLog>> getByPetId(String petId) async {
    final db = await _db;
    final rows = await db.query(
      'symptom_logs',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'observedAt DESC',
    );
    return rows.map(SymptomLog.fromMap).toList();
  }

  Future<void> add(SymptomLog log) async {
    final db = await _db;
    await db.insert(
      'symptom_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('symptom_logs', where: 'id = ?', whereArgs: [id]);
  }
}
