import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import 'document_model.dart';

class DocumentRepository {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<List<PetDocument>> getByPetId(String petId) async {
    final db = await _db;
    final rows = await db.query(
      'pet_documents',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(PetDocument.fromMap).toList();
  }

  Future<void> add(PetDocument doc) async {
    final db = await _db;
    await db.insert('pet_documents', doc.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(PetDocument doc) async {
    final db = await _db;
    await db.update('pet_documents', doc.toMap(),
        where: 'id = ?', whereArgs: [doc.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('pet_documents', where: 'id = ?', whereArgs: [id]);
  }
}
