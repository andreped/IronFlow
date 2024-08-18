import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/database.dart';
import '../core/theme.dart'; // Import your theme with the ChartColors extension

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
    print('Fetching exercise names...');
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
    print('Fetching data points for: $exerciseName');
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
        if (_aggregationMethod == 'None') {
          // Plot all data points individually
          for (var weight in weights) {
            final dayDifference =
                date.difference(earliestDate).inDays.toDouble();
            aggregatedDataPoints.add(ScatterSpot(
              dayDifference,
              weight,
              dotPainter: FlDotCirclePainter(
                  color: Theme.of(context).primaryChartColor, radius: 6),
            ));
          }
        } else {
          // Apply Max or Average aggregation
          double value;
          switch (_aggregationMethod) {
            case 'Max':
              value = weights.reduce((a, b) => a > b ? a : b);
              break;
            case 'Average':
              value = weights.reduce((a, b) => a + b) / weights.length;
              break;
            default:
              value = weights.last;
              break;
          }
          final dayDifference = date.difference(earliestDate).inDays.toDouble();
          aggregatedDataPoints.add(ScatterSpot(
            dayDifference,
            value,
            dotPainter: FlDotCirclePainter(
                color: Theme.of(context).primaryChartColor, radius: 6),
          ));
        }
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

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildExerciseDropdown(theme),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 90, // Adjust the width as needed
                  child: _buildAggregationDropdown(theme),
                ),
                const SizedBox(width: 16.0),
                SizedBox(
                  width: 85, // Adjust the width as needed
                  child: _buildChartTypeToggle(theme),
                ),
              ],
            ),
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
      ),
    );
  }

  Widget _buildExerciseDropdown(ThemeData theme) {
    return DropdownButton<String>(
      hint: Text('Exercise',
          style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
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
          child: Text(exerciseName,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        );
      }).toList(),
      dropdownColor:
          theme.dropdownMenuTheme.menuStyle?.backgroundColor?.resolve({}) ??
              Colors.white,
    );
  }

  Widget _buildAggregationDropdown(ThemeData theme) {
    return DropdownButton<String>(
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
      items: ['Max', 'Average', 'None'].map((method) {
        return DropdownMenuItem<String>(
          value: method,
          child: Text(method,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        );
      }).toList(),
      dropdownColor:
          theme.dropdownMenuTheme.menuStyle?.backgroundColor?.resolve({}) ??
              Colors.white,
    );
  }

  Widget _buildChartTypeToggle(ThemeData theme) {
    return DropdownButton<String>(
      value: _chartType,
      onChanged: (newValue) {
        if (newValue != null && newValue != _chartType) {
          setState(() {
            _chartType = newValue;
            if (_chartType == 'Line' && _aggregationMethod == 'None') {
              _aggregationMethod = 'Max';
            }
          });
          if (_selectedExercise != null) {
            _fetchDataPoints(_selectedExercise!);
          }
        }
      },
      items: ['Line', 'Scatter'].map((type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        );
      }).toList(),
      dropdownColor:
          theme.dropdownMenuTheme.menuStyle?.backgroundColor?.resolve({}) ??
              Colors.white,
    );
  }

  Widget _buildChart(ThemeData theme) {
    final chartColor =
        theme.primaryChartColor; // Use the theme's primary chart color
    final gridColor = theme.colorScheme.onSurface.withOpacity(0.1);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return _chartType == 'Line'
        ? LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: _dataPoints,
                  isCurved: false,
                  color: chartColor,
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
              minY: 0.0,
              maxY: 100.0,
            ),
          )
        : ScatterChart(
            ScatterChartData(
              scatterSpots: _dataPoints,
              scatterTouchData: ScatterTouchData(
                touchTooltipData: ScatterTouchTooltipData(
                  getTooltipColor: (ScatterSpot touchedSpot) => chartColor,
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
              minY: 0.0,
              maxY: 100.0,
            ),
          );
  }

  Widget _buildLegend(ThemeData theme) {
    final legendColor = theme.primaryChartColor;

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
            width: 10,
            height: 10,
            color: legendColor,
          ),
          const SizedBox(width: 4.0),
          Text(
            _selectedExercise ?? '',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
              fontSize: 8,
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
