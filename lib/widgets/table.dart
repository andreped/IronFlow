import 'package:flutter/material.dart';
import '../core/database.dart';
import 'exercise_edit_dialog.dart';
import 'fitness_edit_dialog.dart';
import 'package:intl/intl.dart';

class TableTab extends StatefulWidget {
  final bool isKg;

  TableTab({required this.isKg});

  @override
  _TableTabState createState() => _TableTabState();
}

class _TableTabState extends State<TableTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String _selectedTable = 'exercises';
  String _sortColumn = 'timestamp';
  bool _sortAscending = false;

  Map<String, List<Map<String, dynamic>>> _cache = {};
  late Future<List<Map<String, dynamic>>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _getData();
  }

  Future<List<Map<String, dynamic>>> _getData() async {
    final cacheKey = '$_selectedTable-$_sortColumn-$_sortAscending';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    List<Map<String, dynamic>> data;
    if (_selectedTable == 'exercises') {
      data = await _dbHelper.getExercises(
        sortColumn: _sortColumn,
        ascending: _sortAscending,
      );
    } else if (_selectedTable == 'fitness') {
      data = await _dbHelper.getFitnessData(
        sortColumn: _sortColumn,
        ascending: _sortAscending,
      );
    } else {
      data = [];
    }

    _cache[cacheKey] = data;
    return data;
  }

  Future<void> _deleteRow(String table, int id) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content:
              const Text('🚨 Are you sure you want to delete this record?'),
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
      await _dbHelper.deleteRowItem(table, id);
      _cache.clear(); // Clear cache after deletion
      setState(() {
        _dataFuture = _getData();
      });
    }
  }

  void _showEditDialog(Map<String, dynamic> exercise) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ExerciseEditDialog(
          exerciseData: exercise,
          isKg: widget.isKg,
        );
      },
    ).then((result) async {
      if (result != null) {
        final weight = widget.isKg
            ? result['weight']
            : (double.parse(result['weight']) * 2.20462).toStringAsFixed(2);

        await _dbHelper.updateExercise(
          id: result['id'],
          exercise: result['exercise'],
          weight: weight,
          reps: result['reps'],
          sets: result['sets'],
          timestamp: result['timestamp'],
        );
        _cache.clear(); // Clear cache after update
        setState(() {
          _dataFuture = _getData();
        });
      }
    });
  }

  void _showFitnessEditDialog(Map<String, dynamic> fitness) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FitnessEditDialog(
          fitnessData: fitness,
          isKg: widget.isKg,
        );
      },
    ).then((result) async {
      if (result != null) {
        final weight = widget.isKg
            ? result['weight']
            : (double.parse(result['weight']) * 2.20462).toStringAsFixed(2);

        await _dbHelper.updateFitness(
          id: result['id'],
          weight: weight,
          height: result['height'],
          age: result['age'],
          timestamp: result['timestamp'],
        );
        _cache.clear(); // Clear cache after update
        setState(() {
          _dataFuture = _getData();
        });
      }
    });
  }

  String _formatDate(String timestamp) {
    final DateTime dateTime = DateTime.parse(timestamp);
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    return dateFormat.format(dateTime);
  }

  String _formatWeight(String weight) {
    final double weightInKg = double.parse(weight);
    return widget.isKg
        ? weightInKg.toStringAsFixed(2)
        : (weightInKg * 2.20462).toStringAsFixed(2);
  }

  void _sortTable(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _cache.clear(); // Clear cache after sorting
      _dataFuture = _getData();
    });
  }

  TableCell _buildHeader(String column) {
    final weightLabel = widget.isKg ? 'Weight [kg]' : 'Weight [lbs]';
    final title = column == 'weight' ? weightLabel : column;

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
                  color: Theme.of(context).colorScheme.secondary,
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
        title: Text('Table View'),
        actions: [
          DropdownButton<String>(
            value: _selectedTable,
            items: [
              DropdownMenuItem(
                value: 'exercises',
                child: Text('Exercises'),
              ),
              DropdownMenuItem(
                value: 'fitness',
                child: Text('Fitness'),
              ),
            ],
            onChanged: (String? newValue) {
              setState(() {
                _selectedTable = newValue!;
                _cache.clear(); // Clear cache after table change
                _dataFuture = _getData();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final data = snapshot.data ?? [];

              if (_selectedTable == 'exercises') {
                return Table(
                  columnWidths: {
                    0: FixedColumnWidth(150.0),
                    1: FixedColumnWidth(120.0),
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
                        _buildHeader('exercise'),
                        _buildHeader('weight'),
                        _buildHeader('reps'),
                        _buildHeader('sets'),
                        _buildHeader('timestamp'),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Actions',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    for (var exercise in data)
                      TableRow(
                        children: [
                          TableCell(
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 14.0),
                                  child: Text(exercise['exercise'] ?? ''))),
                          TableCell(
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 14.0),
                                  child: Text(_formatWeight(
                                      exercise['weight'] ?? '')))),
                          TableCell(
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 14.0),
                                  child: Text(
                                      (exercise['reps'] ?? 0).toString()))),
                          TableCell(
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 14.0),
                                  child: Text(
                                      (exercise['sets'] ?? 0).toString()))),
                          TableCell(
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 14.0),
                                  child: Text(_formatDate(
                                      exercise['timestamp'] ?? '')))),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 0.0),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit,
                                        size: 18.0,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary),
                                    onPressed: () {
                                      _showEditDialog(exercise);
                                    },
                                  ),
                                  SizedBox(width: 0.0),
                                  IconButton(
                                    icon: Icon(Icons.delete,
                                        size: 18.0,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary),
                                    onPressed: () async {
                                      await _deleteRow(
                                          'exercises', exercise['id'] ?? 0);
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
              } else if (_selectedTable == 'fitness') {
                return Table(
                  columnWidths: {
                    0: FixedColumnWidth(120.0),
                    1: FixedColumnWidth(80.0),
                    2: FixedColumnWidth(60.0),
                    3: FixedColumnWidth(120.0),
                    4: FixedColumnWidth(130.0),
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
                        _buildHeader('weight'),
                        _buildHeader('height'),
                        _buildHeader('age'),
                        _buildHeader('timestamp'),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Actions',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    if (data.isEmpty)
                      TableRow(
                        children: [
                          for (int i = 0; i < 5; i++)
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 14.0),
                                child: Text(''),
                              ),
                            ),
                        ],
                      )
                    else
                      for (var record in data)
                        TableRow(
                          children: [
                            TableCell(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 14.0),
                                    child: Text(
                                        (record['weight'] ?? 0).toString()))),
                            TableCell(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 14.0),
                                    child: Text(
                                        (record['height'] ?? 0).toString()))),
                            TableCell(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 14.0),
                                    child:
                                        Text((record['age'] ?? 0).toString()))),
                            TableCell(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 14.0),
                                    child: Text(
                                        _formatDate((record['timestamp']) ?? 0)
                                            .toString()))),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 0.0),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit,
                                          size: 18.0,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary),
                                      onPressed: () {
                                        _showFitnessEditDialog(record);
                                      },
                                    ),
                                    SizedBox(width: 0.0),
                                    IconButton(
                                      icon: Icon(Icons.delete,
                                          size: 18.0,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary),
                                      onPressed: () async {
                                        await _deleteRow(
                                            'fitness', record['id'] ?? 0);
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
              } else {
                return Center(child: Text('Unknown table selected.'));
              }
            },
          ),
        ),
      ),
    );
  }
}
