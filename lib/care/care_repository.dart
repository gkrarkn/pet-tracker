import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import 'care_task_model.dart';

class CareRepository {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<List<CareTask>> getByPetId(String petId) async {
    final db = await _db;
    final rows = await db.query(
      'care_tasks',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'isActive DESC, title ASC',
    );
    return rows.map(CareTask.fromMap).toList();
  }

  Future<List<CareTask>> getAllActive() async {
    final db = await _db;
    final rows = await db.query(
      'care_tasks',
      where: 'isActive = 1',
      orderBy: 'title ASC',
    );
    return rows.map(CareTask.fromMap).toList();
  }

  Future<CareTask?> getById(String id) async {
    final db = await _db;
    final rows = await db.query(
      'care_tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CareTask.fromMap(rows.first);
  }

  Future<void> add(CareTask task) async {
    final db = await _db;
    await db.insert(
      'care_tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(CareTask task) async {
    final db = await _db;
    await db.update(
      'care_tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('care_tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setActive(String id, bool isActive) async {
    final db = await _db;
    await db.update(
      'care_tasks',
      {'isActive': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markCompleted(String id, DateTime completedAt) async {
    final db = await _db;
    await db.update(
      'care_tasks',
      {
        'lastCompletedAt': completedAt.toIso8601String(),
        'skippedUntil': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> skipUntil(String id, DateTime skippedUntil) async {
    final db = await _db;
    await db.update(
      'care_tasks',
      {
        'skippedUntil': skippedUntil.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
