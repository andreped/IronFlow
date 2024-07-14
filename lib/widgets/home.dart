import 'package:flutter/material.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _variableNameController = TextEditingController();
  final _variableValueController = TextEditingController();
  final Map<String, String> _variables = {};

  void _addVariable() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _variables[_variableNameController.text] = _variableValueController.text;
        _variableNameController.clear();
        _variableValueController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('IronFlow'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _variableNameController,
                    decoration: InputDecoration(labelText: 'Training exercise'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter information on exercise';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _variableValueController,
                    decoration: InputDecoration(labelText: 'Variable Value'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter information on exercise';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _addVariable,
                    child: Text('Add Exercise'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: _variables.length,
                itemBuilder: (context, index) {
                  String key = _variables.keys.elementAt(index);
                  return ListTile(
                    title: Text('$key: ${_variables[key]}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
