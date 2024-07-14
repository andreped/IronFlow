import 'package:flutter/material.dart';
import 'database.dart';

class VariableSetter extends StatefulWidget {
  final Function() onVariableAdded;

  VariableSetter({required this.onVariableAdded});

  @override
  _VariableSetterState createState() => _VariableSetterState();
}

class _VariableSetterState extends State<VariableSetter> {
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
      widget.onVariableAdded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
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
    );
  }
}
