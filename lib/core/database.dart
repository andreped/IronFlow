import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../common/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const int _databaseVersion = 2; // Update version as needed

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'exercises.db');
    print("Database is located at: $path");
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _upgradeDatabase(db, oldVersion, newVersion);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute(
      'CREATE TABLE exercises(id INTEGER PRIMARY KEY AUTOINCREMENT, exercise TEXT, weight TEXT, reps INTEGER, sets INTEGER, timestamp TEXT)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS predefined_exercises(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)',
    );
    await _initializePredefinedExercises(db);
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Example migration from version 1 to 2: add a new column 'notes'
      await db.execute('ALTER TABLE exercises ADD COLUMN notes TEXT');
    }
    // Handle further migrations here
  }

  Future<void> _initializePredefinedExercises(Database db) async {
    // Insert predefined exercises into the database if they do not exist
    Batch batch = db.batch();
    for (String exercise in predefinedExercises) {
      batch.insert('predefined_exercises', {'name': exercise});
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertExercise({
    required String exercise,
    required String weight,
    required int reps,
    required int sets,
  }) async {
    final db = await database;
    await db.insert(
      'exercises',
      {
        'exercise': exercise,
        'weight': weight,
        'reps': reps,
        'sets': sets,
        'timestamp': DateTime.now().toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteExercise(int id) async {
    final db = await database;
    await db.delete(
      'exercises',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('exercises');
  }

  Future<List<Map<String, dynamic>>> getExercises() async {
    final db = await database;
    return await db.query(
      'exercises',
      orderBy: 'timestamp DESC', // Order by timestamp in descending order
    );
  }

  Future<List<DateTime>> getExerciseDates() async {
    final db = await database;
    final List<Map<String, dynamic>> datesResult = await db.rawQuery(
      'SELECT DISTINCT date(timestamp) as date FROM exercises'
    );

    return datesResult.map((row) {
      return DateTime.parse(row['date']);
    }).toList();
  }

  Future<void> updateExercise({
    required int id,
    required String exercise,
    required String weight,
    required int reps,
    required int sets,
  }) async {
    final db = await database;
    await db.update(
      'exercises',
      {
        'exercise': exercise,
        'weight': weight,
        'reps': reps,
        'sets': sets,
        // Note: Do not update the timestamp here
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> isNewHighScore(String exerciseName, double newWeight) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'exercises',
      columns: ['MAX(weight) as maxWeight'],
      where: 'exercise = ?',
      whereArgs: [exerciseName],
    );

    if (results.isNotEmpty && results.first['maxWeight'] != null) {
      final maxWeight = double.parse(results.first['maxWeight'].toString());
      return newWeight > maxWeight;
    }
    return true; // If it's the first entry for the exercise, it's a high score.
  }

  Future<Map<String, double>> getTotalWeightForDay(DateTime day) async {
    final db = await database;
    final List<Map<String, dynamic>> exercises = await db.query(
      'exercises',
      where: 'date(timestamp) = ?',
      whereArgs: [day.toIso8601String().split('T')[0]],
    );

    Map<String, double> totalWeights = {};

    for (var exercise in exercises) {
      String exerciseName = exercise['exercise'];
      double weight = double.parse(exercise['weight']);
      int reps = exercise['reps'];
      int sets = exercise['sets'];
      double totalWeight = weight * reps * sets;

      if (totalWeights.containsKey(exerciseName)) {
        totalWeights[exerciseName] = totalWeights[exerciseName]! + totalWeight;
      } else {
        totalWeights[exerciseName] = totalWeight;
      }
    }

    return totalWeights;
  }

  Future<Map<String, dynamic>> getSummaryForDay(DateTime day) async {
    final db = await database;
    final List<Map<String, dynamic>> exercises = await db.query(
      'exercises',
      where: 'date(timestamp) = ?',
      whereArgs: [day.toIso8601String().split('T')[0]],
    );

    Map<String, dynamic> summary = {};

    for (var exercise in exercises) {
      String exerciseName = exercise['exercise'];
      double weight = double.parse(exercise['weight']);
      int reps = exercise['reps'];
      int sets = exercise['sets'];
      double totalWeight = weight * reps * sets;

      if (summary.containsKey(exerciseName)) {
        summary[exerciseName]['totalWeight'] += totalWeight;
        summary[exerciseName]['totalSets'] += sets;
        summary[exerciseName]['totalReps'] += reps;
        summary[exerciseName]['records'].add(exercise);
      } else {
        summary[exerciseName] = {
          'totalWeight': totalWeight,
          'totalSets': sets,
          'totalReps': reps,
          'avgWeight': 0.0,
          'records': [exercise],
        };
      }
    }

    summary.forEach((key, value) {
      value['avgWeight'] = value['totalWeight'] / value['totalSets'];
    });

    return summary;
  }

  Future<List<String>> getPredefinedExercises() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query('predefined_exercises');
    return result.map((row) => row['name'] as String).toList();
  }

  Future<void> addPredefinedExercise(String exerciseName) async {
    final db = await database;
    await db.insert(
      'predefined_exercises',
      {'name': exerciseName},
      conflictAlgorithm: ConflictAlgorithm.ignore, // Handle if exercise already exists
    );
  }

  Future<Map<String, Map<String, dynamic>>> getMaxWeightsForExercises() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT exercise, weight, reps FROM exercises WHERE CAST(weight AS REAL) IN (SELECT MAX(CAST(weight AS REAL)) FROM exercises GROUP BY exercise)'
    );

    Map<String, Map<String, dynamic>> maxWeights = {};
    for (var result in results) {
      maxWeights[result['exercise']] = {
        'maxWeight': double.parse(result['weight']),
        'reps': result['reps']
      };
    }
    return maxWeights;
  }
}
