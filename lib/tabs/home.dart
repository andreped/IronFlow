import 'package:flutter/material.dart';
import '../core/database.dart';
import 'visualization.dart';
import 'inputs.dart';
import '../widgets/exercise_edit_dialog.dart';
import 'summary.dart';
import 'records.dart'; // Import the new records tab

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
  final PageStorageBucket bucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Update length to 5
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

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDay = date;
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
            Tab(icon: Icon(Icons.calendar_today), text: 'Summary'),
            Tab(icon: Icon(Icons.show_chart), text: 'Visualize\nData'),
            Tab(icon: Icon(Icons.table_chart), text: 'View\nTable'),
            Tab(icon: Icon(Icons.record_voice_over), text: 'Records'), // New Records tab
          ],
        ),
      ),
      body: PageStorage(
        bucket: bucket,
        child: PageView(
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
            // Summary Tab
            SummaryTab(
              selectedDay: _selectedDay,
              onDateSelected: _onDateSelected,
            ),
            // Visualize Data Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: VisualizationTab(key: PageStorageKey('visualizationTab')),
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
            // Records Tab
            RecordsTab(), // New Records tab
          ],
        ),
      ),
    );
  }
}
