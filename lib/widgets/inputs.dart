import 'package:flutter/material.dart';
import '../core/database.dart';

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

  String? _selectedExercise;
  bool _isAddingNewExercise = false;

  List<String> _predefinedExercises = [];

  @override
  void initState() {
    super.initState();
    _loadPredefinedExercises();
  }

  Future<void> _loadPredefinedExercises() async {
    List<String> exercises = await _dbHelper.getPredefinedExercises();
    setState(() {
      _predefinedExercises = exercises;
      _selectedExercise = _predefinedExercises.isNotEmpty ? _predefinedExercises.first : null;
    });
  }

  Future<void> _addExercise() async {
    if (_formKey.currentState!.validate()) {
      final exerciseName = _isAddingNewExercise
          ? _exerciseNameController.text.trim()
          : _selectedExercise!;
      
      await _dbHelper.insertExercise(exerciseName, _exerciseValueController.text);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Exercise added successfully'),
        duration: Duration(seconds: 2),
      ));

      if (_isAddingNewExercise) {
        await _dbHelper.addPredefinedExercise(exerciseName);
        setState(() {
          _predefinedExercises.add(exerciseName);
          _selectedExercise = exerciseName;
        });
      }

      _exerciseNameController.clear();
      _exerciseValueController.clear();
      setState(() {
        _isAddingNewExercise = false;
      });

      widget.onExerciseAdded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Select Exercise'),
                  items: [
                    ..._predefinedExercises.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }),
                    DropdownMenuItem<String>(
                      value: 'custom',
                      child: Text('Add New Exercise'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      if (value == 'custom') {
                        _isAddingNewExercise = true;
                        _selectedExercise = null;
                      } else {
                        _isAddingNewExercise = false;
                        _selectedExercise = value;
                      }
                      _exerciseNameController.clear();
                    });
                  },
                  value: _selectedExercise,
                  isExpanded: true,
                  iconSize: 24.0,
                  icon: Icon(Icons.arrow_drop_down),
                  elevation: 16,
                  style: TextStyle(color: Colors.black),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select or enter an exercise';
                    }
                    if (value == 'custom' && !_isAddingNewExercise) {
                      return 'Please select or enter an exercise';
                    }
                    return null;
                  },
                  dropdownColor: Colors.white,
                ),
              ),
              SizedBox(width: 16.0),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _exerciseNameController,
                  enabled: _isAddingNewExercise,
                  decoration: InputDecoration(
                    labelText: 'Exercise Name (or enter custom)',
                    enabled: _isAddingNewExercise,
                  ),
                  validator: (value) {
                    if (_isAddingNewExercise && (value == null || value.isEmpty)) {
                      return 'Please enter an exercise name';
                    }
                    return null;
                  },
                ),
              ),
            ],
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
