import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import 'weight_model.dart';

class WeightRepository {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<List<WeightRecord>> getByPetId(String petId) async {
    final db = await _db;
    final rows = await db.query(
      'weights',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'recordedAt ASC',
    );
    return rows.map(WeightRecord.fromMap).toList();
  }

  Future<WeightRecord?> getLatest(String petId) async {
    final db = await _db;
    final rows = await db.query(
      'weights',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'recordedAt DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WeightRecord.fromMap(rows.first);
  }

  Future<void> add(WeightRecord record) async {
    final db = await _db;
    await db.insert('weights', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('weights', where: 'id = ?', whereArgs: [id]);
  }
}
