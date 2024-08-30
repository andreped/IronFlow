import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';
import 'package:IronFlow/core/database.dart'; // Adjust this import based on your project structure

// Mock Database class using Mockito
class MockDatabase extends Mock implements Database {}

// Mocking a function to simulate getting a database path
class MockDatabaseFactory extends Mock implements DatabaseFactory {}

void main() {
  late DatabaseHelper databaseHelper;
  late MockDatabase mockDatabase;
  late MockDatabaseFactory mockDatabaseFactory;

  setUp(() {
    mockDatabase = MockDatabase();
    mockDatabaseFactory = MockDatabaseFactory();
    databaseHelper = DatabaseHelper();
  });

  group('DatabaseHelper Tests', () {
    test('Should initialize database and create tables', () async {
      // Arrange
      when(mockDatabaseFactory.openDatabase(
        await getDatabasesPath(),
        options: anyNamed('options'),
      )).thenAnswer((_) async => mockDatabase);

      when(mockDatabase.execute(
              'CREATE TABLE exercises(id INTEGER PRIMARY KEY AUTOINCREMENT, exercise TEXT, weight TEXT, reps INTEGER, sets INTEGER, timestamp TEXT)'))
          .thenAnswer((_) async => Future.value());

      when(mockDatabase.execute(
              'CREATE TABLE IF NOT EXISTS predefined_exercises(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)'))
          .thenAnswer((_) async => Future.value());

      // Act
      final db = await databaseHelper.database;
      await databaseHelper.database; // Trigger database initialization

      // Assert
      verify(mockDatabase.execute(
        'CREATE TABLE exercises(id INTEGER PRIMARY KEY AUTOINCREMENT, exercise TEXT, weight TEXT, reps INTEGER, sets INTEGER, timestamp TEXT)',
      )).called(1);
      verify(mockDatabase.execute(
        'CREATE TABLE IF NOT EXISTS predefined_exercises(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)',
      )).called(1);
    });

    test('Should insert exercise into the database', () async {
      // Arrange
      when(mockDatabase.insert(
        'exercises',
        {
          'exercise': 'Bench Press',
          'weight': '100',
          'reps': 10,
          'sets': 4,
          'timestamp': isA<String>(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      )).thenAnswer((_) async => 1);

      // Act
      await databaseHelper.insertExercise(
        exercise: 'Bench Press',
        weight: '100',
        reps: 10,
        sets: 4,
      );

      // Assert
      verify(mockDatabase.insert(
        'exercises',
        {
          'exercise': 'Bench Press',
          'weight': '100',
          'reps': 10,
          'sets': 4,
          'timestamp': isA<String>(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      )).called(1);
    });

    test('Should delete exercise from the database', () async {
      // Arrange
      when(mockDatabase.delete(
        'exercises',
        where: 'id = ?',
        whereArgs: [1],
      )).thenAnswer((_) async => 1);

      // Act
      await databaseHelper.deleteRowItem("exercises", 1);

      // Assert
      verify(mockDatabase.delete(
        'exercises',
        where: 'id = ?',
        whereArgs: [1],
      )).called(1);
    });

    test('Should retrieve exercises from the database', () async {
      // Arrange
      when(mockDatabase.query('exercises', orderBy: 'timestamp DESC'))
          .thenAnswer((_) async => [
                {
                  'exercise': 'Bench Press',
                  'weight': '100',
                  'reps': 10,
                  'sets': 4,
                  'timestamp': DateTime.now().toString()
                }
              ]);

      // Act
      final exercises = await databaseHelper.getExercises();

      // Assert
      expect(exercises.length, 1);
      expect(exercises.first['exercise'], 'Bench Press');
    });

    test('Should check for new high score correctly', () async {
      // Arrange
      when(mockDatabase.rawQuery(
          'SELECT weight, reps FROM exercises WHERE exercise = ? ORDER BY weight DESC, reps DESC LIMIT 1',
          [
            'Bench Press'
          ])).thenAnswer((_) async => [
            {'weight': '100', 'reps': 10}
          ]);

      // Act
      final isNewHighScore =
          await databaseHelper.isNewHighScore('Bench Press', 110, 8);

      // Assert
      expect(isNewHighScore, true);
    });

    test('Should calculate total weight for a day correctly', () async {
      // Arrange
      final today = DateTime.now().toString().split(' ')[0];
      when(mockDatabase.query('exercises',
              where: 'timestamp LIKE ?', whereArgs: ['$today%']))
          .thenAnswer((_) async => [
                {
                  'exercise': 'Bench Press',
                  'weight': '100',
                  'reps': 10,
                  'sets': 4,
                  'timestamp': DateTime.now().toString()
                }
              ]);

      // Act
      final totalWeight =
          await databaseHelper.getTotalWeightForDay(DateTime.now());

      // Assert
      expect(totalWeight['Bench Press'], 100.0 * 10 * 4);
    });

    test('Should get the last logged exercise correctly', () async {
      // Arrange
      when(mockDatabase.query('exercises',
              where: 'exercise = ?',
              whereArgs: ['Bench Press'],
              orderBy: 'timestamp DESC',
              limit: 1))
          .thenAnswer((_) async => [
                {
                  'exercise': 'Bench Press',
                  'weight': '100',
                  'reps': 10,
                  'sets': 4,
                  'timestamp': DateTime.now().toString()
                }
              ]);

      // Act
      final lastLoggedExercise =
          await databaseHelper.getLastLoggedExercise('Bench Press');

      // Assert
      expect(lastLoggedExercise, isNotNull);
      expect(lastLoggedExercise!['exercise'], 'Bench Press');
    });
  });
}
