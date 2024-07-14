import 'package:flutter/material.dart';
import 'database.dart';
import 'constants.dart';

class ExerciseSetter extends StatefulWidget {
  final Function() onVariableAdded;

  ExerciseSetter({required this.onVariableAdded});

  @override
  _ExerciseSetterState createState() => _ExerciseSetterState();
}

class _ExerciseSetterState extends State<ExerciseSetter> {
  final _formKey = GlobalKey<FormState>();
  final _variableNameController = TextEditingController();
  final _variableValueController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String? _selectedPredefinedVariable;

  Future<void> _addExercise() async {
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
          SizedBox(
            height: 72, // Adjust the height as needed
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Select Predefined Exercise'),
              items: predefinedVariables.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPredefinedVariable = value;
                  _variableNameController.clear();
                });
              },
              value: _selectedPredefinedVariable,
              isExpanded: true,
              iconSize: 24.0,
              icon: Icon(Icons.arrow_drop_down),
              elevation: 16,
              style: TextStyle(color: Colors.black),
              validator: (value) {
                if (_selectedPredefinedVariable == null && (value == null || value.isEmpty)) {
                  return 'Please enter an exercise name or select one';
                }
                return null;
              },
              dropdownColor: Colors.white,
              // Limit the number of items shown
              selectedItemBuilder: (BuildContext context) {
                return predefinedVariables.take(dropdownVisibleItemCount).map<Widget>((String value) {
                  return Text(value);
                }).toList();
              },
              // Allow scrolling to select items outside the visible range
              // The items are already specified above
            ),
          ),
          TextFormField(
            controller: _variableNameController,
            decoration: InputDecoration(labelText: 'Exercise Name (or enter custom)'),
            validator: (value) {
              if (_selectedPredefinedVariable == null && (value == null || value.isEmpty)) {
                return 'Please enter an exercise name or select one';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _variableValueController,
            decoration: InputDecoration(labelText: 'Exercise Value'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an exercise value';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid integer';
              }
              return null;
            },
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: _addExercise,
            child: Text('Add Exercise'),
          ),
        ],
      ),
    );
  }
}
