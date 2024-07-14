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
              icon: const Icon(Icons.delete),
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
                      columns: [
                        const DataColumn(label: Text('ID')),
                        const DataColumn(label: Text('Exercise')),
                        const DataColumn(label: Text('Weight')),
                        const DataColumn(label: Text('Timestamp')),
                      ],
                      rows: variables.map((variable) {
                        return DataRow(cells: [
                          DataCell(Text(variable['id'].toString())),
                          DataCell(Text(variable['exercise'])),
                          DataCell(Text(variable['weight'])),
                          DataCell(Text(variable['timestamp'])),
                        ]);
                      }).toList(),
                    ),
                  );
                },
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
