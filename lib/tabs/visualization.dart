import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/database.dart';

class VisualizationTab extends StatefulWidget {
  const VisualizationTab({Key? key}) : super(key: key);

  @override
  _VisualizationTabState createState() => _VisualizationTabState();
}

class _VisualizationTabState extends State<VisualizationTab> {
  String? _selectedExercise;
  String _aggregationMethod = 'Max'; // Default aggregation method
  String _chartType = 'Line'; // Default chart type
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

      final groupedByDate = <DateTime, List<double>>{};
      for (var exercise in filteredExercises) {
        final dateTime = DateUtils.dateOnly(DateTime.parse(exercise['timestamp']));
        final weight = double.parse(exercise['weight']);
        if (groupedByDate.containsKey(dateTime)) {
          groupedByDate[dateTime]!.add(weight);
        } else {
          groupedByDate[dateTime] = [weight];
        }
      }

      final aggregatedDataPoints = <ScatterSpot>[];
      final earliestDate = DateUtils.dateOnly(DateTime.parse(filteredExercises.last['timestamp']));
      groupedByDate.forEach((date, weights) {
        double value;
        switch (_aggregationMethod) {
          case 'Max':
            value = weights.reduce((a, b) => a > b ? a : b);
            break;
          case 'Average':
            value = weights.reduce((a, b) => a + b) / weights.length;
            break;
          case 'None':
          default:
            value = weights.last;
            break;
        }
        final dayDifference = date.difference(earliestDate).inDays.toDouble();
        aggregatedDataPoints.add(ScatterSpot(dayDifference, value));
      });

      setState(() {
        _dataPoints = aggregatedDataPoints;
      });
    } catch (e) {
      print('Error fetching data points: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildExerciseDropdown(),
          const SizedBox(height: 16.0),
          _buildAggregationDropdown(),
          const SizedBox(height: 16.0),
          _buildChartTypeToggle(),
          const SizedBox(height: 16.0),
          Expanded(
            child: _dataPoints.isEmpty
                ? const Center(child: Text('No data available'))
                : _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseDropdown() {
    return DropdownButton<String>(
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
    );
  }

  Widget _buildAggregationDropdown() {
    return DropdownButton<String>(
      hint: const Text('Select aggregation method'),
      value: _aggregationMethod,
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() {
            _aggregationMethod = newValue;
          });
          if (_selectedExercise != null) {
            _fetchDataPoints(_selectedExercise!);
          }
        }
      },
      items: <String>['None', 'Max', 'Average'].map((method) {
        return DropdownMenuItem<String>(
          value: method,
          child: Text(method),
        );
      }).toList(),
    );
  }

  Widget _buildChartTypeToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Chart Type:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        DropdownButton<String>(
          value: _chartType,
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                _chartType = newValue;
              });
            }
          },
          items: _aggregationMethod == 'None'
              ? ['Scatter'].map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList()
              : ['Line', 'Scatter'].map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
        ),
      ],
    );
  }

  Widget _buildChart() {
    return _chartType == 'Line'
        ? LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: _dataPoints,
                  isCurved: false,
                  color: Colors.blue,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
              titlesData: _buildTitlesData(),
              borderData: FlBorderData(show: true),
              gridData: const FlGridData(show: true),
            ),
          )
        : ScatterChart(
            ScatterChartData(
              scatterSpots: _dataPoints,
              scatterTouchData: ScatterTouchData(
                touchTooltipData: ScatterTouchTooltipData(
                  getTooltipColor: (ScatterSpot touchedSpot) => Colors.blueAccent,
                ),
                enabled: true,
              ),
              titlesData: _buildTitlesData(),
              borderData: FlBorderData(show: true),
              gridData: const FlGridData(show: true),
            ),
          );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
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
    );
  }
}
