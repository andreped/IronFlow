import 'package:flutter/material.dart';
import '../../core/database.dart';
import '../../core/controllers.dart';
import '../../logic/data/data_fetching.dart';
import '../../core/scroll_handlers.dart';
import '../edit_dialog/edit_dialogs.dart';
import '../../components/table/table_header.dart';
import 'table_row_exercises.dart';
import 'table_row_fitness.dart';

class TableWidget extends StatefulWidget {
  final String selectedTable;
  final bool isKg;
  final DatabaseHelper dbHelper;

  const TableWidget({
    required Key key,
    required this.selectedTable,
    required this.isKg,
    required this.dbHelper,
  }) : super(key: key);

  @override
  TableWidgetState createState() => TableWidgetState();
}

class TableWidgetState extends State<TableWidget> {
  String _sortColumn = 'Timestamp';
  bool _sortAscending = false;
  List<Map<String, dynamic>> _data = [];
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController =
      ClampingScrollController();
  int _offset = 0;
  final int _limit = 50;
  bool _isLoading = false;
  bool _hasMoreData = true;
  final bool _isSyncing = false;
  ScrollController? _activeRowController;
  final List<ScrollController> _rowControllers = [];
  String _searchQuery = ''; // Add search query state

  @override
  void initState() {
    super.initState();
    _verticalScrollController
        .addListener(() => onScroll(_verticalScrollController, _loadNextChunk));
    _horizontalScrollController.addListener(() {
      onHorizontalScroll(_horizontalScrollController, _rowControllers,
          _isSyncing, _activeRowController);
    });

    // Add listener to sync horizontal scroll position on vertical scroll
    _verticalScrollController.addListener(() {
      for (final rowController in _rowControllers) {
        if (rowController.hasClients) {
          rowController.jumpTo(_horizontalScrollController.position.pixels);
        }
      }
    });

    loadData(widget.selectedTable);
  }

  @override
  void didUpdateWidget(TableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTable != oldWidget.selectedTable) {
      loadData(widget.selectedTable);
    }
  }

  @override
  void dispose() {
    _verticalScrollController.removeListener(
        () => onScroll(_verticalScrollController, _loadNextChunk));
    _verticalScrollController.dispose();
    _horizontalScrollController.removeListener(() => onHorizontalScroll(
        _horizontalScrollController,
        _rowControllers,
        _isSyncing,
        _activeRowController));
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> loadData(String selectedTable) async {
    setState(() {
      _data = [];
      _offset = 0;
      _hasMoreData = true;
      _sortColumn = 'Timestamp';
      _sortAscending = false;
    });
    await _loadNextChunk();
  }

  Future<void> _loadNextChunk() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    List<Map<String, dynamic>> newData = await loadNextChunk(
      widget.selectedTable,
      _offset,
      _limit,
      _sortColumn,
      _sortAscending,
      widget.dbHelper,
      _searchQuery, // Pass the search query
    );

    setState(() {
      _data.addAll(newData);
      _offset += newData.length;
      _isLoading = false;
      if (newData.length < _limit) {
        _hasMoreData = false;
      }

      // Add new row controllers and set their scroll position immediately
      for (int i = _data.length - newData.length; i < _data.length; i++) {
        final rowController = ClampingScrollController();
        _rowControllers.add(rowController);
        rowController.jumpTo(_horizontalScrollController.position.pixels);
      }
    });
  }

  Future<void> _deleteRow(String table, int id) async {
    await deleteRow(
        table, id, context, widget.dbHelper, loadData, widget.selectedTable);
  }

  void _showEditDialog(Map<String, dynamic> exercise) {
    showEditDialog(context, exercise, widget.isKg, widget.dbHelper, loadData,
        widget.selectedTable);
  }

  void _showFitnessEditDialog(Map<String, dynamic> fitness) {
    showFitnessEditDialog(context, fitness, widget.isKg, widget.dbHelper,
        loadData, widget.selectedTable);
  }

  void _sortTable(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }

      _data = [];
      _offset = 0;
      _hasMoreData = true;

      _loadNextChunk();
    });
  }

  void filterData(String query) {
    setState(() {
      _searchQuery = query;
      _data = [];
      _offset = 0;
      _hasMoreData = true;
    });
    _loadNextChunk();
  }

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
            physics:
                const NeverScrollableScrollPhysics(), // disable manual scrolling of header
            child: Table(
              columnWidths: widget.selectedTable == 'exercises'
                  ? {
                      0: const FixedColumnWidth(150.0),
                      1: const FixedColumnWidth(120.0),
                      2: const FixedColumnWidth(70.0),
                      3: const FixedColumnWidth(70.0),
                      4: const FixedColumnWidth(120.0),
                      5: const FixedColumnWidth(130.0),
                    }
                  : {
                      0: const FixedColumnWidth(120.0),
                      1: const FixedColumnWidth(90.0),
                      2: const FixedColumnWidth(70.0),
                      3: const FixedColumnWidth(120.0),
                      4: const FixedColumnWidth(130.0),
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
                          tableHeader('Exercise', _sortColumn, _sortAscending,
                              _sortTable, context, widget.isKg),
                          tableHeader('Weight', _sortColumn, _sortAscending,
                              _sortTable, context, widget.isKg),
                          tableHeader('Reps', _sortColumn, _sortAscending,
                              _sortTable, context, widget.isKg),
                          tableHeader('Sets', _sortColumn, _sortAscending,
                              _sortTable, context, widget.isKg),
                          tableHeader('Timestamp', _sortColumn, _sortAscending,
                              _sortTable, context, widget.isKg),
                          const TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Actions',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ]
                      : [
                          tableHeader('Weight', _sortColumn, _sortAscending,
                              _sortTable, context, widget.isKg),
                          tableHeader('Height', _sortColumn, _sortAscending,
                              _sortTable, context, widget.isKg),
                          tableHeader('Age', _sortColumn, _sortAscending,
                              _sortTable, context, widget.isKg),
                          tableHeader('Timestamp', _sortColumn, _sortAscending,
                              _sortTable, context, widget.isKg),
                          const TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Actions',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
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
            physics: const BouncingScrollPhysics(),
            itemCount: _data.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _data.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final item = _data[index];
              final rowController = ClampingScrollController();
              _rowControllers.add(rowController);

              return NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo.metrics.axis == Axis.horizontal &&
                      !_isSyncing) {
                    _activeRowController = rowController;
                    _horizontalScrollController
                        .jumpTo(scrollInfo.metrics.pixels);
                    _activeRowController = null;
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: rowController,
                  physics: const ClampingScrollPhysics(),
                  child: widget.selectedTable == 'exercises'
                      ? TableRowExercises(
                          item: item,
                          isKg: widget.isKg,
                          showEditDialog: _showEditDialog,
                          showFitnessEditDialog: _showFitnessEditDialog,
                          deleteRow: _deleteRow,
                        )
                      : TableRowFitness(
                          item: item,
                          isKg: widget.isKg,
                          showEditDialog: _showEditDialog,
                          showFitnessEditDialog: _showFitnessEditDialog,
                          deleteRow: _deleteRow,
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
