import 'package:flutter/material.dart';
import '../core/database.dart';

class RecordsTab extends StatefulWidget {
  @override
  _RecordsTabState createState() => _RecordsTabState();
}

class _RecordsTabState extends State<RecordsTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, Map<String, dynamic>> _maxWeights = {};
  bool _isSortedByWeight = false;
  bool _isLoading = true; // Track loading state
  String? _errorMessage;  // Track error message

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
        _errorMessage = 'Failed to load data. Please try again later.'; // Set error message
      });
      print('Error fetching records: $e'); // Log error for debugging
    }
  }

  void _sortRecords() {
    if (_isSortedByWeight) {
      _maxWeights = Map.fromEntries(
        _maxWeights.entries.toList()
          ..sort((a, b) => (b.value['maxWeight'] as double)
              .compareTo(a.value['maxWeight'] as double)),
      );
    } else {
      _maxWeights = Map.fromEntries(
        _maxWeights.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchAndSortRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red)))
              : _maxWeights.isEmpty
                  ? const Center(child: Text('No records available.'))
                  : ListView.builder(
                      itemCount: _maxWeights.length,
                      itemBuilder: (context, index) {
                        final exercise = _maxWeights.keys.elementAt(index);
                        final weightData = _maxWeights[exercise]!;
                        final weight = weightData['maxWeight'];
                        final reps = weightData['reps'];

                        return Column(
                          children: [
                            ListTile(
                              title: Text(exercise),
                              trailing:
                                  Text('${weight!.toStringAsFixed(1)} kg x $reps reps'),
                            ),
                            if (index < _maxWeights.length - 1) Divider(),
                          ],
                        );
                      },
                    ),
    );
  }
}
