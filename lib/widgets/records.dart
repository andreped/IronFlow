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
    if (_isSortedByWeight) {
      _maxWeights.sort((a, b) {
        final maxWeightA = a['max_weight'] as double;
        final maxWeightB = b['max_weight'] as double;
        if (maxWeightA == maxWeightB) {
          // If weights are equal, sort alphabetically by exercise name
          return a['exercise'].compareTo(b['exercise']);
        }
        return maxWeightB.compareTo(maxWeightA);
      });
    } else {
      _maxWeights.sort((a, b) => a['exercise'].compareTo(b['exercise']));
    }
  }

  void _toggleSorting() {
    setState(() {
      _isSortedByWeight = !_isSortedByWeight;
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
                    : ListView.builder(
                        itemCount: _maxWeights.length,
                        itemBuilder: (context, index) {
                          final record = _maxWeights[index];
                          final exercise = record['exercise'] as String;
                          final weight = record['max_weight'] as double;
                          final displayWeight = _convertWeight(weight);

                          return Column(
                            children: [
                              ListTile(
                                title: Text(exercise),
                                trailing: Text(
                                    '${displayWeight.toStringAsFixed(1)} ${widget.isKg ? 'kg' : 'lbs'}'),
                              ),
                              if (index < _maxWeights.length - 1) Divider(),
                            ],
                          );
                        },
                      ),
      ),
    );
  }
}
