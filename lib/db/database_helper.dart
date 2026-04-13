import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;
  static const _databaseVersion = 7;

  DatabaseHelper._();

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pet_tracker.db');

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await _createPets(db);
        await _createVetVisits(db);
        await _createVaccines(db);
        await _createWeights(db);
        await _createMedications(db);
        await _createMedicationLogs(db);
        await _createCareTasks(db);
        await _createPetDocuments(db);
        await _createSymptomLogs(db);
        await _createCaregiverAccess(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createVaccines(db);
        if (oldVersion < 3) {
          await _createWeights(db);
          await _createMedications(db);
        }
        if (oldVersion < 4) {
          await _addColumnIfNeeded(
            db,
            table: 'vaccines',
            column: 'reminderTime',
            definition: 'TEXT',
          );
          await _addColumnIfNeeded(
            db,
            table: 'vaccines',
            column: 'reminderEnabled',
            definition: 'INTEGER NOT NULL DEFAULT 0',
          );
          await _addColumnIfNeeded(
            db,
            table: 'vaccines',
            column: 'reminderDaysBefore',
            definition: 'INTEGER NOT NULL DEFAULT 3',
          );
          await _addColumnIfNeeded(
            db,
            table: 'medications',
            column: 'reminderTime',
            definition: 'TEXT',
          );
          await _addColumnIfNeeded(
            db,
            table: 'medications',
            column: 'reminderEnabled',
            definition: 'INTEGER NOT NULL DEFAULT 0',
          );
          await _addColumnIfNeeded(
            db,
            table: 'vet_visits',
            column: 'category',
            definition: 'TEXT NOT NULL DEFAULT \'kontrol\'',
          );
          await _addColumnIfNeeded(
            db,
            table: 'vet_visits',
            column: 'reminderTime',
            definition: 'TEXT',
          );
          await _addColumnIfNeeded(
            db,
            table: 'vet_visits',
            column: 'reminderEnabled',
            definition: 'INTEGER NOT NULL DEFAULT 0',
          );
          await _addColumnIfNeeded(
            db,
            table: 'vet_visits',
            column: 'reminderDaysBefore',
            definition: 'INTEGER NOT NULL DEFAULT 1',
          );
          await _createMedicationLogs(db);
        }
        if (oldVersion < 5) {
          await _createCareTasks(db);
        }
        if (oldVersion < 6) {
          await _addColumnIfNeeded(
            db,
            table: 'pets',
            column: 'themeColor',
            definition: 'TEXT NOT NULL DEFAULT \'teal\'',
          );
          await _addColumnIfNeeded(
            db,
            table: 'pets',
            column: 'themeIcon',
            definition: 'TEXT NOT NULL DEFAULT \'pets\'',
          );
          await _addColumnIfNeeded(
            db,
            table: 'vet_visits',
            column: 'clinicAddress',
            definition: 'TEXT',
          );
          await _addColumnIfNeeded(
            db,
            table: 'vet_visits',
            column: 'clinicPhone',
            definition: 'TEXT',
          );
          await _addColumnIfNeeded(
            db,
            table: 'care_tasks',
            column: 'skippedUntil',
            definition: 'TEXT',
          );
        }
        if (oldVersion < 7) {
          await _createPetDocuments(db);
          await _createSymptomLogs(db);
          await _createCaregiverAccess(db);
        }
      },
    );
  }

  Future<void> _addColumnIfNeeded(
    Database db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  Future<void> _createPets(Database db) => db.execute('''
    CREATE TABLE pets (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      species TEXT NOT NULL,
      breed TEXT NOT NULL,
      birthDate TEXT NOT NULL,
      photoUrl TEXT,
      themeColor TEXT NOT NULL DEFAULT 'teal',
      themeIcon TEXT NOT NULL DEFAULT 'pets'
    )
  ''');

  Future<void> _createVetVisits(Database db) => db.execute('''
    CREATE TABLE vet_visits (
      id TEXT PRIMARY KEY,
      petId TEXT NOT NULL,
      visitDate TEXT NOT NULL,
      category TEXT NOT NULL DEFAULT 'kontrol',
      reason TEXT NOT NULL,
      notes TEXT,
      vetName TEXT,
      clinicAddress TEXT,
      clinicPhone TEXT,
      reminderTime TEXT,
      reminderEnabled INTEGER NOT NULL DEFAULT 0,
      reminderDaysBefore INTEGER NOT NULL DEFAULT 1,
      FOREIGN KEY (petId) REFERENCES pets (id) ON DELETE CASCADE
    )
  ''');

  Future<void> _createVaccines(Database db) => db.execute('''
    CREATE TABLE vaccines (
      id TEXT PRIMARY KEY,
      petId TEXT NOT NULL,
      name TEXT NOT NULL,
      administeredDate TEXT NOT NULL,
      nextDueDate TEXT,
      notes TEXT,
      vetName TEXT,
      reminderTime TEXT,
      reminderEnabled INTEGER NOT NULL DEFAULT 0,
      reminderDaysBefore INTEGER NOT NULL DEFAULT 3,
      FOREIGN KEY (petId) REFERENCES pets (id) ON DELETE CASCADE
    )
  ''');

  Future<void> _createWeights(Database db) => db.execute('''
    CREATE TABLE weights (
      id TEXT PRIMARY KEY,
      petId TEXT NOT NULL,
      weightKg REAL NOT NULL,
      recordedAt TEXT NOT NULL,
      notes TEXT,
      FOREIGN KEY (petId) REFERENCES pets (id) ON DELETE CASCADE
    )
  ''');

  Future<void> _createMedications(Database db) => db.execute('''
    CREATE TABLE medications (
      id TEXT PRIMARY KEY,
      petId TEXT NOT NULL,
      name TEXT NOT NULL,
      dosage TEXT NOT NULL,
      frequency TEXT NOT NULL,
      startDate TEXT NOT NULL,
      endDate TEXT,
      notes TEXT,
      isActive INTEGER NOT NULL DEFAULT 1,
      reminderTime TEXT,
      reminderEnabled INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (petId) REFERENCES pets (id) ON DELETE CASCADE
    )
  ''');

  Future<void> _createMedicationLogs(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS medication_logs (
      id TEXT PRIMARY KEY,
      medicationId TEXT NOT NULL,
      petId TEXT NOT NULL,
      scheduledDate TEXT NOT NULL,
      status TEXT NOT NULL,
      takenAt TEXT,
      note TEXT,
      FOREIGN KEY (medicationId) REFERENCES medications (id) ON DELETE CASCADE,
      FOREIGN KEY (petId) REFERENCES pets (id) ON DELETE CASCADE
    )
  ''');

  Future<void> _createCareTasks(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS care_tasks (
      id TEXT PRIMARY KEY,
      petId TEXT NOT NULL,
      type TEXT NOT NULL,
      title TEXT NOT NULL,
      frequency TEXT NOT NULL,
      notes TEXT,
      reminderEnabled INTEGER NOT NULL DEFAULT 0,
      reminderTime TEXT,
      isActive INTEGER NOT NULL DEFAULT 1,
      startDate TEXT NOT NULL,
      lastCompletedAt TEXT,
      skippedUntil TEXT,
      FOREIGN KEY (petId) REFERENCES pets (id) ON DELETE CASCADE
    )
  ''');

  Future<void> _createPetDocuments(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS pet_documents (
      id TEXT PRIMARY KEY,
      petId TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT,
      filePath TEXT NOT NULL,
      fileType TEXT NOT NULL DEFAULT 'image',
      createdAt TEXT NOT NULL,
      FOREIGN KEY (petId) REFERENCES pets (id) ON DELETE CASCADE
    )
  ''');

  Future<void> _createSymptomLogs(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS symptom_logs (
      id TEXT PRIMARY KEY,
      petId TEXT NOT NULL,
      symptom TEXT NOT NULL,
      severity TEXT NOT NULL,
      note TEXT,
      observedAt TEXT NOT NULL,
      FOREIGN KEY (petId) REFERENCES pets (id) ON DELETE CASCADE
    )
  ''');

  Future<void> _createCaregiverAccess(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS caregiver_access (
      id TEXT PRIMARY KEY,
      petId TEXT NOT NULL,
      name TEXT NOT NULL,
      role TEXT NOT NULL,
      inviteCode TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'active',
      lastAction TEXT,
      lastActiveAt TEXT,
      FOREIGN KEY (petId) REFERENCES pets (id) ON DELETE CASCADE
    )
  ''');
}
