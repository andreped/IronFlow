import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/database.dart';
import '../core/theme.dart';

class VisualizationTab extends StatefulWidget {
  final bool isKg;
  final String defaultAggregationMethod;
  final String defaultChartType;

  const VisualizationTab({
    Key? key,
    required this.isKg,
    required this.defaultAggregationMethod,
    required this.defaultChartType,
  }) : super(key: key);

  @override
  _VisualizationTabState createState() => _VisualizationTabState();
}

class _VisualizationTabState extends State<VisualizationTab> {
  String? _selectedExercise;
  String _selectedTable = 'Exercise'; // Default selected table
  late String _aggregationMethod;
  late String _chartType;
  String _dataType = 'Weight'; // Default data type for Fitness table
  List<String> _exerciseNames = [];
  List<ScatterSpot> _dataPoints = [];
  double _minX = 0.0;
  double _maxX = 0.0;
  double _minY = 0.0;
  double _maxY = 100.0;
  DateTimeRange? _selectedDateRange;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _initializeDefaults();
    _fetchExerciseNames(); // Fetch exercise names initially
  }

  void _initializeDefaults() {
    setState(() {
      _aggregationMethod = widget.defaultAggregationMethod;
      _chartType = widget.defaultChartType;
    });
  }

  @override
  void didUpdateWidget(covariant VisualizationTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.defaultAggregationMethod != oldWidget.defaultAggregationMethod ||
        widget.defaultChartType != oldWidget.defaultChartType) {
      _initializeDefaults();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when the tab becomes active
    if (_selectedExercise != null && _selectedTable.isNotEmpty) {
      _fetchDataPoints(_selectedExercise);
    }
  }

  Future<void> _fetchExerciseNames() async {
    print('Fetching names from $_selectedTable table...');
    try {
      List<String> names;
      if (_selectedTable == 'Exercise') {
        // fetch recorded exercises
        names = await _dbHelper.getRecordedExercises();
      } else {
        // fetch fitness data
        List<Map<String, dynamic>> variables = await _dbHelper.getFitnessData();
        names = variables
            .map((entry) => entry['exercise'] as String)
            .toSet()
            .toList();
      }

      // sort names if not empty
      if (names.isNotEmpty) {
        names.sort();
      }

      // update states
      setState(() {
        _exerciseNames = names;
        if (_selectedExercise != null) {
          _fetchDataPoints(_selectedExercise);
        }
      });
    } catch (e) {
      print('Error fetching names: $e');
    }

    // render last recorded exercise by default if any
    if (_exerciseNames.isNotEmpty && _selectedExercise == null) {
      try {
        String? lastRecordedExercise =
            await _dbHelper.getLastLoggedExerciseName();
        if (lastRecordedExercise != null) {
          setState(() {
            _selectedExercise = lastRecordedExercise;
            _fetchDataPoints(_selectedExercise);
          });
        }
      } catch (e) {
        print('Error fetching last recorded exercise: $e');
      }
    }

    // Fetch data points for the default data type if Fitness table is selected
    if (_selectedTable == 'Fitness') {
      _fetchDataPoints(null);
    }
  }

  double _convertWeight(double weightInKg) {
    return widget.isKg ? weightInKg : weightInKg * 2.20462;
  }

  Future<void> _fetchDataPoints(String? exerciseName) async {
    print('Fetching data points for: $exerciseName');
    String currAggregationMethod = _aggregationMethod;
    List<Map<String, dynamic>> records;
    if (_selectedTable == 'Exercise') {
      records = await _dbHelper.getExercises();
    } else {
      records = await _dbHelper.getFitnessData();
      currAggregationMethod = 'Max';
    }

    final filteredRecords = exerciseName == null
        ? records
        : records
            .where((record) => record['exercise'] == exerciseName)
            .toList();

    final groupedByDate = <DateTime, List<Map<String, dynamic>>>{};

    // Group records by date
    for (var record in filteredRecords) {
      final dateTime = DateUtils.dateOnly(DateTime.parse(record['timestamp']));

      if (_selectedDateRange == null ||
          (dateTime.isAfter(
                  _selectedDateRange!.start.subtract(Duration(days: 1))) &&
              dateTime
                  .isBefore(_selectedDateRange!.end.add(Duration(days: 1))))) {
        if (groupedByDate.containsKey(dateTime)) {
          groupedByDate[dateTime]!.add(record);
        } else {
          groupedByDate[dateTime] = [record];
        }
      }
    }

    final aggregatedDataPoints = <ScatterSpot>[];
    final earliestDate =
        DateUtils.dateOnly(DateTime.parse(filteredRecords.last['timestamp']));

    double? minValue;
    double? maxValue;

    groupedByDate.forEach((date, recordsForDay) {
      double value;
      switch (currAggregationMethod) {
        case 'Max':
          value = recordsForDay
              .map((record) =>
                  double.tryParse(record[_dataType.toLowerCase()].toString()) ??
                  0.0)
              .reduce((a, b) => a > b ? a : b);
          break;

        case 'Average':
          // Weighted Average for this day
          double totalWeight = 0.0;
          double totalRepsSets = 0.0;

          for (var record in recordsForDay) {
            final weight = double.tryParse(record['weight'].toString()) ?? 0.0;
            final reps = double.tryParse(record['reps'].toString()) ?? 1.0;
            final sets = double.tryParse(record['sets'].toString()) ?? 1.0;

            totalWeight += sets * reps * weight;
            totalRepsSets += sets * reps;
          }

          value = totalRepsSets > 0 ? totalWeight / totalRepsSets : 0.0;
          break;

        case 'Top3Avg':
          // Sort records by weight in descending order
          final sortedRecords = recordsForDay
              .map((record) => {
                    'weight':
                        double.tryParse(record['weight'].toString()) ?? 0.0,
                    'reps': double.tryParse(record['reps'].toString()) ?? 1.0,
                    'sets': double.tryParse(record['sets'].toString()) ?? 1.0,
                  })
              .toList()
            ..sort(
                (a, b) => (b['weight'] ?? 0.0).compareTo(a['weight'] ?? 0.0));

          // Take the top 3 records with the highest weights
          final top3Records = sortedRecords.take(3).toList();

          // Calculate the weighted average for the top 3 records
          double top3TotalWeight = 0.0;
          double top3TotalRepsSets = 0.0;

          for (var record in top3Records) {
            final weight = record['weight'];
            final reps = record['reps'];
            final sets = record['sets'];

            top3TotalWeight += (sets ?? 1.0) * (reps ?? 1.0) * (weight ?? 0.0);
            top3TotalRepsSets += (sets ?? 1.0) * (reps ?? 1.0);
          }

          value =
              top3TotalRepsSets > 0 ? top3TotalWeight / top3TotalRepsSets : 0.0;
          break;

        case 'Total':
          value = recordsForDay.fold(0.0, (sum, record) {
            final sets = double.tryParse(record['sets'].toString()) ?? 1.0;
            final reps = double.tryParse(record['reps'].toString()) ?? 1.0;
            final weight = double.tryParse(record['weight'].toString()) ?? 0.0;
            return sum + (sets * reps * weight);
          });
          break;

        default:
          value =
              double.tryParse(recordsForDay.last[_dataType.toLowerCase()]) ??
                  0.0;
          break;
      }

      value = double.parse(value.toStringAsFixed(2));
      final dayDifference = date.difference(earliestDate).inDays.toDouble();
      final convertedValue = _convertWeight(value);

      aggregatedDataPoints.add(ScatterSpot(
        dayDifference,
        convertedValue,
        dotPainter: FlDotCirclePainter(
          color: Theme.of(context).colorScheme.secondary, // Use theme color
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

      // Convert minY and maxY to the appropriate unit
      _minY = _convertWeight(_minY);
      _maxY = _convertWeight(_maxY);
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      if (_selectedExercise != null) {
        _fetchDataPoints(_selectedExercise!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scatterColor = theme.primaryChartColor;
    final lineColor = theme.primaryChartColor;
    final axisTextColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    // Get the height of the screen
    final screenHeight = MediaQuery.of(context).size.height;
    // Define the maximum height for the chart as 45% of the screen height
    final chartMaxHeight = screenHeight * 0.45;

    // Initialize the date range to the last month if not already set
    if (_selectedDateRange == null) {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, now.day);
      _selectedDateRange = DateTimeRange(start: lastMonth, end: now);
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTableDropdown(theme),
              const SizedBox(height: 8.0),
              if (_selectedTable == 'Exercise') _buildExerciseDropdown(theme),
              if (_selectedTable == 'Fitness') _buildDataTypeDropdown(theme),
              const SizedBox(height: 16.0),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: chartMaxHeight,
                ),
                child: _dataPoints.isEmpty
                    ? Center(
                        child: Text(
                          'No Data Available',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : _buildChart(
                        theme, scatterColor, lineColor, axisTextColor),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 100,
                    child: _buildAggregationDropdown(theme),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () => _selectDateRange(context),
                    child: Text(
                      'Date Range',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  SizedBox(
                    width: 100,
                    child: _buildChartTypeToggle(theme),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableDropdown(ThemeData theme) {
    return DropdownButton<String>(
      hint: Text('Select Table',
          style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
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
      hint: Text('Select Exercise',
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
            _fetchDataPoints(_selectedExercise);
          });
        }
      },
      items: ['Weight', 'Height', 'Age'].map((dataType) {
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
            _fetchDataPoints(_selectedExercise);
          });
        }
      },
      items: ['Max', 'Average', 'Top3Avg', 'Total'].map((method) {
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
    // Calculate the min and max values dynamically
    double _minX = _dataPoints.map((e) => e.x).reduce((a, b) => a < b ? a : b);
    double _maxX = _dataPoints.map((e) => e.x).reduce((a, b) => a > b ? a : b);
    double _minY = _dataPoints.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    double _maxY = _dataPoints.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    // Calculate the dynamic intervals
    int nbLines = 6;
    double horizontalRange = _maxY - _minY;
    double verticalRange = _maxX - _minX;
    double horizontalInterval = horizontalRange / nbLines;
    double verticalInterval = verticalRange / nbLines;

    // Ensure a maximum of x lines for each axis and that intervals are not zero
    if (horizontalInterval == 0) {
      horizontalInterval = 1;
    }
    if (verticalInterval == 0) {
      verticalInterval = 1;
    }

    return _chartType == 'Line'
        ? LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: _dataPoints,
                  isCurved: false,
                  color: lineColor,
                  belowBarData: BarAreaData(show: false),
                ),
              ],
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
                  axisNameWidget: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Days',
                      style: TextStyle(
                        color: axisTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  axisNameSize: 30,
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final convertedValue =
                          widget.isKg ? value : value * 2.20462;
                      return Text(
                        convertedValue.toStringAsFixed(1),
                        style: TextStyle(
                          color: axisTextColor,
                          fontSize: 12,
                        ),
                      );
                    },
                    reservedSize:
                        50, // Ensure enough space for the Y-axis labels
                    interval: horizontalInterval,
                  ),
                  axisNameWidget: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      widget.isKg ? 'Weight [kg]' : 'Weight [lbs]',
                      style: TextStyle(
                        color: axisTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  axisNameSize: 30,
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
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: axisTextColor, // Set the color for the border
                  width: 0.75, // Set the width for the border
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: true,
                horizontalInterval: horizontalInterval,
                verticalInterval: verticalInterval,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey,
                    strokeWidth: 0.5,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Colors.grey,
                    strokeWidth: 0.5,
                  );
                },
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                handleBuiltInTouches: true,
              ),
            ),
          )
        : ScatterChart(
            ScatterChartData(
              scatterSpots: _dataPoints,
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
                  axisNameWidget: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Days',
                      style: TextStyle(
                        color: axisTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  axisNameSize: 30,
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final convertedValue =
                          widget.isKg ? value : value * 2.20462;
                      return Text(
                        convertedValue.toStringAsFixed(1),
                        style: TextStyle(
                          color: axisTextColor,
                          fontSize: 12,
                        ),
                      );
                    },
                    reservedSize:
                        50, // Ensure enough space for the Y-axis labels
                    interval: horizontalInterval,
                  ),
                  axisNameWidget: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      widget.isKg ? 'Weight [kg]' : 'Weight [lbs]',
                      style: TextStyle(
                        color: axisTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  axisNameSize: 30,
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
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: axisTextColor, // Set the color for the border
                  width: 0.75, // Set the width for the border
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: true,
                horizontalInterval: horizontalInterval,
                verticalInterval: verticalInterval,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey,
                    strokeWidth: 0.5,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Colors.grey,
                    strokeWidth: 0.5,
                  );
                },
              ),
              scatterTouchData: ScatterTouchData(
                enabled: true,
                handleBuiltInTouches: true,
              ),
            ),
          );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta, Color textColor) {
    const double reservedSize = 50.0;

    // Convert the value back to a date
    final date = DateTime.now().add(Duration(days: value.toInt()));
    final formattedDate = DateFormat('MM/dd').format(date);

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: SizedBox(
        width: reservedSize,
        child: Text(
          formattedDate,
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
    const double reservedSize = 30.0;

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
}
