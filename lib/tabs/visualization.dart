import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/database.dart';
import '../core/theme.dart'; // Import your theme with the ChartColors extension

class VisualizationTab extends StatefulWidget {
  final bool isKg;

  const VisualizationTab({Key? key, required this.isKg}) : super(key: key);

  @override
  _VisualizationTabState createState() => _VisualizationTabState();
}

class _VisualizationTabState extends State<VisualizationTab> {
  String? _selectedExercise;
  String _selectedTable = 'Exercise'; // Default selected table
  String _aggregationMethod = 'Max'; // Default aggregation method
  String _chartType = 'Line'; // Default chart type
  String _dataType = 'Weight'; // Default data type for Fitness table
  List<String> _exerciseNames = [];
  List<ScatterSpot> _dataPoints = [];
  double? _minY;
  double? _maxY;
  final Color fixedColor = Colors.purple;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _fetchExerciseNames();
  }

  Future<void> _fetchExerciseNames() async {
    print('Fetching names from $_selectedTable table...');
    try {
      List<Map<String, dynamic>> variables;
      if (_selectedTable == 'Exercise') {
        variables = await _dbHelper.getExercises();
        final names = variables
            .map((entry) => entry['exercise'] as String)
            .toSet()
            .toList();
        setState(() {
          _exerciseNames = names;
        });
      } else {
        // For Fitness table, no exercise names needed
        setState(() {
          _exerciseNames = [];
        });
      }
    } catch (e) {
      print('Error fetching names: $e');
    }
  }

  double _convertWeight(double weightInKg) {
    return widget.isKg ? weightInKg : weightInKg * 2.20462;
  }

  Future<void> _fetchDataPoints(String? selectedExercise) async {
    print('Fetching data points for: $selectedExercise');
    try {
      List<Map<String, dynamic>> records;
      if (_selectedTable == 'Exercise') {
        records = await _dbHelper.getExercises();
        final filteredRecords = records
            .where((record) => record['exercise'] == selectedExercise)
            .toList();

        final groupedByDate = <DateTime, List<double>>{};
        for (var record in filteredRecords) {
          final dateTime =
              DateUtils.dateOnly(DateTime.parse(record['timestamp']));
          final weight = double.tryParse(record['weight']) ?? 0.0;
          if (groupedByDate.containsKey(dateTime)) {
            groupedByDate[dateTime]!.add(weight);
          } else {
            groupedByDate[dateTime] = [weight];
          }
        }

        final aggregatedDataPoints = <ScatterSpot>[];
        final earliestDate = DateUtils.dateOnly(
            DateTime.parse(filteredRecords.last['timestamp']));

        double? minWeight;
        double? maxWeight;

        groupedByDate.forEach((date, weights) {
          if (_aggregationMethod == 'None') {
            // Plot all data points individually
            for (var weight in weights) {
              final dayDifference =
                  date.difference(earliestDate).inDays.toDouble();
              final convertedWeight = _convertWeight(weight);

              aggregatedDataPoints.add(ScatterSpot(
                dayDifference,
                convertedWeight,
                dotPainter: FlDotCirclePainter(
                    color: Theme.of(context).primaryChartColor, radius: 6),
              ));

              // Update min and max weight
              if (minWeight == null || convertedWeight < (minWeight as double))
                minWeight = convertedWeight;
              if (maxWeight == null || convertedWeight > (maxWeight as double))
                maxWeight = convertedWeight;
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
            final convertedValue = _convertWeight(value);
            aggregatedDataPoints.add(ScatterSpot(
              dayDifference,
              convertedValue,
              dotPainter: FlDotCirclePainter(
                  color: Theme.of(context).primaryChartColor, radius: 6),
            ));

            // Update min and max weight
            if (minWeight == null || convertedValue < (minWeight as double))
              minWeight = convertedValue;
            if (maxWeight == null || convertedValue > (maxWeight as double))
              maxWeight = convertedValue;
          }
        });

        setState(() {
          _dataPoints = aggregatedDataPoints;
          _minY = minWeight ?? 0.0;
          _maxY = maxWeight ?? 100.0; // Set default if no data
        });
      } else {
        records = await _dbHelper.getFitnessData();

        final groupedByDate = <DateTime, List<double>>{};
        for (var record in records) {
          final dateTime =
              DateUtils.dateOnly(DateTime.parse(record['timestamp']));
          final value = double.tryParse(record[_dataType.toLowerCase()]) ?? 0.0;
          if (groupedByDate.containsKey(dateTime)) {
            groupedByDate[dateTime]!.add(value);
          } else {
            groupedByDate[dateTime] = [value];
          }
        }

        final aggregatedDataPoints = <ScatterSpot>[];
        final earliestDate = DateUtils.dateOnly(
            DateTime.parse(records.last['timestamp']));

        double? minValue;
        double? maxValue;

        groupedByDate.forEach((date, values) {
          if (_aggregationMethod == 'None') {
            // Plot all data points individually
            for (var value in values) {
              final dayDifference =
                  date.difference(earliestDate).inDays.toDouble();

              aggregatedDataPoints.add(ScatterSpot(
                dayDifference,
                value,
                dotPainter: FlDotCirclePainter(
                    color: Theme.of(context).primaryChartColor, radius: 6),
              ));

              // Update min and max value
              if (minValue == null || value < (minValue as double))
                minValue = value;
              if (maxValue == null || value > (maxValue as double))
                maxValue = value;
            }
          } else {
            // Apply Max or Average aggregation
            double value;
            switch (_aggregationMethod) {
              case 'Max':
                value = values.reduce((a, b) => a > b ? a : b);
                break;
              case 'Average':
                value = values.reduce((a, b) => a + b) / values.length;
                break;
              default:
                value = values.last;
                break;
            }
            final dayDifference = date.difference(earliestDate).inDays.toDouble();
            aggregatedDataPoints.add(ScatterSpot(
              dayDifference,
              value,
              dotPainter: FlDotCirclePainter(
                  color: Theme.of(context).primaryChartColor, radius: 6),
            ));

            // Update min and max value
            if (minValue == null || value < (minValue as double))
              minValue = value;
            if (maxValue == null || value > (maxValue as double))
              maxValue = value;
          }
        });

        setState(() {
          _dataPoints = aggregatedDataPoints;
          _minY = minValue ?? 0.0;
          _maxY = maxValue ?? 100.0; // Set default if no data
        });
      }
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
            _buildTableDropdown(theme),
            const SizedBox(height: 16.0),
            if (_selectedTable == 'Exercise') _buildExerciseDropdown(theme),
            if (_selectedTable == 'Fitness') _buildDataTypeDropdown(theme),
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

  Widget _buildTableDropdown(ThemeData theme) {
    return DropdownButton<String>(
      value: _selectedTable,
      onChanged: (newValue) {
        if (newValue != null && newValue != _selectedTable) {
          setState(() {
            _selectedTable = newValue;
            _selectedExercise = null; // Reset the selected exercise
            _exerciseNames = []; // Clear the exercise names
            _dataPoints = []; // Clear the data points
            _dataType = 'Weight'; // Reset data type to default
          });
          _fetchExerciseNames(); // Fetch the new exercise names if needed
        }
      },
      items: ['Exercise', 'Fitness'].map((table) {
        return DropdownMenuItem<String>(
          value: table,
          child: Text(table,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        );
      }).toList(),
      dropdownColor:
          theme.dropdownMenuTheme.menuStyle?.backgroundColor?.resolve({}) ??
              Colors.white,
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

  Widget _buildDataTypeDropdown(ThemeData theme) {
    return DropdownButton<String>(
      value: _dataType,
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() {
            _dataType = newValue;
            _dataPoints = []; // Clear existing data points
            _fetchDataPoints(null); // Fetch data points for the new type
          });
        }
      },
      items: ['Weight', 'Age', 'Height'].map((type) {
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
          if (_selectedExercise != null || _selectedTable == 'Fitness') {
            _fetchDataPoints(_selectedExercise);
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
        if (newValue != null) {
          setState(() {
            _chartType = newValue;
          });
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
    return _chartType == 'Line' ? _buildLineChart(theme) : _buildScatterChart();
  }

  Widget _buildLineChart(ThemeData theme) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: _dataPoints.map((data) {
              return FlSpot(data.x, data.y);
            }).toList(),
            isCurved: false,
            color: fixedColor,
            barWidth: 2,
            dotData: FlDotData(show: true),
          ),
        ],
        minY: _minY,
        maxY: _maxY,
        borderData: FlBorderData(
          show: true,
          border: Border.all(
              color: theme.primaryChartColor, width: 1), // Use theme color
        ),
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false, // Hide top titles
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false, // Hide right titles
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScatterChart() {
    return ScatterChart(
      ScatterChartData(
        scatterSpots: _dataPoints,
        minY: _minY,
        maxY: _maxY,
        borderData: FlBorderData(show: true),
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false, // Hide top titles
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false, // Hide right titles
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: theme.primaryChartColor, // Use the themed color
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        _selectedExercise ?? '',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.primaryChartColor, // Use the themed color
        ),
      ),
    );
  }
}
