import 'package:flutter/material.dart';
import '../core/database.dart';
import '../widgets/exercise_edit_dialog.dart';
import 'package:intl/intl.dart'; // Add this import

class TableTab extends StatefulWidget {
  @override
  _TableTabState createState() => _TableTabState();
}

class _TableTabState extends State<TableTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String _sortColumn = 'timestamp';
  bool _sortAscending = false;

  Future<List<Map<String, dynamic>>> _getExercises() async {
    return await _dbHelper.getExercises(
      sortColumn: _sortColumn,
      ascending: _sortAscending,
    );
  }

  Future<void> _deleteExercise(int id) async {
    // Confirm deletion
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
      await _dbHelper.deleteExercise(id);
      setState(() {});
    }
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

  String _formatDate(String timestamp) {
    final DateTime dateTime = DateTime.parse(timestamp);
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    return dateFormat.format(dateTime);
  }

  void _sortTable(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  TableCell _buildHeader(String title, String column) {
    return TableCell(
      child: GestureDetector(
        onTap: () => _sortTable(column),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (_sortColumn == column)
                Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Data'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _getExercises(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final exercises = snapshot.data!;
              return Table(
                columnWidths: {
                  0: FixedColumnWidth(150.0),
                  1: FixedColumnWidth(90.0),
                  2: FixedColumnWidth(70.0),
                  3: FixedColumnWidth(70.0),
                  4: FixedColumnWidth(120.0),
                  5: FixedColumnWidth(130.0),
                },
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: Colors.grey.shade300,
                    width: 0.5,
                  ),
                  verticalInside: BorderSide.none,
                  top: BorderSide.none,
                  bottom: BorderSide.none,
                ),
                children: [
                  TableRow(
                    children: [
                      _buildHeader('Exercise', 'exercise'),
                      _buildHeader('Weight', 'weight'),
                      _buildHeader('Reps', 'reps'),
                      _buildHeader('Sets', 'sets'),
                      _buildHeader('Timestamp', 'timestamp'),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Actions',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  for (var exercise in exercises)
                    TableRow(
                      children: [
                        TableCell(
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 14.0),
                                child: Text(exercise['exercise']))),
                        TableCell(
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 14.0),
                                child: Text(exercise['weight']))),
                        TableCell(
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 14.0),
                                child: Text(exercise['reps'].toString()))),
                        TableCell(
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 14.0),
                                child: Text(exercise['sets'].toString()))),
                        TableCell(
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 14.0),
                                child:
                                    Text(_formatDate(exercise['timestamp'])))),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 0.0),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, size: 18.0),
                                  onPressed: () {
                                    _showEditDialog(exercise);
                                  },
                                ),
                                SizedBox(width: 0.0),
                                IconButton(
                                  icon: Icon(Icons.delete, size: 18.0),
                                  onPressed: () async {
                                    await _deleteExercise(exercise['id']);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
