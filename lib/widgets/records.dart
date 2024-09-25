import 'package:flutter/material.dart';
import '../core/database.dart';
import '../core/theme.dart';

class RecordsTab extends StatefulWidget {
  final bool isKg;
  final bool bodyweightEnabledGlobal;

  const RecordsTab({Key? key, required this.isKg, required this.bodyweightEnabledGlobal}) : super(key: key);

  @override
  _RecordsTabState createState() => _RecordsTabState();
}

class _RecordsTabState extends State<RecordsTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _maxWeights = [];
  List<Map<String, dynamic>> _filteredWeights = [];
  bool _isSortedByWeight = true;
  bool _isAscending = false;
  bool _isLoading = true; // Track loading state
  String? _errorMessage; // Track error message
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  Future<void> _fetchAndSortRecords() async {
    setState(() {
      _isLoading = true; // Start loading
      _errorMessage = null; // Clear previous errors
    });

    try {
      final data = await _dbHelper.getMaxWeightsForExercises();
      setState(() {
        _maxWeights = data;
        _filteredWeights = data;
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
    // Ensure that _filteredWeights is a modifiable list
    _filteredWeights = List<Map<String, dynamic>>.from(_filteredWeights);

    if (_isSortedByWeight) {
      _filteredWeights.sort((a, b) {
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
      _filteredWeights.sort((a, b) {
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

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _filteredWeights = _maxWeights;
    });
  }

  void _filterRecords(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredWeights = _maxWeights;
      } else {
        _filteredWeights = _maxWeights
            .where((record) => record['exercise']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
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
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search for exercises...',
                  hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: textColor),
                onChanged: _filterRecords,
              )
            : Text('Records'),
        leading: _isSearching
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
                onPressed: _stopSearch,
              )
            : null,
        actions: _isSearching
            ? [
                IconButton(
                  icon: Icon(Icons.clear, color: theme.iconTheme.color),
                  onPressed: () {
                    _searchController.clear();
                    _filterRecords('');
                  },
                ),
              ]
            : [
                IconButton(
                  icon: Icon(Icons.search, color: theme.iconTheme.color),
                  onPressed: _startSearch,
                ),
              ],
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
                : _filteredWeights.isEmpty
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
                                columnSpacing: 64.0, // Increase column spacing
                                dataRowHeight:
                                    65.0, // Set the height of each row
                                columns: [
                                  DataColumn(
                                    label: Expanded(
                                      child: GestureDetector(
                                        onTap: () => _toggleSorting(false),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Text('Exercise',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            if (!_isSortedByWeight)
                                              Row(
                                                children: [
                                                  SizedBox(width: 4.0),
                                                  Icon(
                                                    _isAscending
                                                        ? Icons.arrow_upward
                                                        : Icons.arrow_downward,
                                                    size: 16.0,
                                                    color: arrowColor,
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: GestureDetector(
                                        onTap: () => _toggleSorting(true),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                                'Weight [${widget.isKg ? 'kg' : 'lbs'}]',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            if (_isSortedByWeight)
                                              Row(
                                                children: [
                                                  SizedBox(width: 4.0),
                                                  Icon(
                                                    _isAscending
                                                        ? Icons.arrow_upward
                                                        : Icons.arrow_downward,
                                                    size: 16.0,
                                                    color: arrowColor,
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                rows: _filteredWeights.map((record) {
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
                                      Container(
                                        alignment: Alignment.centerRight,
                                        padding: EdgeInsets.only(right: 16.0),
                                        child: Text(
                                          '${displayWeight.toStringAsFixed(1)} x $reps reps',
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
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
