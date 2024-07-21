import 'package:flutter/material.dart';
import '../core/database.dart';
import 'visualization.dart';
import 'inputs.dart';
import 'exercise_edit_dialog.dart';

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

class _ExerciseStoreHomePageState extends State<ExerciseStoreHomePage> with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  DateTime _selectedDay = DateTime.now();
  late TabController _tabController;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ExerciseEditDialog(exerciseData: exercise);
      },
    ).then((result) async {
      if (result != null) {
        await _dbHelper.updateExercise(
          id: result['id'],
          exercise: result['exercise'],
          weight: result['weight'],
          reps: result['reps'],
          sets: result['sets'],
        );
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            _pageController.jumpToPage(index);
          },
          tabs: const [
            Tab(icon: Icon(Icons.add), text: 'Log\nExercise'),
            Tab(icon: Icon(Icons.table_chart), text: 'View\nTable'),
            Tab(icon: Icon(Icons.show_chart), text: 'Visualize\nData'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Summary'),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe gesture
        onPageChanged: (index) {
          _tabController.animateTo(index);
        },
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
                  return DataTable(
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabController.index,
        onTap: (index) {
          _tabController.animateTo(index);
          _pageController.jumpToPage(index); // Sync PageView with TabBar
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Log\nExercise'),
          BottomNavigationBarItem(icon: Icon(Icons.table_chart), label: 'View\nTable'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Visualize\nData'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Summary'),
        ],
      ),
    );
  }
}
