import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/database.dart';
import '../core/theme.dart'; // Import the theme.dart

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
  double? _minX, _maxX, _minY, _maxY;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _fetchExerciseNames();
    _fetchDataPoints(); // Fetch data points with default values
  }

  Future<void> _fetchExerciseNames() async {
    print('Fetching names from $_selectedTable table...');
    try {
      List<Map<String, dynamic>> variables;
      if (_selectedTable == 'Exercise') {
        variables = await _dbHelper.getExercises();
      } else {
        variables = await _dbHelper.getFitnessData();
      }

      final names = variables
          .map((entry) => entry['exercise'] as String)
          .toSet()
          .toList();
      setState(() {
        _exerciseNames = names;
      });
    } catch (e) {
      print('Error fetching names: $e');
    }
  }

  double _convertWeight(double weightInKg) {
    return widget.isKg ? weightInKg : weightInKg * 2.20462;
  }

  Future<void> _fetchDataPoints([String? exerciseName]) async {
    print('Fetching data points for: $exerciseName');
    try {
      List<Map<String, dynamic>> records;
      if (_selectedTable == 'Exercise') {
        records = await _dbHelper.getExercises();
      } else {
        records = await _dbHelper.getFitnessData();
      }

      final filteredRecords = exerciseName == null
          ? records
          : records
              .where((record) => record['exercise'] == exerciseName)
              .toList();

      final groupedByDate = <DateTime, List<double>>{};
      for (var record in filteredRecords) {
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
      final earliestDate =
          DateUtils.dateOnly(DateTime.parse(filteredRecords.last['timestamp']));

      double? minValue;
      double? maxValue;

      groupedByDate.forEach((date, values) {
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
        final convertedValue = _convertWeight(value);

        aggregatedDataPoints.add(ScatterSpot(
          dayDifference,
          convertedValue,
          dotPainter: FlDotCirclePainter(
            color: Theme.of(context).primaryChartColor, // Use theme color
            radius: 6,
          ),
        ));

        // Update min and max values
        if (minValue == null || convertedValue < (minValue as double))
          minValue = convertedValue;
        if (maxValue == null || convertedValue > (maxValue as double))
          maxValue = convertedValue;
      });

      setState(() {
        _dataPoints = aggregatedDataPoints;
        _minX =
            _dataPoints.map((point) => point.x).reduce((a, b) => a < b ? a : b);
        _maxX =
            _dataPoints.map((point) => point.x).reduce((a, b) => a > b ? a : b);
        _minY = minValue ?? 0.0;
        _maxY = maxValue ?? 100.0; // Set default if no data
      });
    } catch (e) {
      print('Error fetching data points: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scatterColor =
        theme.primaryChartColor; // Use primaryChartColor for scatter points
    final lineColor =
        theme.primaryChartColor; // Use primaryChartColor for lines
    final axisTextColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

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
                  width: 90,
                  child: _buildAggregationDropdown(theme),
                ),
                const SizedBox(width: 16.0),
                SizedBox(
                  width: 100,
                  child: _buildChartTypeToggle(theme),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: _dataPoints.isEmpty
                  ? Center(
                      child: Text(
                        'No Data Available',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 300,
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _buildChart(
                                theme, scatterColor, lineColor, axisTextColor),
                          ),
                        ],
                      ),
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
          _fetchDataPoints(); // Fetch data points with updated table
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
            _fetchDataPoints(
                _selectedExercise); // Refetch data with new data type
          });
        }
      },
      items: ['Weight'].map((dataType) {
        return DropdownMenuItem<String>(
          value: dataType,
          child: Text(dataType,
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
            _fetchDataPoints(_selectedExercise); // Refetch data with new method
          });
        }
      },
      items: ['Max', 'Average'].map((method) {
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
    return ToggleButtons(
      isSelected: [_chartType == 'Line', _chartType == 'Scatter'],
      onPressed: (int index) {
        setState(() {
          _chartType = index == 0 ? 'Line' : 'Scatter';
          _fetchDataPoints(_selectedExercise); // Refetch data with new chart type
        });
      },
      children: [
        Icon(Icons.show_chart, color: theme.iconTheme.color),
        Icon(Icons.scatter_plot, color: theme.iconTheme.color),
      ],
    );
  }

  Widget _buildChart(ThemeData theme, Color scatterColor, Color lineColor,
      Color axisTextColor) {
    return _chartType == 'Line'
        ? LineChart(
            LineChartData(
              minX: _minX,
              maxX: _maxX,
              minY: _minY,
              maxY: _maxY,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) =>
                        _bottomTitleWidgets(value, meta, axisTextColor),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) =>
                        _leftTitleWidgets(value, meta, axisTextColor),
                    reservedSize:
                        50, // Ensure enough space for the Y-axis labels
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false, // Hide top axis titles
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false, // Hide right axis titles
                  ),
                ),
              ),
              gridData: FlGridData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: _dataPoints.map((e) => FlSpot(e.x, e.y)).toList(),
                  isCurved: false,
                  color: lineColor,
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          )
        : ScatterChart(
            ScatterChartData(
              minX: _minX,
              maxX: _maxX,
              minY: _minY,
              maxY: _maxY,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) =>
                        _bottomTitleWidgets(value, meta, axisTextColor),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) =>
                        _leftTitleWidgets(value, meta, axisTextColor),
                    reservedSize:
                        50, // Ensure enough space for the Y-axis labels
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false, // Hide top axis titles
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false, // Hide right axis titles
                  ),
                ),
              ),
              scatterSpots: _dataPoints,
            ),
          );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta, Color textColor) {
    const double reservedSize = 20.0;

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: SizedBox(
        width: reservedSize,
        child: Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            color: textColor,
            fontSize: 12,
          ),
          textAlign: TextAlign.right,
        ),
      ),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta, Color textColor) {
    const double reservedSize = 50.0;

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: RotatedBox(
        quarterTurns: 0,
        child: SizedBox(
          width: reservedSize,
          child: Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              color: textColor,
              fontSize: 12,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ),
    );
  }
}
