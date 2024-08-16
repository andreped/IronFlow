import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../common/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const int _databaseVersion = 1; // Keep the version fixed for now

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

  Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    // Placeholder for future upgrade logic
    if (oldVersion < newVersion) {
      // Example: if (oldVersion < 2) {
      //   await db.execute('ALTER TABLE exercises ADD COLUMN notes TEXT');
      // }
      // Add more version checks and migration logic as needed
    }
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

  Future<List<Map<String, dynamic>>> getExercises({
    String sortColumn = 'timestamp',
    bool ascending = false,
  }) async {
    final db = await database;
    final orderBy = '$sortColumn ${ascending ? 'ASC' : 'DESC'}';
    return await db.query(
      'exercises',
      orderBy: orderBy,
    );
  }

  Future<List<DateTime>> getExerciseDates() async {
    final db = await database;
    final List<Map<String, dynamic>> datesResult = await db
        .rawQuery('SELECT DISTINCT date(timestamp) as date FROM exercises');

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
    required String timestamp,
  }) async {
    final db = await database;
    await db.update(
      'exercises',
      {
        'exercise': exercise,
        'weight': weight,
        'reps': reps,
        'sets': sets,
        'timestamp': timestamp,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateExerciseName(String oldName, String newName) async {
    final db = await database;
    await db.update(
      'exercises',
      {'exercise': newName},
      where: 'exercise = ?',
      whereArgs: [oldName],
    );
  }

  Future<void> updatePredefinedExercise(String oldName, String newName) async {
    final db = await database;

    // Update predefined_exercises table
    await db.update(
      'predefined_exercises',
      {'name': newName},
      where: 'name = ?',
      whereArgs: [oldName],
    );

    // Update exercises table
    await db.update(
      'exercises',
      {'exercise': newName},
      where: 'exercise = ?',
      whereArgs: [oldName],
    );
  }

  Future<bool> isNewHighScore(
      String exerciseName, double newWeight, int newReps) async {
    final db = await database;

    // Query to get the current highest weight and corresponding reps for that weight
    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT weight, reps FROM exercises 
      WHERE exercise = ?
      ORDER BY CAST(weight AS REAL) DESC, reps DESC
      LIMIT 1
      ''',
      [exerciseName],
    );

    if (results.isNotEmpty) {
      final row = results.first;
      final maxWeight = double.parse(row['weight'].toString());
      final maxReps = row['reps'] as int;

      // Check if both weight and reps are greater than the current record
      if (newWeight > maxWeight ||
          (newWeight == maxWeight && newReps > maxReps)) {
        return true; // New record found
      }
    }

    return false; // No new record
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

  Future<Map<DateTime, List<Map<String, dynamic>>>> getDailyRecordsForExercise(
      String exerciseName) async {
    final db = await database;
    final List<Map<String, dynamic>> records = await db.query(
      'exercises',
      where: 'exercise = ?',
      whereArgs: [exerciseName],
      orderBy: 'timestamp DESC', // Optional: order by timestamp
    );

    Map<DateTime, List<Map<String, dynamic>>> dailyRecords = {};

    for (var record in records) {
      DateTime date = DateTime.parse(record['timestamp']).toLocal();
      DateTime day = DateTime(date.year, date.month, date.day);

      if (!dailyRecords.containsKey(day)) {
        dailyRecords[day] = [];
      }
      dailyRecords[day]!.add(record);
    }

    return dailyRecords;
  }

  Future<Map<String, dynamic>> getSummaryForExercise(
      String exerciseName) async {
    final db = await database;
    final List<Map<String, dynamic>> exercises = await db.query(
      'exercises',
      where: 'exercise = ?',
      whereArgs: [exerciseName],
    );

    Map<String, dynamic> summary = {};
    Map<String, List<Map<String, dynamic>>> recordsByDate = {};

    if (exercises.isNotEmpty) {
      double totalWeight = 0;
      int totalSets = 0;
      int totalReps = 0;

      for (var record in exercises) {
        double weight = double.parse(record['weight']);
        int reps = record['reps'];
        int sets = record['sets'];
        DateTime timestamp = DateTime.parse(record['timestamp']);
        String dateKey =
            '${timestamp.year}-${timestamp.month}-${timestamp.day}';

        double weightPerSession = weight * reps * sets;
        totalWeight += weightPerSession;
        totalSets += sets;
        totalReps += reps;

        if (recordsByDate[dateKey] == null) {
          recordsByDate[dateKey] = [];
        }
        recordsByDate[dateKey]!.add(record);
      }

      summary[exerciseName] = {
        'totalWeight': totalWeight,
        'totalSets': totalSets,
        'totalReps': totalReps,
        'avgWeight': totalWeight / totalSets,
        'recordsByDate': recordsByDate,
      };
    }

    return summary;
  }

  Future<List<String>> getPredefinedExercises() async {
    final db = await database;
    final List<Map<String, dynamic>> result =
        await db.query('predefined_exercises');
    return result.map((row) => row['name'] as String).toList();
  }

  Future<void> addPredefinedExercise(String exerciseName) async {
    final db = await database;
    await db.insert(
      'predefined_exercises',
      {'name': exerciseName},
      conflictAlgorithm:
          ConflictAlgorithm.ignore, // Handle if exercise already exists
    );
  }

  Future<Map<String, Map<String, dynamic>>> getMaxWeightsForExercises() async {
    final db = await database;

    // Query to get the maximum weight and corresponding highest reps for each exercise
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT exercise, weight, reps
      FROM exercises
      WHERE (exercise, CAST(weight AS REAL)) IN (
        SELECT exercise, MAX(CAST(weight AS REAL))
        FROM exercises
        GROUP BY exercise
      )
      ORDER BY exercise, CAST(weight AS REAL) DESC, reps DESC
      ''');

    Map<String, Map<String, dynamic>> maxWeights = {};
    for (var result in results) {
      final exercise = result['exercise'] as String;
      final weight = double.parse(result['weight']);
      final reps = result['reps'] as int;

      if (maxWeights.containsKey(exercise)) {
        final existing = maxWeights[exercise]!;
        if (weight == existing['maxWeight']) {
          if (reps > existing['reps']) {
            existing['reps'] = reps;
          }
        } else if (weight > existing['maxWeight']) {
          existing['maxWeight'] = weight;
          existing['reps'] = reps;
        }
      } else {
        maxWeights[exercise] = {
          'maxWeight': weight,
          'reps': reps,
        };
      }
    }

    return maxWeights;
  }

  Future<Map<String, dynamic>?> getLastLoggedExercise(
      String exerciseName) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'exercises',
      where: 'exercise = ?',
      whereArgs: [exerciseName],
      orderBy: 'timestamp DESC',
      limit: 1, // Fetch only the latest entry
    );

    if (result.isNotEmpty) {
      final row = result.first;
      return {
        'exercise': row['exercise'],
        'weight':
            double.tryParse(row['weight']) ?? 0.0, // Convert weight to double
        'reps': row['reps'] as int,
        'sets': row['sets'] as int,
      };
    }
    return null;
  }

  Future<String?> getLastLoggedExerciseName() async {
    final db = await database;

    // Query to get the most recent exercise entry based on the timestamp
    final List<Map<String, dynamic>> result = await db.query(
      'exercises',
      orderBy: 'timestamp DESC',
      limit: 1, // Fetch only the latest entry
    );

    // Check if we have any results
    if (result.isNotEmpty) {
      final row = result.first;
      return row['exercise'] as String?;
    }

    // Return null if no result found
    return null;
  }
}
