import 'package:flutter/material.dart';
import '../core/database.dart';
import '../core/theme.dart'; // Import the theme for isKg

class RecordsTab extends StatefulWidget {
  final bool isKg;

  const RecordsTab({Key? key, required this.isKg}) : super(key: key);

  @override
  _RecordsTabState createState() => _RecordsTabState();
}

class _RecordsTabState extends State<RecordsTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _maxWeights = [];
  bool _isSortedByWeight = false;
  bool _isAscending = true;
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
        if (maxWeightA == maxWeightB) {
          // If weights are equal, sort alphabetically by exercise name
          return (a['exercise'] ?? '').compareTo(b['exercise'] ?? '');
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

  void _toggleSorting() {
    setState(() {
      _isSortedByWeight = !_isSortedByWeight;
      _sortRecords();
    });
  }

  void _toggleSortOrder() {
    setState(() {
      _isAscending = !_isAscending;
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

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('High Scores'),
        actions: [
          IconButton(
            icon: Icon(
              _isSortedByWeight ? Icons.fitness_center : Icons.sort_by_alpha,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: _toggleSorting,
            tooltip:
                _isSortedByWeight ? 'Sort Alphabetically' : 'Sort by Weight',
          ),
          IconButton(
            icon: Icon(
              _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: _toggleSortOrder,
            tooltip: _isAscending ? 'Sort Descending' : 'Sort Ascending',
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
                : _maxWeights.isEmpty
                    ? const Center(child: Text('No data available'))
                    : ListView.separated(
                        itemCount: _maxWeights.length,
                        itemBuilder: (context, index) {
                          final record = _maxWeights[index];
                          final exercise = record['exercise'] as String;
                          final weight = record['weight'];
                          final reps = record['reps'];
                          final displayWeight = _convertWeight(
                              weight is String ? double.parse(weight) : weight);

                          return ListTile(
                            title: Text(exercise),
                            trailing: Text(
                                '${displayWeight.toStringAsFixed(1)} ${widget.isKg ? 'kg' : 'lbs'} x $reps reps'),
                          );
                        },
                        separatorBuilder: (context, index) => Divider(),
                      ),
      ),
    );
  }
}
