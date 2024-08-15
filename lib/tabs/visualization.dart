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
  final Color fixedColor = Colors.purple;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _fetchExerciseNames();
  }

  Future<void> _fetchExerciseNames() async {
    try {
      final variables = await _dbHelper.getExercises();
      final names = variables
          .map((exercise) => exercise['exercise'] as String)
          .toSet()
          .toList();
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
      final filteredExercises = exercises
          .where((exercise) => exercise['exercise'] == exerciseName)
          .toList();

      final groupedByDate = <DateTime, List<double>>{};
      for (var exercise in filteredExercises) {
        final dateTime =
            DateUtils.dateOnly(DateTime.parse(exercise['timestamp']));
        final weight = double.parse(exercise['weight']);
        if (groupedByDate.containsKey(dateTime)) {
          groupedByDate[dateTime]!.add(weight);
        } else {
          groupedByDate[dateTime] = [weight];
        }
      }

      final aggregatedDataPoints = <ScatterSpot>[];
      final earliestDate = DateUtils.dateOnly(
          DateTime.parse(filteredExercises.last['timestamp']));
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
        aggregatedDataPoints.add(ScatterSpot(
          dayDifference,
          value,
          dotPainter: FlDotCirclePainter(color: fixedColor, radius: 6),
        ));
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
    final theme = Theme.of(context);

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
                ? Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final chartHeight = constraints.maxHeight;

                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: chartHeight,
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: _buildChart(theme),
                            ),
                            if (_selectedExercise != null)
                              Positioned(
                                bottom: 44,
                                right: 8,
                                child: _buildLegend(theme),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
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
            if (_aggregationMethod == 'None' && _chartType == 'Line') {
              _chartType = 'Scatter';
            }
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

  Widget _buildChart(ThemeData theme) {
    final minY = _dataPoints.isNotEmpty
        ? _dataPoints.map((spot) => spot.y).reduce((a, b) => a < b ? a : b)
        : 0.0;
    final maxY = _dataPoints.isNotEmpty
        ? _dataPoints.map((spot) => spot.y).reduce((a, b) => a > b ? a : b)
        : 0.0;
    final padding = 2;
    final paddedMinY = minY - padding;
    final paddedMaxY = maxY + padding;

    final plotColor = fixedColor; // Apply fixed color here

    final gridColor = theme.colorScheme.onSurface.withOpacity(0.1);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return _chartType == 'Line'
        ? LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: _dataPoints,
                  isCurved: false,
                  color: plotColor, // Apply fixed color here
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
              titlesData: _buildTitlesData(textColor),
              borderData: FlBorderData(show: true),
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: gridColor, strokeWidth: 1);
                  }),
              minY: paddedMinY,
              maxY: paddedMaxY,
            ),
          )
        : ScatterChart(
            ScatterChartData(
              scatterSpots: _dataPoints,
              scatterTouchData: ScatterTouchData(
                touchTooltipData: ScatterTouchTooltipData(
                  getTooltipColor: (ScatterSpot touchedSpot) =>
                      plotColor, // Apply fixed color here
                ),
                enabled: true,
              ),
              titlesData: _buildTitlesData(textColor),
              borderData: FlBorderData(show: true),
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: gridColor, strokeWidth: 1);
                  }),
              minY: paddedMinY,
              maxY: paddedMaxY,
            ),
          );
  }

  Widget _buildLegend(ThemeData theme) {
    final legendColor = fixedColor; // Use the fixed color

    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: legendColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10, // Smaller size
            height: 10, // Smaller size
            color: legendColor,
          ),
          const SizedBox(width: 4.0),
          Text(
            _selectedExercise!,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
              fontSize: 8, // Smaller font size
            ),
          ),
        ],
      ),
    );
  }

  FlTitlesData _buildTitlesData(Color textColor) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            return Text(
              value.toInt().toString(),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            );
          },
        ),
        axisNameWidget: Text(
          'Weights [kg]',
          style: TextStyle(
            color: textColor,
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
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            );
          },
        ),
        axisNameWidget: Text(
          'Days',
          style: TextStyle(
            color: textColor,
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
