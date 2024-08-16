import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../core/database.dart';

class SummaryTab extends StatefulWidget {
  final DateTime selectedDay;
  final Function(DateTime) onDateSelected;

  SummaryTab({required this.selectedDay, required this.onDateSelected});

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
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(color: Colors.white),
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
                        color: Colors.red,
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
    List<String> exercises = await _dbHelper.getPredefinedExercises();
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            return ListTile(
              title: Text(exercise),
              onTap: () async {
                final dailyRecords = await _dbHelper.getDailyRecordsForExercise(exercise);
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('View Mode: '),
                ToggleButtons(
                  isSelected: [_isExerciseView, !_isExerciseView],
                  onPressed: (int index) {
                    setState(() {
                      _isExerciseView = index == 0;
                    });
                  },
                  children: const <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Exercise View'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Day View'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            _isExerciseView
                ? Row(
                    children: [
                      const Text('Select Exercise: '),
                      TextButton(
                        onPressed: () => _showExerciseSelectionModal(context),
                        child: Text(_selectedExercise ?? 'None'),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Text('Select Day: '),
                      TextButton(
                        onPressed: () => _showCalendarModal(context),
                        child: Text(
                            '${widget.selectedDay.year}-${widget.selectedDay.month}-${widget.selectedDay.day}'),
                      ),
                    ],
                  ),
            const SizedBox(height: 20),
            _isExerciseView && _selectedExercise != null
                ? _dailyRecords.isEmpty
                    ? const Text('No data available for selected exercise')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _dailyRecords.entries.map((entry) {
                          final day = entry.key;
                          final records = entry.value;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                  child: Text(
                                    '${day.year}-${day.month}-${day.day}',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                ...records.map((record) {
                                  return ListTile(
                                    title: Text(
                                        'Sets: ${record['sets']}, Reps: ${record['reps']}, Weight: ${record['weight']} kg'),
                                    subtitle: Text('Timestamp: ${record['timestamp']}'),
                                  );
                                }).toList(),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                : FutureBuilder<Map<String, dynamic>>(
                    future: _dbHelper.getSummaryForDay(widget.selectedDay),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('No data available for selected day');
                      }

                      final summaryData = snapshot.data!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: summaryData.entries.map((entry) {
                          final exercise = entry.key;
                          final details = entry.value as Map<String, dynamic>;
                          final totalWeight = details['totalWeight'];
                          final totalSets = details['totalSets'];
                          final totalReps = details['totalReps'];
                          final avgWeight = details['avgWeight'];
                          final records =
                              details['records'] as List<Map<String, dynamic>>;

                          return Card(
                            child: ExpansionTile(
                              title: Text(exercise),
                              subtitle: Text(
                                  'Total Weight: ${totalWeight.toStringAsFixed(1)} kg, Sets: $totalSets, Reps: $totalReps, Avg Weight per Set: ${avgWeight.toStringAsFixed(1)} kg'),
                              children: records.map((record) {
                                return ListTile(
                                  title: Text(
                                      'Sets: ${record['sets']}, Reps: ${record['reps']}, Weight: ${record['weight']} kg'),
                                  subtitle: Text('Timestamp: ${record['timestamp']}'),
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
