import 'package:flutter/material.dart';
import '../core/database.dart';
import 'visualization.dart';
import 'inputs.dart';

class ExerciseStoreApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IronFlow',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ExerciseStoreHomePage(),
    );
  }
}

class ExerciseStoreHomePage extends StatefulWidget {
  @override
  _ExerciseStoreHomePageState createState() => _ExerciseStoreHomePageState();
}

class _ExerciseStoreHomePageState extends State<ExerciseStoreHomePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  DateTime _selectedDay = DateTime.now();

  Future<void> _clearDatabase() async {
    await _dbHelper.clearDatabase();
    setState(() {});
  }

  Future<void> _deleteExercise(int id) async {
    await _dbHelper.deleteExercise(id);
    setState(() {});
  }

  Future<List<Map<String, dynamic>>> _getExercises() async {
    return await _dbHelper.getExercises();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDay) {
      setState(() {
        _selectedDay = picked;
      });
    }
  }

  void _showEditDialog(Map<String, dynamic> exercise) {
    TextEditingController weightController = TextEditingController(text: exercise['weight']);
    TextEditingController repsController = TextEditingController(text: exercise['reps'].toString());
    TextEditingController setsController = TextEditingController(text: exercise['sets'].toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Exercise'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: weightController,
                decoration: const InputDecoration(labelText: 'Weight'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: repsController,
                decoration: const InputDecoration(labelText: 'Reps'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: setsController,
                decoration: const InputDecoration(labelText: 'Sets'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                await _dbHelper.updateExercise(
                  id: exercise['id'],
                  weight: weightController.text,
                  reps: int.parse(repsController.text),
                  sets: int.parse(setsController.text),
                );
                setState(() {});
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('IronFlow'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () async {
                await _clearDatabase();
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.add), text: 'Log Exercise'),
              Tab(icon: Icon(Icons.table_chart), text: 'View Table'),
              Tab(icon: Icon(Icons.show_chart), text: 'Visualize Data'),
              Tab(icon: Icon(Icons.calendar_today), text: 'Summary'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Log Exercise Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ExerciseSetter(
                onExerciseAdded: () {
                  setState(() {});
                },
              ),
            ),
            // View Table Tab
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getExercises(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final exercises = snapshot.data!;
                    return SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Exercise')),
                          DataColumn(label: Text('Weight')),
                          DataColumn(label: Text('Reps')),
                          DataColumn(label: Text('Sets')),
                          DataColumn(label: Text('Timestamp')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: exercises.map((exercise) {
                          return DataRow(cells: [
                            DataCell(Text(exercise['id'].toString())),
                            DataCell(Text(exercise['exercise'])),
                            DataCell(Text(exercise['weight'])),
                            DataCell(Text(exercise['reps'].toString())),
                            DataCell(Text(exercise['sets'].toString())),
                            DataCell(Text(exercise['timestamp'])),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      _showEditDialog(exercise);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      await _deleteExercise(exercise['id']);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Visualize Data Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: VisualizationTab(),
            ),
            // Summary Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView( // Wrap with SingleChildScrollView
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Select Day: '),
                        TextButton(
                          onPressed: () => _selectDate(context),
                          child: Text('${_selectedDay.year}-${_selectedDay.month}-${_selectedDay.day}'),
                        ),
                      ],
                    ),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _dbHelper.getSummaryForDay(_selectedDay),
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
                                subtitle: Text('Total Weight: ${totalWeight.toStringAsFixed(2)} kg, Sets: $totalSets, Reps: $totalReps, Avg Weight per Set: ${avgWeight.toStringAsFixed(2)} kg'),
                                children: records.map((record) {
                                  return ListTile(
                                    title: Text('Sets: ${record['sets']}, Reps: ${record['reps']}, Weight: ${record['weight']} kg'),
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
            ),
          ],
        ),
      ),
    );
  }
}
