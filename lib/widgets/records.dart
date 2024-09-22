import 'package:flutter/material.dart';
import '../core/database.dart';
import '../core/theme.dart';

class RecordsTab extends StatefulWidget {
  final bool isKg;

  const RecordsTab({Key? key, required this.isKg}) : super(key: key);

  @override
  _RecordsTabState createState() => _RecordsTabState();
}

class _RecordsTabState extends State<RecordsTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _maxWeights = [];
  bool _isSortedByWeight = true;
  bool _isAscending = false;
  bool _isLoading = true; // Track loading state
  String? _errorMessage; // Track error message

  Future<void> _fetchAndSortRecords() async {
    setState(() {
      _isLoading = true; // Start loading
      _errorMessage = null; // Clear previous errors
    });

    try {
      final data = await _dbHelper.getMaxWeightsForExercises();
      setState(() {
        _maxWeights = data;
        _sortRecords();
        _isLoading = false; // Finished loading
      });
    } catch (e) {
      setState(() {
        _isLoading = false; // Finished loading
        _errorMessage =
            'Failed to load data. Please try again later.'; // Set error message
      });
      print('Error fetching records: $e'); // Log error for debugging
    }
  }

  void _sortRecords() {
    // Ensure that _maxWeights is a modifiable list
    _maxWeights = List<Map<String, dynamic>>.from(_maxWeights);

    if (_isSortedByWeight) {
      _maxWeights.sort((a, b) {
        final maxWeightA =
            a['weight'] != null ? double.parse(a['weight'].toString()) : 0.0;
        final maxWeightB =
            b['weight'] != null ? double.parse(b['weight'].toString()) : 0.0;
        final repsA = a['reps'] != null ? int.parse(a['reps'].toString()) : 0;
        final repsB = b['reps'] != null ? int.parse(b['reps'].toString()) : 0;

        if (maxWeightA == maxWeightB) {
          // If weights are equal, sort by reps
          return _isAscending ? repsA.compareTo(repsB) : repsB.compareTo(repsA);
        }
        return _isAscending
            ? maxWeightA.compareTo(maxWeightB)
            : maxWeightB.compareTo(maxWeightA);
      });
    } else {
      _maxWeights.sort((a, b) {
        return _isAscending
            ? (a['exercise'] ?? '').compareTo(b['exercise'] ?? '')
            : (b['exercise'] ?? '').compareTo(a['exercise'] ?? '');
      });
    }
  }

  void _toggleSorting(bool isWeightColumn) {
    setState(() {
      if (_isSortedByWeight == isWeightColumn) {
        _isAscending = !_isAscending;
      } else {
        _isSortedByWeight = isWeightColumn;
        _isAscending = true;
      }
      _sortRecords();
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchAndSortRecords();
  }

  double _convertWeight(double weightInKg) {
    return widget.isKg ? weightInKg : weightInKg * 2.20462;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final arrowColor = isDarkMode ? Colors.purple : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('High Scores'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Text(_errorMessage!,
                        style: TextStyle(color: Colors.red)),
                  )
                : _maxWeights.isEmpty
                    ? const Center(child: Text('No data available'))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: DataTable(
                                columnSpacing: 32.0,
                                dataRowHeight:
                                    65.0, // Set the height of each row
                                columns: [
                                  DataColumn(
                                    label: Expanded(
                                      child: InkWell(
                                        onTap: () => _toggleSorting(false),
                                        child: Row(
                                          children: [
                                            Text('Exercise'),
                                            if (!_isSortedByWeight)
                                              Icon(
                                                _isAscending
                                                    ? Icons.arrow_upward
                                                    : Icons.arrow_downward,
                                                size: 16.0,
                                                color: arrowColor,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: InkWell(
                                        onTap: () => _toggleSorting(true),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                                'Weight [${widget.isKg ? 'kg' : 'lbs'}]'),
                                            if (_isSortedByWeight)
                                              Icon(
                                                _isAscending
                                                    ? Icons.arrow_upward
                                                    : Icons.arrow_downward,
                                                size: 16.0,
                                                color: arrowColor,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                rows: _maxWeights.map((record) {
                                  final exercise = record['exercise'] as String;
                                  final weight = record['weight'];
                                  final reps = record['reps'];
                                  final displayWeight = _convertWeight(
                                      weight is String
                                          ? double.parse(weight)
                                          : weight);

                                  return DataRow(cells: [
                                    DataCell(Text(exercise)),
                                    DataCell(
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          '${displayWeight.toStringAsFixed(1)} x $reps reps',
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
