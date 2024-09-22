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
              });
            },
          ),
        ],
      ),
      body: TableWidget(
        selectedTable: _selectedTable,
        isKg: widget.isKg,
        dbHelper: _dbHelper,
      ),
    );
  }
}

class TableWidget extends StatefulWidget {
  final String selectedTable;
  final bool isKg;
  final DatabaseHelper dbHelper;

  TableWidget({
    required this.selectedTable,
    required this.isKg,
    required this.dbHelper,
  });

  @override
  _TableWidgetState createState() => _TableWidgetState();
}

class _TableWidgetState extends State<TableWidget> {
  String _sortColumn = 'timestamp';
  bool _sortAscending = false;

  Map<String, List<Map<String, dynamic>>> _cache = {};
  List<Map<String, dynamic>> _data = []; // Initialize with an empty list
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final GlobalKey _scrollKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cacheKey = '${widget.selectedTable}-$_sortColumn-$_sortAscending';
    if (_cache.containsKey(cacheKey)) {
      setState(() {
        _data = List<Map<String, dynamic>>.from(_cache[cacheKey]!);
      });
      return;
    }

    List<Map<String, dynamic>> data;
    if (widget.selectedTable == 'exercises') {
      data = await widget.dbHelper.getExercises(
        sortColumn: _sortColumn,
        ascending: _sortAscending,
      );
    } else if (widget.selectedTable == 'fitness') {
      data = await widget.dbHelper.getFitnessData(
        sortColumn: _sortColumn,
        ascending: _sortAscending,
      );
    } else {
      data = [];
    }

    setState(() {
      _data = List<Map<String, dynamic>>.from(data); // Create a mutable copy
      _cache[cacheKey] = data;
    });
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
      await widget.dbHelper.deleteRowItem(table, id);
      _cache.clear(); // Clear cache after deletion
      _loadData();
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

        await widget.dbHelper.updateExercise(
          id: result['id'],
          exercise: result['exercise'],
          weight: weight,
          reps: result['reps'],
          sets: result['sets'],
          timestamp: result['timestamp'],
        );
        _cache.clear(); // Clear cache after update
        _loadData();
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

        await widget.dbHelper.updateFitness(
          id: result['id'],
          weight: weight,
          height: result['height'],
          age: result['age'],
          timestamp: result['timestamp'],
        );
        _cache.clear(); // Clear cache after update
        _loadData();
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

      // Perform the sorting on the data
      _data.sort((a, b) {
        int compareResult;
        if (column == 'exercise' || column == 'timestamp') {
          compareResult = a[column].compareTo(b[column]);
        } else {
          compareResult = double.parse(a[column].toString())
              .compareTo(double.parse(b[column].toString()));
        }
        return _sortAscending ? compareResult : -compareResult;
      });
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
    if (_data.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      key: _scrollKey,
      controller: _verticalScrollController,
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            Table(
              columnWidths: widget.selectedTable == 'exercises'
                  ? {
                      0: FixedColumnWidth(150.0),
                      1: FixedColumnWidth(120.0),
                      2: FixedColumnWidth(70.0),
                      3: FixedColumnWidth(70.0),
                      4: FixedColumnWidth(120.0),
                      5: FixedColumnWidth(130.0),
                    }
                  : {
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
                  children: widget.selectedTable == 'exercises'
                      ? [
                          _buildHeader('exercise'),
                          _buildHeader('weight'),
                          _buildHeader('reps'),
                          _buildHeader('sets'),
                          _buildHeader('timestamp'),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Actions',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ]
                      : [
                          _buildHeader('weight'),
                          _buildHeader('height'),
                          _buildHeader('age'),
                          _buildHeader('timestamp'),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Actions',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                ),
                for (var item in _data)
                  TableRow(
                    children: widget.selectedTable == 'exercises'
                        ? [
                            TableCell(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 14.0),
                                    child: Text(item['exercise'] ?? ''))),
                            TableCell(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 14.0),
                                    child: Text(
                                        _formatWeight(item['weight'] ?? '')))),
                            TableCell(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 14.0),
                                    child:
                                        Text((item['reps'] ?? 0).toString()))),
                            TableCell(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 14.0),
                                    child:
                                        Text((item['sets'] ?? 0).toString()))),
                            TableCell(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 14.0),
                                    child: Text(
                                        _formatDate(item['timestamp'] ?? '')))),
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
                                        _showEditDialog(item);
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
                                            'exercises', item['id'] ?? 0);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]
                        : [
                            TableCell(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 14.0),
                                    child: Text(
                                        (item['weight'] ?? 0).toString()))),
                            TableCell(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 14.0),
                                    child: Text(
                                        (item['height'] ?? 0).toString()))),
                            TableCell(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 14.0),
                                    child:
                                        Text((item['age'] ?? 0).toString()))),
                            TableCell(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 14.0),
                                    child: Text(
                                        _formatDate(item['timestamp'] ?? '')))),
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
                                        _showFitnessEditDialog(item);
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
                                            'fitness', item['id'] ?? 0);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
