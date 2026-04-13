import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import 'pet_model.dart';

class PetRepository {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<List<Pet>> getAll() async {
    final db = await _db;
    final rows = await db.query('pets', orderBy: 'name ASC');
    return rows.map(Pet.fromMap).toList();
  }

  Future<Pet?> getById(String id) async {
    final db = await _db;
    final rows = await db.query('pets', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Pet.fromMap(rows.first);
  }

  Future<void> add(Pet pet) async {
    final db = await _db;
    await db.insert('pets', pet.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(Pet pet) async {
    final db = await _db;
    await db.update('pets', pet.toMap(), where: 'id = ?', whereArgs: [pet.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('pets', where: 'id = ?', whereArgs: [id]);
  }
}
