import 'package:flutter/material.dart';
import 'database.dart';
import 'visualization.dart';
import 'helpers.dart';

class VariableStoreApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IronFlow',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: VariableStoreHomePage(),
    );
  }
}

class VariableStoreHomePage extends StatefulWidget {
  @override
  _VariableStoreHomePageState createState() => _VariableStoreHomePageState();
}

class _VariableStoreHomePageState extends State<VariableStoreHomePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> _clearDatabase() async {
    await _dbHelper.clearDatabase();
    setState(() {});
  }

  Future<List<Map<String, dynamic>>> _getVariables() async {
    return await _dbHelper.getVariables();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('IronFlow'),
          actions: [
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                await _clearDatabase();
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.add), text: 'Log Exercise'),
              Tab(icon: Icon(Icons.table_chart), text: 'View Table'),
              Tab(icon: Icon(Icons.show_chart), text: 'Visualize Data'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: ExerciseSetter(
                onVariableAdded: () {
                  setState(() {});
                },
              ),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getVariables(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final variables = snapshot.data!;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Value')),
                      DataColumn(label: Text('Timestamp')),
                    ],
                    rows: variables.map((variable) {
                      return DataRow(cells: [
                        DataCell(Text(variable['id'].toString())),
                        DataCell(Text(variable['name'])),
                        DataCell(Text(variable['value'])),
                        DataCell(Text(variable['timestamp'])),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
            VisualizationTab(),
          ],
        ),
      ),
    );
  }
}
