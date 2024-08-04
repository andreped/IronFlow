import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/database.dart';

class VisualizationTab extends StatefulWidget {
  const VisualizationTab({Key? key}) : super(key: key);

  @override
  _VisualizationTabState createState() => _VisualizationTabState();
}

class _VisualizationTabState extends State<VisualizationTab> with AutomaticKeepAliveClientMixin {
  String? _selectedExercise;
  List<String> _exerciseNames = [];
  List<ScatterSpot> _dataPoints = [];

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _fetchExerciseNames();
  }

  Future<void> _fetchExerciseNames() async {
    try {
      final variables = await _dbHelper.getExercises();
      print('Fetched exercises: $variables');
      final names = variables.map((exercise) => exercise['exercise'] as String).toSet().toList();
      setState(() {
        _exerciseNames = names;
      });
    } catch (e) {
      print('Error fetching exercise names: $e');
    }
  }

  Future<void> _fetchDataPoints(String exerciseName) async {
    try {
      final exercises = await _dbHelper.getExercises();
      final filteredExercises = exercises.where((exercise) => exercise['exercise'] == exerciseName).toList();

      // Sort the filtered exercises by timestamp in descending order
      filteredExercises.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));

      // Get the earliest date (ignoring the time part)
      final earliestDate = DateUtils.dateOnly(DateTime.parse(filteredExercises.last['timestamp']));

      final dataPoints = filteredExercises.map((exercise) {
        final dateTime = DateUtils.dateOnly(DateTime.parse(exercise['timestamp']));

        // Calculate the difference in days, ignoring hours time information
        final dayDifference = dateTime.difference(earliestDate).inDays.toDouble();
        return ScatterSpot(dayDifference, double.parse(exercise['weight']));
      }).toList();

      setState(() {
        _dataPoints = dataPoints;
      });
    } catch (e) {
      print('Error fetching data points: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          DropdownButton<String>(
            hint: const Text('Select an exercise'),
            value: _selectedExercise,
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedExercise = newValue;
                });
                _fetchDataPoints(newValue);
              }
            },
            items: _exerciseNames.map((exerciseName) {
              return DropdownMenuItem<String>(
                value: exerciseName,
                child: Text(exerciseName),
              );
            }).toList(),
          ),
          const SizedBox(height: 16.0),
          Expanded(
            child: _dataPoints.isEmpty
                ? const Center(child: Text('No data available'))
                : ScatterChart(
                    ScatterChartData(
                      scatterSpots: _dataPoints,
                      scatterTouchData: ScatterTouchData(
                        touchTooltipData: ScatterTouchTooltipData(
                          getTooltipColor: (ScatterSpot touchedSpot) => Colors.blueAccent,
                        ),
                        enabled: true,
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40, // Add padding on the left for numbers and text
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                          axisNameWidget: const Text(
                            'Weights [kg]',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                          axisNameWidget: const Text(
                            'Days',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      gridData: const FlGridData(show: true),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true; // Required by AutomaticKeepAliveClientMixin
}
