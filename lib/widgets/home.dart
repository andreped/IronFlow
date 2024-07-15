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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
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
              const Tab(icon: Icon(Icons.add), text: 'Log Exercise'),
              Tab(icon: Icon(Icons.table_chart), text: 'View Table'),
              Tab(icon: Icon(Icons.show_chart), text: 'Visualize Data'),
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
                    final variables = snapshot.data!;
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
                        rows: variables.map((variable) {
                          return DataRow(cells: [
                            DataCell(Text(variable['id'].toString())),
                            DataCell(Text(variable['exercise'])),
                            DataCell(Text(variable['weight'])),
                            DataCell(Text(variable['reps'].toString())),
                            DataCell(Text(variable['sets'].toString())),
                            DataCell(Text(variable['timestamp'])),
                            DataCell(
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () async {
                                  await _deleteExercise(variable['id']);
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
            // Visualize Data Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: VisualizationTab(),
            ),
          ],
        ),
      ),
    );
  }
}
