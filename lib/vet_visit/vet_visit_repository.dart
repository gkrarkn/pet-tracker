import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import 'vet_visit_model.dart';

class VetVisitRepository {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<List<VetVisit>> getAll() async {
    final db = await _db;
    final rows = await db.query('vet_visits', orderBy: 'visitDate DESC');
    return rows.map(VetVisit.fromMap).toList();
  }

  Future<List<VetVisit>> getByPetId(String petId) async {
    final db = await _db;
    final rows = await db.query(
      'vet_visits',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'visitDate DESC',
    );
    return rows.map(VetVisit.fromMap).toList();
  }

  Future<List<VetVisit>> getUpcoming({
    String? petId,
    int withinDays = 30,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final until = DateTime.now().add(Duration(days: withinDays)).toIso8601String();
    final rows = await db.query(
      'vet_visits',
      where: petId == null
          ? 'visitDate >= ? AND visitDate <= ?'
          : 'petId = ? AND visitDate >= ? AND visitDate <= ?',
      whereArgs: petId == null ? [now, until] : [petId, now, until],
      orderBy: 'visitDate ASC',
    );
    return rows.map(VetVisit.fromMap).toList();
  }

  Future<VetVisit?> getById(String id) async {
    final db = await _db;
    final rows =
        await db.query('vet_visits', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return VetVisit.fromMap(rows.first);
  }

  Future<void> add(VetVisit visit) async {
    final db = await _db;
    await db.insert('vet_visits', visit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(VetVisit visit) async {
    final db = await _db;
    await db.update('vet_visits', visit.toMap(),
        where: 'id = ?', whereArgs: [visit.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('vet_visits', where: 'id = ?', whereArgs: [id]);
  }
}
