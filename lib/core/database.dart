import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../common/constants.dart';
import 'package:logging/logging.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// Initialize the logger
final Logger _logger = Logger('DatabaseLogger');

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const int _databaseVersion = 2; // Increment version if schema changes

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    _initializePredefinedExercises(_database!);
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = await _databasePath();
    _logger.info("Database is located at: $path");
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
      'CREATE TABLE predefined_exercises(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, bodyweight_enabled INTEGER DEFAULT 0)',
    );
    await db.execute(
      'CREATE TABLE fitness(id INTEGER PRIMARY KEY AUTOINCREMENT, weight TEXT, height INTEGER, age INTEGER, timestamp TEXT)',
    );
    await _initializePredefinedExercises(db);
  }

  Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      if (oldVersion < 2) {
        // Add the new column to the predefined_exercises table
        await db.execute(
            'ALTER TABLE predefined_exercises ADD COLUMN bodyweight_enabled INTEGER DEFAULT 0');
      }
    }
  }

  Future<void> _initializePredefinedExercises(Database db) async {
    // Insert predefined exercises into the database if they do not exist
    Batch batch = db.batch();
    for (var exercise in predefinedExercises) {
      exercise.forEach((name, bodyweightEnabled) {
        batch.insert('predefined_exercises',
            {'name': name, 'bodyweight_enabled': bodyweightEnabled == 1});
      });
    }
    await batch.commit(noResult: true); // Execute the batch
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
    if (table == 'fitness') {
      await db.execute('DROP TABLE IF EXISTS fitness');
      await db.execute(
        'CREATE TABLE fitness(id INTEGER PRIMARY KEY AUTOINCREMENT, weight TEXT, height INTEGER, age INTEGER, timestamp TEXT)',
      );
      _logger.info('Fitness table recreated successfully');
    } else {
      await db.delete(table);
    }
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

  Future<List<Map<String, dynamic>>> getExercisesChunk({
    required String sortColumn,
    required bool ascending,
    required int offset,
    required int limit,
    bool isNumeric = false,
    bool isDateTime = false,
    String searchQuery = '',
  }) async {
    final orderBy = isNumeric
        ? 'CAST($sortColumn AS REAL) ${ascending ? 'ASC' : 'DESC'}'
        : isDateTime
            ? 'DATETIME($sortColumn) ${ascending ? 'ASC' : 'DESC'}'
            : '$sortColumn ${ascending ? 'ASC' : 'DESC'}';

    final db = await database;

    // add WHERE clause if searchQuery is not empty
    final whereClause =
        searchQuery.isNotEmpty ? "WHERE exercise LIKE '%$searchQuery%'" : '';

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT * FROM exercises
      $whereClause
      ORDER BY $orderBy
      LIMIT $limit OFFSET $offset
    ''');

    return result;
  }

  Future<List<Map<String, dynamic>>> getFitnessDataChunk({
    required String sortColumn,
    required bool ascending,
    required int offset,
    required int limit,
    bool isNumeric = false,
    bool isDateTime = false,
  }) async {
    final orderBy = isNumeric
        ? 'CAST($sortColumn AS REAL) ${ascending ? 'ASC' : 'DESC'}'
        : isDateTime
            ? 'DATETIME($sortColumn) ${ascending ? 'ASC' : 'DESC'}'
            : '$sortColumn ${ascending ? 'ASC' : 'DESC'}';

    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT * FROM fitness
      ORDER BY $orderBy
      LIMIT $limit OFFSET $offset
    ''');

    return result;
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

    // @TODO: Should instead find the closest weight based on timestamp
    final double bodyweight = await getMostRecentBodyWeight();

    Map<String, dynamic> summary = {};

    for (var exercise in exercises) {
      String exerciseName = exercise['exercise'];
      double weight = double.parse(exercise['weight']);
      int reps = exercise['reps'];
      int sets = exercise['sets'];

      int bodyweightEnabled =
          await isBodyWeightEnabledForExercise(exerciseName);

      // @TODO: dynamically fetch bodyweight value
      weight += bodyweight * bodyweightEnabled;

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

  Future<DateTime?> getLastLoggedExerciseTime() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT MAX(timestamp) as lastTime FROM exercises');
    if (result.isNotEmpty && result.first['lastTime'] != null) {
      return DateTime.parse(result.first['lastTime'] as String);
    }
    return null;
  }

  Future<List<String>> getPredefinedExercises() async {
    final db = await database;
    final List<Map<String, dynamic>> exercises =
        await db.rawQuery('SELECT DISTINCT name FROM predefined_exercises');
    return exercises.map((e) => e['name'] as String).toList();
  }

  Future<int> isBodyWeightEnabledForExercise(String exerciseName) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT bodyweight_enabled FROM predefined_exercises WHERE name = ?',
      [exerciseName],
    );
    return results.isNotEmpty ? results.first['bodyweight_enabled'] as int : 0;
  }

  Future<void> addPredefinedExercise(
      String exerciseName, bool bodyweightEnabled) async {
    final db = await database;
    await db.insert(
      'predefined_exercises',
      {'name': exerciseName, 'bodyweight_enabled': bodyweightEnabled},
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

  Future<double> getMostRecentBodyWeight() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT weight FROM fitness
      ORDER BY timestamp DESC
      LIMIT 1
      ''',
    );

    return results.isNotEmpty ? double.parse(results.first['weight']) : 0.0;
  }

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

  Future<void> backupDatabase(BuildContext context) async {
    try {
      // set backupPath for each OS, android and iOS
      String backupPath;
      if (Platform.isAndroid) {
        backupPath = '/storage/emulated/0/Download/backup_database.db';
      } else if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        backupPath = '${directory.path}/backup_database.db';
      } else {
        throw Exception('Unsupported platform');
      }
      String dbPath = await _databasePath();
      File databaseFile = File(dbPath);
      await databaseFile.copy(backupPath);
      print('Database backed up successfully to $backupPath');
      await _showDialog(context, 'Backup Successful',
          'Database backed up successfully to $backupPath');
    } catch (e) {
      print('Failed to back up database: $e');
      await _showDialog(
          context, 'Backup Failed', 'Failed to back up database: $e');
    }
  }

  Future<void> restoreDatabase(BuildContext context) async {
    try {
      String file_path;
      if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        file_path = '${directory.path}/backup_database.db';
      } else if (Platform.isAndroid) {
        file_path = '/storage/emulated/0/Download/backup_database.db';

        // Use file picker to select the backup file
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.any,
        );

        if (result == null) {
          print('No file selected');
          await _showDialog(context, 'Restore Failed', 'No file selected');
          return;
        }

        file_path = result.files.single.path!;
      } else {
        throw Exception('Unsupported platform');
      }

      // Check if the backup file exists
      File selectedFile = File(file_path);
      if (!await selectedFile.exists()) {
        print('File does not exist');
        await _showDialog(context, 'Restore Failed', 'File does not exist');
        return;
      }

      // Get the destination database path
      String dbPath = await _databasePath();

      // Open the backup database
      Database backupDb = await openDatabase(file_path);

      // Open the destination database
      Database destinationDb = await openDatabase(dbPath);

      // Start a transaction
      await destinationDb.transaction((txn) async {
        // Read records from tables in the backup database
        List<Map<String, dynamic>> exercises =
            await backupDb.query('exercises');
        List<Map<String, dynamic>> predefinedExercises =
            await backupDb.query('predefined_exercises');
        List<Map<String, dynamic>> fitness = await backupDb.query('fitness');

        // Insert records into the respective tables in the destination database
        for (var record in exercises) {
          await txn.insert(
            'exercises',
            record,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        for (var record in predefinedExercises) {
          await txn.insert(
            'predefined_exercises',
            record,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        for (var record in fitness) {
          await txn.insert(
            'fitness',
            record,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      // Close the backup database after transferring records
      await backupDb.close();

      print('Database restored successfully from $file_path');
      await _showDialog(context, 'Restore Successful',
          'Database restored successfully from $file_path');
    } catch (e) {
      print('Failed to restore database: $e');
      await _showDialog(
          context, 'Restore Failed', 'Failed to restore database: $e');
    }
  }

  Future<void> _showDialog(
      BuildContext context, String title, String content) async {
    await showDialog(
      context: context,
      useRootNavigator:
          true, // Ensure the dialog is shown on top of any existing modals
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
