import 'package:flutter/material.dart';
import 'database.dart';
import 'constants.dart';

class ExerciseSetter extends StatefulWidget {
  final Function() onExerciseAdded;

  ExerciseSetter({required this.onExerciseAdded});

  @override
  _ExerciseSetterState createState() => _ExerciseSetterState();
}

class _ExerciseSetterState extends State<ExerciseSetter> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseNameController = TextEditingController();
  final _exerciseValueController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String? _selectedPredefinedExercise;

  Future<void> _addExercise() async {
    if (_formKey.currentState!.validate()) {
      final exerciseName = _selectedPredefinedExercise ?? _exerciseNameController.text;
      await _dbHelper.insertExercise(
        exerciseName,
        _exerciseValueController.text,
      );
      _exerciseNameController.clear();
      _exerciseValueController.clear();
      setState(() {
        _selectedPredefinedExercise = null;
      });
      widget.onExerciseAdded();
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
              items: predefinedExercises.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPredefinedExercise = value;
                  _exerciseNameController.clear();
                });
              },
              value: _selectedPredefinedExercise,
              isExpanded: true,
              iconSize: 24.0,
              icon: Icon(Icons.arrow_drop_down),
              elevation: 16,
              style: TextStyle(color: Colors.black),
              validator: (value) {
                if (_selectedPredefinedExercise == null && (value == null || value.isEmpty)) {
                  return 'Please enter an exercise name or select one';
                }
                return null;
              },
              dropdownColor: Colors.white,
              // Limit the number of items shown
              selectedItemBuilder: (BuildContext context) {
                return predefinedExercises.take(dropdownVisibleItemCount).map<Widget>((String value) {
                  return Text(value);
                }).toList();
              },
              // Allow scrolling to select items outside the visible range
              // The items are already specified above
            ),
          ),
          TextFormField(
            controller: _exerciseNameController,
            decoration: InputDecoration(labelText: 'Exercise Name (or enter custom)'),
            validator: (value) {
              if (_selectedPredefinedExercise == null && (value == null || value.isEmpty)) {
                return 'Please enter an exercise name or select one';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _exerciseValueController,
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
