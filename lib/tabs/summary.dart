import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../core/database.dart';

class SummaryTab extends StatefulWidget {
  final DateTime selectedDay;
  final Function(DateTime) onDateSelected;
  final bool isKg;

  const SummaryTab({
    Key? key,
    required this.selectedDay,
    required this.onDateSelected,
    required this.isKg,
  }) : super(key: key);

  @override
  _SummaryTabState createState() => _SummaryTabState();
}

class _SummaryTabState extends State<SummaryTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<DateTime> _trainedDates = [];
  bool _isExerciseView = false;
  String? _selectedExercise;
  Map<DateTime, List<Map<String, dynamic>>> _dailyRecords = {};

  @override
  void initState() {
    super.initState();
    _loadTrainedDates();
  }

  Future<void> _loadTrainedDates() async {
    List<DateTime> dates = await _dbHelper.getExerciseDates();
    setState(() {
      _trainedDates = dates;
    });
  }

  Future<void> _showCalendarModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return TableCalendar(
          focusedDay: widget.selectedDay,
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.now(),
          selectedDayPredicate: (day) => isSameDay(day, widget.selectedDay),
          calendarFormat: CalendarFormat.month,
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              widget.onDateSelected(selectedDay);
              _isExerciseView = false;
            });
            Navigator.of(context).pop();
          },
          eventLoader: (day) {
            return _trainedDates.where((d) => isSameDay(d, day)).toList();
          },
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleTextStyle:
                TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            todayTextStyle:
                TextStyle(color: Theme.of(context).colorScheme.onBackground),
            markersMaxCount: 1,
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (_trainedDates.any((d) => isSameDay(d, date))) {
                return Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 2.0,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Future<void> _showExerciseSelectionModal(BuildContext context) async {
    List<String> exercises = await _dbHelper.getRecordedExercises();
    exercises.sort();
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        if (exercises.isEmpty) {
          return Center(
            child: Text('No exercises recorded yet.'),
          );
        } else {
          return ListView.builder(
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return ListTile(
                title: Text(exercise),
                onTap: () async {
                  final dailyRecords =
                      await _dbHelper.getDailyRecordsForExercise(exercise);
                  setState(() {
                    _selectedExercise = exercise;
                    _dailyRecords = dailyRecords;
                    _isExerciseView = true;
                  });
                  Navigator.of(context).pop();
                },
              );
            },
          );
        }
      },
    );
  }

  Future<void> _loadLastLoggedExercise() async {
    List<String> exercises = await _dbHelper.getRecordedExercises();
    exercises.sort();
    if (exercises.isNotEmpty) {
      final lastExercise = await _dbHelper.getLastLoggedExerciseName();
      final dailyRecords =
          await _dbHelper.getDailyRecordsForExercise(lastExercise!);
      setState(() {
        _selectedExercise = lastExercise;
        _dailyRecords = dailyRecords;
      });
    }
  }

  double _convertWeight(double weightInKg) {
    return widget.isKg ? weightInKg : weightInKg * 2.20462;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _isExerciseView
                    ? const Text('Select Exercise: ')
                    : const Text('Select Day: '),
                _isExerciseView
                    ? TextButton(
                        onPressed: () => _showExerciseSelectionModal(context),
                        child: Text(_selectedExercise ?? 'None',
                            style: TextStyle(color: textColor)),
                      )
                    : TextButton(
                        onPressed: () => _showCalendarModal(context),
                        child: Text(
                            '${widget.selectedDay.year}-${widget.selectedDay.month}-${widget.selectedDay.day}',
                            style: TextStyle(color: textColor)),
                      ),
                SizedBox(width: 8), // Add space between button and icon
                IconButton(
                  icon: Icon(
                    _isExerciseView
                        ? Icons.calendar_today
                        : Icons.fitness_center,
                    color: primaryColor,
                  ),
                  onPressed: () async {
                    setState(() {
                      _isExerciseView = !_isExerciseView;
                    });
                    if (_isExerciseView) {
                      await _loadLastLoggedExercise();
                    } else {
                      // Clear exercise data when switching to Day View
                      _selectedExercise = null;
                      _dailyRecords = {};
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            _isExerciseView && _selectedExercise != null
                ? _dailyRecords.isEmpty
                    ? Text('No data available for selected exercise',
                        style: TextStyle(color: textColor))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _dailyRecords.entries.map((entry) {
                          final day = entry.key;
                          final records = entry.value;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            color: cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side: BorderSide(
                                color: primaryColor.withOpacity(0.5),
                                width: 1.0,
                              ),
                            ),
                            elevation: 4,
                            child: ExpansionTile(
                              title: Text(
                                '${day.year}-${day.month}-${day.day}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: primaryColor,
                                ),
                              ),
                              children: records.map((record) {
                                final weightStr = record['weight'] as String;
                                final weight =
                                    double.tryParse(weightStr) ?? 0.0;
                                final convertedWeight = _convertWeight(weight);
                                return ListTile(
                                  title: Text(
                                      'Sets: ${record['sets']}, Reps: ${record['reps']}, Weight: ${convertedWeight.toStringAsFixed(1)} ${widget.isKg ? 'kg' : 'lbs'}'),
                                  subtitle:
                                      Text('Timestamp: ${record['timestamp']}'),
                                );
                              }).toList(),
                            ),
                          );
                        }).toList(),
                      )
                : _isExerciseView
                    ? Text('Please select an exercise to view data.',
                        style: TextStyle(color: textColor))
                    : FutureBuilder<Map<String, dynamic>>(
                        future: _dbHelper.getSummaryForDay(widget.selectedDay),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}',
                                style: TextStyle(color: textColor));
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return Text('No data available for selected day',
                                style: TextStyle(color: textColor));
                          }

                          final summaryData = snapshot.data!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: summaryData.entries.map((entry) {
                              final exercise = entry.key;
                              final details =
                                  entry.value as Map<String, dynamic>;
                              final totalWeight = details['totalWeight'];
                              final totalSets = details['totalSets'];
                              final totalReps = details['totalReps'];
                              final avgWeight = details['avgWeight'];
                              final records = details['records']
                                  as List<Map<String, dynamic>>;

                              final displayTotalWeight =
                                  _convertWeight(totalWeight);
                              final displayAvgWeight =
                                  _convertWeight(avgWeight);

                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                color: cardColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  side: BorderSide(
                                    color: primaryColor.withOpacity(0.5),
                                    width: 1.0,
                                  ),
                                ),
                                elevation: 4,
                                child: ExpansionTile(
                                  title: Text(exercise,
                                      style: TextStyle(color: textColor)),
                                  subtitle: Text(
                                      'Total Weight: ${displayTotalWeight.toStringAsFixed(1)} ${widget.isKg ? 'kg' : 'lbs'}, Total Sets: $totalSets, Total Reps: $totalReps, Avg Weight: ${displayAvgWeight.toStringAsFixed(1)} ${widget.isKg ? 'kg' : 'lbs'}',
                                      style: TextStyle(color: textColor)),
                                  children: records.map((record) {
                                    final weightStr =
                                        record['weight'] as String;
                                    final weight =
                                        double.tryParse(weightStr) ?? 0.0;
                                    final convertedWeight =
                                        _convertWeight(weight);
                                    return ListTile(
                                      title: Text(
                                          'Sets: ${record['sets']}, Reps: ${record['reps']}, Weight: ${convertedWeight.toStringAsFixed(1)} ${widget.isKg ? 'kg' : 'lbs'}'),
                                      subtitle: Text(
                                          'Timestamp: ${record['timestamp']}'),
                                    );
                                  }).toList(),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
