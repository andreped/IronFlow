import 'package:flutter/material.dart';
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != widget.selectedDay) {
      widget.onDateSelected(picked);
    }
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
                  onPressed: () => _selectDate(context),
                  child: Text('${widget.selectedDay.year}-${widget.selectedDay.month}-${widget.selectedDay.day}'),
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
                    final records = details['records'] as List<Map<String, dynamic>>;

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
