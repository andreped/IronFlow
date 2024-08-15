import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';  // Import TableCalendar
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
  Map<DateTime, List<dynamic>> _events = {}; // To store events for each day

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    // Load events from your database or any source
    // Here you would populate the _events map with the dates that have been trained.
    // For example:
    // _events[DateTime(2024, 8, 14)] = [...]; // List of events for the date
    // You may need to adjust this based on your actual data structure.
    // You can also use this example to manually add events:
    // _events[DateTime.now()] = ['Event 1', 'Event 2'];

    // Call setState to update the UI with loaded events
    setState(() {});
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
            Navigator.of(context).pop();  // Close the modal after selection
          },
          eventLoader: (day) {
            // Provide events for the day
            return _events[day] ?? [];
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
              children: [
                const Text('Select Day: '),
                TextButton(
                  onPressed: () => _showCalendarModal(context),
                  child: Text(
                      '${widget.selectedDay.year}-${widget.selectedDay.month}-${widget.selectedDay.day}'),
                ),
              ],
            ),
            FutureBuilder<Map<String, dynamic>>(
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
                            'Total Weight: ${totalWeight.toStringAsFixed(2)} kg, Sets: $totalSets, Reps: $totalReps, Avg Weight per Set: ${avgWeight.toStringAsFixed(2)} kg'),
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
