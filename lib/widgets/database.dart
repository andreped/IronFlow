import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'exercises.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE exercises(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, value TEXT, timestamp TEXT)',
        );
      },
    );
  }

  Future<void> insertExercise(String name, String value) async {
    final db = await database;
    await db.insert(
      'exercises',
      {'name': name, 'value': value, 'timestamp': DateTime.now().toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getExercises() async {
    final db = await database;
    return await db.query('exercises');
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('exercises');
  }
}
