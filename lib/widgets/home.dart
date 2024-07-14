import 'package:flutter/material.dart';
import 'database.dart';
import 'visualization.dart';

class VariableStoreApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Variable Store App',
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
  final _formKey = GlobalKey<FormState>();
  final _variableNameController = TextEditingController();
  final _variableValueController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> _addVariable() async {
    if (_formKey.currentState!.validate()) {
      await _dbHelper.insertVariable(
        _variableNameController.text,
        _variableValueController.text,
      );
      _variableNameController.clear();
      _variableValueController.clear();
      setState(() {});
    }
  }

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
          title: Text('Variable Store App'),
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
              Tab(icon: Icon(Icons.add), text: 'Add Variable'),
              Tab(icon: Icon(Icons.table_chart), text: 'View Table'),
              Tab(icon: Icon(Icons.show_chart), text: 'Visualize Data'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _variableNameController,
                          decoration: InputDecoration(labelText: 'Variable Name'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a variable name';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _variableValueController,
                          decoration: InputDecoration(labelText: 'Variable Value'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a variable value';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid integer';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: _addVariable,
                          child: Text('Add Variable'),
                        ),
                      ],
                    ),
                  ),
                ],
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
