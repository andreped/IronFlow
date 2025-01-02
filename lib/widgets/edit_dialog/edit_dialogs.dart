import 'package:flutter/material.dart';
import '../../core/database.dart';
import 'exercise_edit_dialog.dart';
import 'fitness_edit_dialog.dart';

void showEditDialog(
  BuildContext context,
  Map<String, dynamic> exercise,
  bool isKg,
  DatabaseHelper dbHelper,
  Function loadData,
  String selectedTable,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return ExerciseEditDialog(
        exerciseData: exercise,
        isKg: isKg,
      );
    },
  ).then((result) async {
    if (result != null) {
      final weight = isKg
          ? result['weight']
          : (double.parse(result['weight']) * 2.20462).toStringAsFixed(2);

      await dbHelper.updateExercise(
        id: result['id'],
        exercise: result['exercise'],
        weight: weight,
        reps: result['reps'],
        sets: result['sets'],
        timestamp: result['timestamp'],
      );
      loadData(selectedTable);
    }
  });
}

void showFitnessEditDialog(
  BuildContext context,
  Map<String, dynamic> fitness,
  bool isKg,
  DatabaseHelper dbHelper,
  Function loadData,
  String selectedTable,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return FitnessEditDialog(
        fitnessData: fitness,
        isKg: isKg,
      );
    },
  ).then((result) async {
    if (result != null) {
      final weight = isKg
          ? result['weight']
          : (double.parse(result['weight']) * 2.20462).toStringAsFixed(2);

      await dbHelper.updateFitness(
        id: result['id'],
        weight: weight,
        height: result['height'],
        age: result['age'],
        timestamp: result['timestamp'],
      );
      loadData(selectedTable);
    }
  });
}

Future<void> deleteRow(
  String table,
  int id,
  BuildContext context,
  DatabaseHelper dbHelper,
  Function loadData,
  String selectedTable,
) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('🚨 Are you sure you want to delete this record?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
    },
  );

  if (confirmed == true) {
    await dbHelper.deleteRowItem(table, id);
    loadData(selectedTable);
  }
}