import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../common/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const int _databaseVersion = 1; // Increment version if schema changes

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = await _databasePath();
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
      readOnly: false, // Ensure the database is not opened in read-only mode
    );
  }

  Future<String> _databasePath() async {
    return join(await getDatabasesPath(), 'exercises.db');
  }

  Future<void> _createTables(Database db) async {
    await db.execute(
      'CREATE TABLE exercises(id INTEGER PRIMARY KEY AUTOINCREMENT, exercise TEXT, weight TEXT, reps INTEGER, sets INTEGER, timestamp TEXT)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS predefined_exercises(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)',
    );
    await db.execute(
      'CREATE TABLE fitness(id INTEGER PRIMARY KEY AUTOINCREMENT, weight TEXT, height INTEGER, age INTEGER, timestamp TEXT)',
    );
    await _initializePredefinedExercises(db);
  }

  Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      if (oldVersion < 1) {
        //await db.execute("DROP TABLE IF EXISTS fitness");

        //await db.execute(
        //  'CREATE TABLE fitness(id INTEGER PRIMARY KEY AUTOINCREMENT, weight TEXT, height INTEGER, age INTEGER, timestamp TEXT)',
        //);
      }
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

  Future<void> deleteRowItem(String table, int id) async {
    final db = await database;
    await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearDatabase(String table) async {
    final db = await database;
    await db.delete(table);
  }

  Future<List<String>> getRecordedExercises() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT exercise 
      FROM exercises
    ''');

    return result.map((row) => row['exercise'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getExercises({
    String sortColumn = 'timestamp',
    bool ascending = false,
  }) async {
    final db = await database;
    final orderBy = sortColumn == 'weight'
        ? 'CAST($sortColumn AS REAL) ${ascending ? 'ASC' : 'DESC'}'
        : '$sortColumn ${ascending ? 'ASC' : 'DESC'}';
    return await db.query(
      'exercises',
      orderBy: orderBy,
    );
  }

  Future<List<Map<String, dynamic>>> getFitnessData({
    String sortColumn = 'timestamp',
    bool ascending = false,
  }) async {
    final db = await database;
    final orderBy = '$sortColumn ${ascending ? 'ASC' : 'DESC'}';
    return await db.query(
      'fitness',
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

  Future<void> updateFitness({
    required int id,
    required String weight,
    required int height,
    required int age,
    required String timestamp,
  }) async {
    final db = await database;
    await db.update(
      'fitness',
      {
        'weight': weight,
        'height': height,
        'age': age,
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
    final List<Map<String, dynamic>> records = await db.query(
      'exercises',
      where: 'exercise = ?',
      whereArgs: [exerciseName],
      orderBy: 'timestamp DESC', // Optional: order by timestamp
    );

    double totalWeight = 0;
    int totalSets = 0;
    int totalReps = 0;
    DateTime? lastLoggedDate;
    int recordCount = records.length;

    for (var record in records) {
      totalWeight +=
          double.parse(record['weight']) * record['reps'] * record['sets'];
      totalSets += record['sets'] as int;
      totalReps += record['reps'] as int;
      lastLoggedDate = DateTime.parse(record['timestamp']);
    }

    double avgWeight = totalSets > 0 ? totalWeight / totalSets : 0;

    return {
      'totalWeight': totalWeight,
      'totalSets': totalSets,
      'totalReps': totalReps,
      'avgWeight': avgWeight,
      'recordCount': recordCount,
      'lastLoggedDate': lastLoggedDate,
    };
  }

  Future<List<String>> getPredefinedExercises() async {
    final db = await database;
    final List<Map<String, dynamic>> exercises =
        await db.rawQuery('SELECT DISTINCT name FROM predefined_exercises');
    return exercises.map((e) => e['name'] as String).toList();
  }

  Future<void> addPredefinedExercise(String exerciseName) async {
    final db = await database;
    await db.insert(
      'predefined_exercises',
      {'name': exerciseName},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, dynamic>>> getMaxWeightsForExercises() async {
    final db = await database;
    final List<Map<String, dynamic>> maxWeights = await db.rawQuery(
      '''
      SELECT exercise, weight, reps, sets
      FROM exercises
      WHERE (exercise, weight) IN (
        SELECT exercise, MAX(CAST(weight AS REAL)) as weight
        FROM exercises
        GROUP BY exercise
      )
      ORDER BY exercise, reps DESC
      ''',
    );

    // Remove duplicates by keeping only the first occurrence of each exercise
    final Map<String, Map<String, dynamic>> uniqueMaxWeights = {};
    for (var record in maxWeights) {
      final exercise = record['exercise'];
      if (!uniqueMaxWeights.containsKey(exercise)) {
        uniqueMaxWeights[exercise] = record;
      }
    }

    return uniqueMaxWeights.values.toList();
  }

  Future<Map<String, dynamic>> getLastLoggedExercise(
      String exerciseName) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT * FROM exercises
      WHERE exercise = ?
      ORDER BY timestamp DESC
      LIMIT 1
      ''',
      [exerciseName],
    );

    return results.isNotEmpty ? results.first : {};
  }

  Future<String?> getLastLoggedExerciseName() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT exercise FROM exercises
      ORDER BY timestamp DESC
      LIMIT 1
      ''',
    );

    return results.isNotEmpty ? results.first['exercise'] as String : null;
  }

  Future<Map<String, dynamic>?> getLastLoggedFitness() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT weight, height, age FROM fitness
      ORDER BY timestamp DESC
      LIMIT 1
      ''',
    );

    return results.isNotEmpty ? results.first : null;
  }

  // Methods for fitness table
  Future<void> insertFitness({
    required double weight,
    required int height,
    required int age,
  }) async {
    final db = await database;
    await db.insert(
      'fitness',
      {
        'weight': weight,
        'height': height,
        'age': age,
        'timestamp': DateTime.now().toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> isExerciseUsed(String exerciseName) async {
    final db = await database;
    var result = await db.rawQuery(
        'SELECT COUNT(*) FROM exercises WHERE exercise = ?', [exerciseName]);
    int? count = Sqflite.firstIntValue(result);
    return count! > 0;
  }

  Future<void> deleteExercise(String exerciseName) async {
    final db = await database;
    await db.delete('predefined_exercises',
        where: 'name = ?', whereArgs: [exerciseName]);
  }

  Future<void> backupDatabase() async {
    try {
      // Request storage permissions
      if (await Permission.storage.request().isGranted) {
        // Get the default directory (Downloads)
        Directory? downloadsDirectory = await getDownloadsDirectory();
        String defaultPath = downloadsDirectory?.path ?? '';

        // Let the user choose the directory
        String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Select Backup Directory',
          initialDirectory: defaultPath,
        );

        if (selectedDirectory != null) {
          // Perform the backup operation
          String dbPath = await _databasePath();
          File databaseFile = File(dbPath);
          String backupPath = '$selectedDirectory/backup_database.db';
          await databaseFile.copy(backupPath);

          print('Database backed up successfully to $backupPath');
        } else {
          print('Backup operation cancelled');
        }
      } else {
        print('Storage permission denied');
      }
    } catch (e) {
      print('Failed to back up database: $e');
    }
  }

  Future<void> restoreDatabase() async {
    try {
      // Request storage permissions
      if (await Permission.storage.request().isGranted) {
        // Let the user select the backup file
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          dialogTitle: 'Select Backup File',
          type: FileType.custom,
          allowedExtensions: ['db'],
        );

        if (result != null && result.files.single.path != null) {
          String selectedFilePath = result.files.single.path!;

          // Perform the restore operation
          String dbPath = await _databasePath();
          File selectedFile = File(selectedFilePath);
          await selectedFile.copy(dbPath);

          print('Database restored successfully from $selectedFilePath');
        } else {
          print('Restore operation cancelled');
        }
      } else {
        print('Storage permission denied');
      }
    } catch (e) {
      print('Failed to restore database: $e');
    }
  }
}
