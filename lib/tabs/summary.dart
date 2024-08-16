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
  List<String> _predefinedExercises = [];
  String? _selectedExercise;
  bool _isDayView = true; // Toggle state

  @override
  void initState() {
    super.initState();
    _loadTrainedDates();
    _loadPredefinedExercises();
  }

  Future<void> _loadTrainedDates() async {
    List<DateTime> dates = await _dbHelper.getExerciseDates();
    setState(() {
      _trainedDates = dates;
    });
  }

  Future<void> _loadPredefinedExercises() async {
    List<String> exercises = await _dbHelper.getPredefinedExercises();
    setState(() {
      _predefinedExercises = exercises;
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
            });
            Navigator.of(context).pop(); // Close the modal after selection
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _showCalendarModal(context),
                  child: Text(
                      '${widget.selectedDay.year}-${widget.selectedDay.month}-${widget.selectedDay.day}'),
                ),
                Switch(
                  value: _isDayView,
                  onChanged: (value) {
                    setState(() {
                      _isDayView = value;
                      _selectedExercise = null;
                    });
                  },
                  activeColor: Colors.blueAccent,
                  activeTrackColor: Colors.blueAccent.withOpacity(0.3),
                  inactiveThumbColor: Colors.orange,
                  inactiveTrackColor: Colors.orange.withOpacity(0.3),
                ),
                Text(_isDayView ? 'Day View' : 'Exercise View'),
              ],
            ),
            if (!_isDayView)
              DropdownButton<String>(
                value: _selectedExercise,
                hint: Text('Select Exercise'),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedExercise = newValue!;
                  });
                },
                items: _predefinedExercises
                    .map<DropdownMenuItem<String>>((String exercise) {
                  return DropdownMenuItem<String>(
                    value: exercise,
                    child: Text(exercise),
                  );
                }).toList(),
              ),
            FutureBuilder<Map<String, dynamic>>(
              future: _isDayView
                  ? _dbHelper.getSummaryForDay(widget.selectedDay)
                  : (_selectedExercise != null
                      ? _dbHelper.getSummaryForExercise(_selectedExercise!)
                      : Future.value({})),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No data available for selected view');
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
