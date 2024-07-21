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
  final _newExerciseController = TextEditingController();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _setsController = TextEditingController();
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
          ? _newExerciseController.text.trim()
          : _selectedExercise!;

      await _dbHelper.insertExercise(
        exercise: exerciseName,
        weight: _weightController.text,
        reps: int.parse(_repsController.text),
        sets: int.parse(_setsController.text),
      );

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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

      _newExerciseController.clear();
      _weightController.clear();
      _repsController.clear();
      _setsController.clear();
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
                  decoration: const InputDecoration(labelText: 'Select Exercise'),
                  items: [
                    ..._predefinedExercises.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }),
                    const DropdownMenuItem<String>(
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
                    });
                  },
                  value: _isAddingNewExercise ? 'custom' : _selectedExercise,
                  isExpanded: true,
                  iconSize: 24.0,
                  icon: const Icon(Icons.arrow_drop_down),
                  elevation: 16,
                  style: const TextStyle(color: Colors.black),
                  validator: (value) {
                    if (!_isAddingNewExercise && (value == null || value.isEmpty)) {
                      return 'Please select or enter an exercise';
                    }
                    return null;
                  },
                  dropdownColor: Colors.white,
                ),
              ),
            ],
          ),
          if (_isAddingNewExercise)
            TextFormField(
              controller: _newExerciseController,
              decoration: const InputDecoration(labelText: 'New Exercise Name'),
              validator: (value) {
                if (_isAddingNewExercise && (value == null || value.isEmpty)) {
                  return 'Please enter a new exercise name';
                }
                return null;
              },
            ),
          TextFormField(
            controller: _weightController,
            decoration: const InputDecoration(labelText: 'Weight'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the exercise weight';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _repsController,
            decoration: const InputDecoration(labelText: 'Reps'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the number of reps';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid integer';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _setsController,
            decoration: const InputDecoration(labelText: 'Sets'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the number of sets';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid integer';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: _addExercise,
            child: const Text('Add Exercise'),
          ),
        ],
      ),
    );
  }
}
