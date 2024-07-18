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
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();

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

  List<Map<String, dynamic>> _filterExercises(List<Map<String, dynamic>> exercises) {
    if (_searchQuery.isEmpty) {
      return exercises;
    }
    return exercises.where((exercise) {
      return exercise['exercise'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
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
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search Exercises',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _getExercises(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final exercises = _filterExercises(snapshot.data!);
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
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        await _deleteExercise(exercise['id']);
                                      },
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
                ),
              ],
            ),
            // Visualize Data Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: VisualizationTab(),
            ),
            // Summary Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
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
                  FutureBuilder<Map<String, double>>(
                    future: _dbHelper.getTotalWeightForDay(_selectedDay),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('No data available for selected day');
                      }

                      final totalWeights = snapshot.data!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: totalWeights.entries.map((entry) {
                          return Card(
                            child: ListTile(
                              title: Text(entry.key),
                              subtitle: Text('Total Weight: ${entry.value}'),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
