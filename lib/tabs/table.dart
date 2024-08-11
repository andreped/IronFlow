import 'package:flutter/material.dart';
import '../core/database.dart';
import '../widgets/exercise_edit_dialog.dart';

class TableTab extends StatefulWidget {
  @override
  _TableTabState createState() => _TableTabState();
}

class _TableTabState extends State<TableTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Map<String, dynamic>>> _getExercises() async {
    return await _dbHelper.getExercises();
  }

  Future<void> _deleteExercise(int id) async {
    await _dbHelper.deleteExercise(id);
    setState(() {});
  }

  void _showEditDialog(Map<String, dynamic> exercise) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ExerciseEditDialog(exerciseData: exercise);
      },
    ).then((result) async {
      if (result != null) {
        await _dbHelper.updateExercise(
          id: result['id'],
          exercise: result['exercise'],
          weight: result['weight'],
          reps: result['reps'],
          sets: result['sets'],
          timestamp: result['timestamp'],
        );
        setState(() {});
      }
    });
  }

  Future<void> _showConfirmationDialogs() async {
    final bool? firstDialogConfirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ Confirm Deletion'),
          content: const Text(
              '🚨 Clicking this button deletes all the recorded exercise data. Are you sure you want to do this?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (firstDialogConfirmed == true) {
      final bool? secondDialogConfirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('❗️ Are you really sure?'),
            content: const Text(
                '💥 Are you really sure you want to lose all your data? There is no going back!'),
            actions: <Widget>[
              TextButton(
                child: const Text('No'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Yes'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (secondDialogConfirmed == true) {
        await _dbHelper.clearDatabase();

        // Show success SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Database cleared successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        setState(() {}); // Refresh the table after clearing the database
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              await _showConfirmationDialogs();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _getExercises(), // Fetch fresh data
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final exercises = snapshot.data!;
              return DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Exercise')),
                  DataColumn(label: Text('Weight')),
                  DataColumn(label: Text('Reps')),
                  DataColumn(label: Text('Sets')),
                  DataColumn(label: Text('Timestamp')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: exercises.map((exercise) {
                  return DataRow(cells: [
                    DataCell(Text(exercise['id'].toString())),
                    DataCell(Text(exercise['exercise'])),
                    DataCell(Text(exercise['weight'])),
                    DataCell(Text(exercise['reps'].toString())),
                    DataCell(Text(exercise['sets'].toString())),
                    DataCell(Text(exercise['timestamp'])),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _showEditDialog(exercise);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await _deleteExercise(exercise['id']);
                            },
                          ),
                        ],
                      ),
                    ),
                  ]);
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }
}
