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

  final List<String> _predefinedVariables = ["Benchpress", "Pullup", "Knee Lift"];
  String? _selectedPredefinedVariable;

  Future<void> _addVariable() async {
    if (_formKey.currentState!.validate()) {
      final variableName = _selectedPredefinedVariable ?? _variableNameController.text;
      await _dbHelper.insertVariable(
        variableName,
        _variableValueController.text,
      );
      _variableNameController.clear();
      _variableValueController.clear();
      setState(() {
        _selectedPredefinedVariable = null;
      });
      widget.onVariableAdded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: 'Select Predefined Variable'),
            items: _predefinedVariables.map((variable) {
              return DropdownMenuItem<String>(
                value: variable,
                child: Text(variable),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPredefinedVariable = value;
                _variableNameController.clear();
              });
            },
            value: _selectedPredefinedVariable,
          ),
          TextFormField(
            controller: _variableNameController,
            decoration: InputDecoration(labelText: 'Variable Name (or enter custom)'),
            validator: (value) {
              if (_selectedPredefinedVariable == null && (value == null || value.isEmpty)) {
                return 'Please enter a variable name or select one';
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
