import 'package:flutter/material.dart';
import '../core/database.dart';
import 'package:logging/logging.dart';
import '../components/search/search_bar.dart' as custom;
import '../widgets/records/records_table.dart';
import '../repositories/records_repository.dart';

class RecordsTab extends StatefulWidget {
  final bool isKg;
  final bool bodyweightEnabledGlobal;

  const RecordsTab(
      {super.key, required this.isKg, required this.bodyweightEnabledGlobal});

  @override
  RecordsTabState createState() => RecordsTabState();
}

class RecordsTabState extends State<RecordsTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _maxWeights = [];
  List<Map<String, dynamic>> _filteredWeights = [];
  bool _isSortedByWeight = true;
  bool _isAscending = false;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  Future<void> _fetchAndSortRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data =
          await RecordsRepository(_dbHelper).getMaxWeightsForExercises();
      setState(() {
        _maxWeights = data;
        _filteredWeights = data;
        _sortRecords();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data. Please try again later.';
      });
      Logger('RecordsLogger').severe('Error fetching records: $e');
    }
  }

  void _sortRecords() {
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
            ? custom.SearchBar(
                searchController: _searchController,
                onChanged: _filterRecords,
                textColor: textColor,
                onClear: () {
                  _searchController.clear();
                  _filterRecords('');
                },
              )
            : const Text('Records'),
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
                        style: const TextStyle(color: Colors.red)),
                  )
                : _filteredWeights.isEmpty
                    ? const Center(child: Text('No data available'))
                    : RecordsTable(
                        filteredWeights: _filteredWeights,
                        isSortedByWeight: _isSortedByWeight,
                        isAscending: _isAscending,
                        arrowColor: arrowColor,
                        toggleSorting: _toggleSorting,
                        convertWeight: _convertWeight,
                        isKg: widget.isKg,
                      ),
      ),
    );
  }
}
