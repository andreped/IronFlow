import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/data_service.dart';
import '../services/logger_service.dart';
import '../widgets/charts/chart_widget.dart';
import '../widgets/dropdown/dropdown_widget.dart';
import '../widgets/toggle/toggle_buttons_widget.dart';
import '../models/fitness_data.dart';
import '../models/exercise.dart';
import '../core/database.dart';

class VisualizationTab extends StatefulWidget {
  final bool isKg;
  final bool bodyweightEnabledGlobal;
  final String defaultAggregationMethod;
  final String defaultChartType;

  const VisualizationTab({
    super.key,
    required this.isKg,
    required this.bodyweightEnabledGlobal,
    required this.defaultAggregationMethod,
    required this.defaultChartType,
  });

  @override
  VisualizationTabState createState() => VisualizationTabState();
}

class VisualizationTabState extends State<VisualizationTab> {
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

  final DataService _dataService = DataService();
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
    LoggerService.logger.info('Fetching names from $_selectedTable table...');
    try {
      Set<String> names = {};
      if (_selectedTable == 'Exercise') {
        // fetch recorded exercises
        List<Exercise> variables = await _dataService.fetchExercises();
        print(variables);
        names = variables.map((entry) => entry.name).toSet();
      } else {
        // fetch fitness data
        List<FitnessData> variables = await _dataService.fetchFitnessData();
        names = variables.map((entry) => entry.exercise).toSet();
      }

      // sort names if not empty
      List<String> sortedNames = names.toList();
      if (sortedNames.isNotEmpty) {
        sortedNames.sort();
      }

      // Debugging: Print fetched exercise names
      print('Fetched exercise names: $sortedNames');

      // update states
      setState(() {
        _exerciseNames = sortedNames;
        if (_selectedExercise != null &&
            !_exerciseNames.contains(_selectedExercise)) {
          _selectedExercise = null;
        }
      });

      // render last recorded exercise by default if any
      if (_exerciseNames.isNotEmpty && _selectedExercise == null) {
        try {
          String? lastRecordedExercise =
              await _dbHelper.getLastLoggedExerciseName();
          if (lastRecordedExercise != null &&
              _exerciseNames.contains(lastRecordedExercise)) {
            setState(() {
              _selectedExercise = lastRecordedExercise;
              _fetchDataPoints(_selectedExercise);
            });
          }
        } catch (e) {
          LoggerService.logger
              .severe('Error fetching last recorded exercise: $e');
        }
      }

      // Fetch data points for the default data type if Fitness table is selected
      if (_selectedTable == 'Fitness') {
        _fetchDataPoints(null);
      }
    } catch (e) {
      LoggerService.logger.severe('Error fetching names: $e');
    }
  }

  Future<void> _fetchDataPoints(String? exerciseName) async {
    LoggerService.logger.info('Fetching data points for: $exerciseName');

    // Clear existing data points
    setState(() {
      _dataPoints = [];
    });

    List<dynamic> records = [];

    if (_selectedTable == 'Exercise') {
      records = await _dataService.fetchExercises();
    } else if (_selectedTable == 'Fitness') {
      records = await _dataService.fetchFitnessData();
    }

    // Filter records by exercise name if provided
    if (exerciseName != null) {
      if (_selectedTable == 'Exercise') {
        records =
            records.where((record) => record.name == exerciseName).toList();
      } else if (_selectedTable == 'Fitness') {
        records =
            records.where((record) => record.exercise == exerciseName).toList();
      }
    }

    // Filter records by date range
    List<dynamic> filteredRecords =
        _dataService.filterDataByDateRange(records, _selectedDateRange);

    // If no records are found within the selected date range, adjust the date range to include all records for the selected exercise
    if (filteredRecords.isEmpty) {
      if (records.isNotEmpty) {
        final earliestRecordDate = records
            .map((record) => record.timestamp)
            .reduce((a, b) => a.isBefore(b) ? a : b);
        _selectedDateRange =
            DateTimeRange(start: earliestRecordDate, end: DateTime.now());
        filteredRecords =
            _dataService.filterDataByDateRange(records, _selectedDateRange);
      }
    }

    // Group records by day
    Map<DateTime, List<dynamic>> recordsByDay = {};
    for (var record in filteredRecords) {
      DateTime date = DateUtils.dateOnly(record.timestamp);
      if (!recordsByDay.containsKey(date)) {
        recordsByDay[date] = [];
      }
      recordsByDay[date]!.add(record);
    }

    // Debugging: Print grouped records by day
    print('Records grouped by day: ${recordsByDay.length}');

    // Aggregate data per day
    List<ScatterSpot> aggregatedDataPoints = [];
    recordsByDay.forEach((date, dailyRecords) {
      double value;
      switch (_aggregationMethod) {
        case 'Max':
          value = _dataService.aggregateMax(dailyRecords, _dataType);
          break;
        case 'Average':
          value = _dataService.aggregateAverage(dailyRecords, _dataType);
          break;
        case 'Total':
          value = _dataService.aggregateTotal(dailyRecords, _dataType);
          break;
        case 'Top3Avg':
          value = _dataService.aggregateTop3Avg(dailyRecords, _dataType);
          break;
        case 'Top3Tot':
          value = _dataService.aggregateTop3Tot(dailyRecords, _dataType);
          break;
        default:
          value = 0.0;
          break;
      }

      double dayDifference = date.difference(DateTime.now()).inDays.toDouble();
      double convertedValue = _convertValue(value);

      aggregatedDataPoints.add(ScatterSpot(
        dayDifference,
        convertedValue,
        dotPainter: FlDotCirclePainter(
          color: Theme.of(context).colorScheme.secondary,
          radius: 6,
        ),
      ));
    });

    // Calculate min and max y values dynamically
    double minY = aggregatedDataPoints.isNotEmpty
        ? aggregatedDataPoints
            .map((point) => point.y)
            .reduce((a, b) => a < b ? a : b)
        : 0.0;
    double maxY = aggregatedDataPoints.isNotEmpty
        ? aggregatedDataPoints
            .map((point) => point.y)
            .reduce((a, b) => a > b ? a : b)
        : 100.0;

    setState(() {
      _dataPoints = aggregatedDataPoints;
      _minX = _dataPoints.isNotEmpty
          ? _dataPoints.map((point) => point.x).reduce((a, b) => a < b ? a : b)
          : 0.0;
      _maxX = _dataPoints.isNotEmpty
          ? _dataPoints.map((point) => point.x).reduce((a, b) => a > b ? a : b)
          : 0.0;
      _minY = minY;
      _maxY = maxY;
    });

    // Debugging: Print final data points
    print('Final data points: ${_dataPoints.length}');
  }

  double _convertValue(double value) {
    if (_selectedTable == 'Fitness') {
      switch (_dataType) {
        case 'Weight':
          return widget.isKg
              ? value
              : value * 2.20462; // Convert to lbs if needed
        case 'Height':
          return value; // Assuming height is already in the desired unit
        case 'Age':
          return value; // Age doesn't need conversion
        default:
          return value;
      }
    }
    return value;
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
    final scatterColor = theme.colorScheme.primary;
    final lineColor = theme.colorScheme.primary;
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
              DropdownWidget(
                value: _selectedTable,
                items: ['Exercise', 'Fitness'],
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
                hint: 'Select Table',
                theme: theme,
              ),
              const SizedBox(height: 8.0),
              if (_selectedTable == 'Exercise')
                DropdownWidget(
                  value: _selectedExercise ?? '',
                  items: _exerciseNames,
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _dataPoints = []; // Clear the data points
                        _selectedExercise = newValue;
                      });
                      _fetchDataPoints(newValue);
                    }
                  },
                  hint: 'Select Exercise',
                  theme: theme,
                ),
              if (_selectedTable == 'Fitness')
                DropdownWidget(
                  value: _dataType,
                  items: ['Weight', 'Height', 'Age'],
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _dataType = newValue;
                        _fetchDataPoints(_selectedExercise);
                      });
                    }
                  },
                  hint: 'Select Data Type',
                  theme: theme,
                ),
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
                    : Container(
                        padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                        child: ChartWidget(
                          dataPoints: _dataPoints,
                          chartType: _chartType,
                          scatterColor: scatterColor,
                          lineColor: lineColor,
                          axisTextColor: axisTextColor,
                          isKg: widget.isKg,
                        ),
                      ),
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 110,
                    child: DropdownWidget(
                      value: _aggregationMethod,
                      items: ['Max', 'Average', 'Total', 'Top3Avg', 'Top3Tot'],
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _aggregationMethod = newValue;
                            _fetchDataPoints(_selectedExercise);
                          });
                        }
                      },
                      hint: 'Select Agg',
                      theme: theme,
                    ),
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
                    child: ToggleButtonsWidget(
                      isSelected: [
                        _chartType == 'Line',
                        _chartType == 'Scatter'
                      ],
                      onPressed: (int index) {
                        setState(() {
                          _chartType = index == 0 ? 'Line' : 'Scatter';
                        });
                      },
                      icons: [
                        Icon(Icons.show_chart, color: theme.iconTheme.color),
                        Icon(Icons.scatter_plot, color: theme.iconTheme.color),
                      ],
                    ),
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
}
