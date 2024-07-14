import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/database.dart';

class VisualizationTab extends StatefulWidget {
  @override
  _VisualizationTabState createState() => _VisualizationTabState();
}

class _VisualizationTabState extends State<VisualizationTab> {
  String? _selectedExercise;
  List<String> _exerciseNames = [];
  List<FlSpot> _dataPoints = [];

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _fetchExerciseNames();
  }

  Future<void> _fetchExerciseNames() async {
    final variables = await _dbHelper.getExercises();
    final names = variables.map((exercise) => exercise['exercise'] as String).toSet().toList();
    setState(() {
      _exerciseNames = names;
    });
  }

  Future<void> _fetchDataPoints(String exerciseName) async {
    final exercises = await _dbHelper.getExercises();
    final filteredExercises = exercises.where((exercise) => exercise['exercise'] == exerciseName).toList();

    // get earliest date
    final dateTimes = exercises.map((row) => row['timestamp'] as String).toList();
    final earliestDateTime = DateTime.parse(dateTimes.reduce((a, b) => a.compareTo(b) < 0 ? a : b));

    final dataPoints = filteredExercises.asMap().entries.map((entry) {
      return FlSpot(DateTime.parse(entry.value['timestamp']).difference(earliestDateTime).inDays.toDouble(), double.parse(entry.value['weight']));
    }).toList();

    setState(() {
      _dataPoints = dataPoints;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          DropdownButton<String>(
            hint: const Text('Select an exercise'),
            value: _selectedExercise,
            onChanged: (newValue) {
              setState(() {
                _selectedExercise = newValue;
                _fetchDataPoints(newValue!);
              });
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
                : LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: _dataPoints,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40, // Add padding on the left for numbers and text
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toString(),
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
                                value.toString(),
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
}
