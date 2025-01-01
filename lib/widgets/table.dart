import 'package:flutter/material.dart';
import '../core/database.dart';
import 'exercise_edit_dialog.dart';
import 'fitness_edit_dialog.dart';
import 'package:intl/intl.dart';

class ClampingScrollController extends ScrollController {
  @override
  void jumpTo(double value) {
    final double maxScrollExtent = position.maxScrollExtent;
    final double minScrollExtent = position.minScrollExtent;
    final double clampedValue = value.clamp(minScrollExtent, maxScrollExtent);
    super.jumpTo(clampedValue);
  }

  @override
  Future<void> animateTo(double offset, {
    required Duration duration,
    required Curve curve,
  }) {
    final double maxScrollExtent = position.maxScrollExtent;
    final double minScrollExtent = position.minScrollExtent;
    final double clampedOffset = offset.clamp(minScrollExtent, maxScrollExtent);
    return super.animateTo(clampedOffset, duration: duration, curve: curve);
  }
}

class TableTab extends StatefulWidget {
  final bool isKg;

  TableTab({required this.isKg});

  @override
  _TableTabState createState() => _TableTabState();
}

class _TableTabState extends State<TableTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String _selectedTable = 'exercises';
  final GlobalKey<_TableWidgetState> _tableWidgetKey =
      GlobalKey<_TableWidgetState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Table View'),
        actions: [
          DropdownButton<String>(
            value: _selectedTable,
            items: const [
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
                _tableWidgetKey.currentState?._loadData(_selectedTable);
              });
            },
          ),
        ],
      ),
      body: TableWidget(
        key: _tableWidgetKey,
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
    required Key key,
    required this.selectedTable,
    required this.isKg,
    required this.dbHelper,
  }) : super(key: key);

  @override
  _TableWidgetState createState() => _TableWidgetState();
}

class _TableWidgetState extends State<TableWidget> {
  String _sortColumn = 'timestamp';
  bool _sortAscending = false;
  List<Map<String, dynamic>> _data = [];
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ClampingScrollController();
  int _offset = 0;
  final int _limit = 20;
  bool _isLoading = false;
  bool _hasMoreData = true;
  bool _isSyncing = false;
  ScrollController? _activeRowController;

  @override
  void initState() {
    super.initState();
    _verticalScrollController.addListener(_onScroll);
    _horizontalScrollController.addListener(_onHorizontalScroll);
    _loadData(widget.selectedTable);
  }

  @override
  void dispose() {
    _verticalScrollController.removeListener(_onScroll);
    _verticalScrollController.dispose();
    _horizontalScrollController.removeListener(_onHorizontalScroll);
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData(String selectedTable) async {
    setState(() {
      _data = [];
      _offset = 0;
      _hasMoreData = true;
    });
    await _loadNextChunk();
  }

  Future<void> _loadNextChunk() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    List<Map<String, dynamic>> data;
    if (widget.selectedTable == 'exercises') {
      data = await widget.dbHelper.getExercisesChunk(
        sortColumn: _sortColumn,
        ascending: _sortAscending,
        offset: _offset,
        limit: _limit,
      );
    } else if (widget.selectedTable == 'fitness') {
      data = await widget.dbHelper.getFitnessDataChunk(
        sortColumn: _sortColumn,
        ascending: _sortAscending,
        offset: _offset,
        limit: _limit,
      );
    } else {
      data = [];
    }

    setState(() {
      _data.addAll(data);
      _offset += _limit;
      _isLoading = false;
      if (data.length < _limit) {
        _hasMoreData = false;
      }
    });
  }

  void _onScroll() {
    if (_verticalScrollController.position.pixels >=
        _verticalScrollController.position.maxScrollExtent - 200) {
      _loadNextChunk();
    }
  }

  void _onHorizontalScroll() {
    if (_isSyncing) return;
    setState(() {
      _isSyncing = true;
    });
    for (var rowController in _rowControllers) {
      if (rowController != _activeRowController && rowController.hasClients) {
        rowController.jumpTo(_horizontalScrollController.offset);
      }
    }
    setState(() {
      _isSyncing = false;
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
      _loadData(widget.selectedTable);
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
        _loadData(widget.selectedTable);
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
        _loadData(widget.selectedTable);
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
    // Exit early if there is no data to sort
    if (_data.isEmpty) {
      return;
    }

    column = column.toLowerCase();
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }

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
    final title = column == 'Weight' ? weightLabel : column;

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
              if (_sortColumn == column.toLowerCase())
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

  final List<ScrollController> _rowControllers = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.axis == Axis.horizontal && !_isSyncing) {
              _horizontalScrollController.jumpTo(scrollInfo.metrics.pixels);
            }
            return false;
          },
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _horizontalScrollController,
            physics: NeverScrollableScrollPhysics(), // disable manual scrolling of header
            child: Table(
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
                      1: FixedColumnWidth(90.0),
                      2: FixedColumnWidth(70.0),
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
                          _buildHeader('Exercise'),
                          _buildHeader('Weight'),
                          _buildHeader('Reps'),
                          _buildHeader('Sets'),
                          _buildHeader('Timestamp'),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Actions',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ]
                      : [
                          _buildHeader('Weight'),
                          _buildHeader('Height'),
                          _buildHeader('Age'),
                          _buildHeader('Timestamp'),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Actions',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _verticalScrollController,
            physics: BouncingScrollPhysics(),
            itemCount: _data.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _data.length) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final item = _data[index];
              final rowController = ClampingScrollController();
              _rowControllers.add(rowController);

              return NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo.metrics.axis == Axis.horizontal && !_isSyncing) {
                    _activeRowController = rowController;
                    _horizontalScrollController.jumpTo(scrollInfo.metrics.pixels);
                    _activeRowController = null;
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: rowController,
                  physics: ClampingScrollPhysics(),
                  child: Table(
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
                            1: FixedColumnWidth(90.0),
                            2: FixedColumnWidth(70.0),
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
                                TableCell(
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 14.0),
                                        child: Text(item['exercise'] ?? ''))),
                                TableCell(
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 14.0),
                                        child: Text(_formatWeight(
                                            item['weight'] ?? '')))),
                                TableCell(
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 14.0),
                                        child: Text(
                                            (item['reps'] ?? 0).toString()))),
                                TableCell(
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 14.0),
                                        child: Text(
                                            (item['sets'] ?? 0).toString()))),
                                TableCell(
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 14.0),
                                        child: Text(_formatDate(
                                            item['timestamp'] ?? '')))),
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
                                        child: Text(_formatWeight(
                                            item['weight'] ?? '')))),
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
                                        child: Text(
                                            (item['age'] ?? 0).toString()))),
                                TableCell(
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 14.0),
                                        child: Text(_formatDate(
                                            item['timestamp'] ?? '')))),
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}