import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _setsController = TextEditingController(text: '1'); // Default sets to 1
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String? _selectedExercise;
  bool _isAddingNewExercise = false;
  String? _lastExerciseName;
  double? _lastWeight;
  int? _lastReps;
  int? _lastSets;

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
      _selectedExercise =
          _predefinedExercises.isNotEmpty ? _predefinedExercises.first : null;
      if (_selectedExercise != null) {
        _loadLastLoggedExercise();
      }
    });
  }

  Future<void> _loadLastLoggedExercise() async {
    if (_selectedExercise != null) {
      final lastLogged =
          await _dbHelper.getLastLoggedExercise(_selectedExercise!);
      if (lastLogged != null) {
        setState(() {
          _lastExerciseName = lastLogged['exercise'];
          _lastWeight = lastLogged['weight'];
          _lastReps = lastLogged['reps'];
          _lastSets = lastLogged['sets'];
          _weightController.text = _lastWeight?.toString() ?? '';
          _repsController.text = _lastReps?.toString() ?? '';
          _setsController.text = _lastSets?.toString() ?? '1';
        });
      }
    }
  }

  Future<void> _addOrUpdateExercise() async {
    // Manually trigger form validation
    if (_formKey.currentState!.validate()) {
      final exerciseName = _isAddingNewExercise
          ? _newExerciseController.text.trim()
          : _selectedExercise!;

      // Convert values to appropriate types
      final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
      final reps = int.tryParse(_repsController.text);
      final sets = int.tryParse(_setsController.text);

      if (weight == null || reps == null || sets == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please enter valid values'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ));
        return;
      }

      final isNewHighScore =
          await _dbHelper.isNewHighScore(exerciseName, weight, reps);

      await _dbHelper.insertExercise(
        exercise: exerciseName,
        weight: weight.toString(),
        reps: reps,
        sets: sets,
      );

      if (isNewHighScore) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🚀🎉 New high score for $exerciseName!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🎯 Exercise added successfully'),
          duration: Duration(seconds: 2),
        ));
      }

      if (_isAddingNewExercise) {
        await _dbHelper.addPredefinedExercise(exerciseName);
        setState(() {
          _predefinedExercises.add(exerciseName);
          _selectedExercise = exerciseName;
        });
      } else {
        _loadLastLoggedExercise();
      }

      _newExerciseController.clear();
      setState(() {
        _isAddingNewExercise = false;
      });

      widget.onExerciseAdded();
    }
  }

  void _showNumberInputSheet({
    required TextEditingController controller,
    required String label,
    required String initialValue,
    required bool isDouble, // Added to determine if value is double or int
  }) {
    final FocusNode focusNode = FocusNode();
    final TextEditingController localController = TextEditingController(text: initialValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      builder: (BuildContext context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus(focusNode);
        });

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(fontSize: 18)),
                TextField(
                  focusNode: focusNode,
                  controller: localController,
                  keyboardType: isDouble
                      ? TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[\d,.]+$')),
                  ],
                  decoration: InputDecoration(
                    labelText: label,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Handle type casting based on `isDouble`
                    final value = isDouble
                        ? double.tryParse(localController.text.replaceAll(',', '.'))
                        : int.tryParse(localController.text);
                    
                    if (value != null) {
                      setState(() {
                        controller.text = value.toString();
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Please enter a valid number'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.red,
                      ));
                    }
                  },
                  child: Text('Done'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openExerciseSelectionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Add New Exercise'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _isAddingNewExercise = true;
                  _selectedExercise = null;
                });
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _predefinedExercises.length,
                itemBuilder: (context, index) {
                  final exercise = _predefinedExercises[index];
                  return ListTile(
                    title: Text(exercise),
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditExerciseDialog(exercise);
                      },
                    ),
                    onTap: () {
                      setState(() {
                        _selectedExercise = exercise;
                        _isAddingNewExercise = false;
                      });
                      Navigator.pop(context);
                      _loadLastLoggedExercise();
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditExerciseDialog(String oldName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Exercise Name'),
          content: TextField(
            controller: _newExerciseController..text = oldName,
            decoration: InputDecoration(labelText: 'New Exercise Name'),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                final newName = _newExerciseController.text.trim();
                if (newName.isNotEmpty && newName != oldName) {
                  await _dbHelper.updatePredefinedExercise(oldName, newName);
                  await _dbHelper.updateExerciseName(oldName, newName);
                  setState(() {
                    final index = _predefinedExercises.indexOf(oldName);
                    if (index != -1) {
                      _predefinedExercises[index] = newName;
                      if (_selectedExercise == oldName) {
                        _selectedExercise = newName;
                      }
                    }
                  });
                }
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _openExerciseSelectionSheet,
                  child: InputDecorator(
                    decoration:
                        const InputDecoration(labelText: 'Select Exercise'),
                    child: Text(
                      _isAddingNewExercise
                          ? 'Add New Exercise'
                          : _selectedExercise ?? 'Select Exercise',
                      style: TextStyle(
                        color: _selectedExercise == null
                            ? theme.hintColor
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isAddingNewExercise)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: TextFormField(
                controller: _newExerciseController,
                decoration:
                    const InputDecoration(labelText: 'New Exercise Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new exercise name';
                  }
                  return null;
                },
              ),
            ),
          GestureDetector(
            onTap: () {
              _showNumberInputSheet(
                controller: _weightController,
                label: 'Weight',
                initialValue: _weightController.text,
                isDouble: true,
              );
            },
            child: AbsorbPointer(
              child: TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Weight'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^[\d,.]+$'),
                  ),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the exercise weight';
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              _showNumberInputSheet(
                controller: _repsController,
                label: 'Reps',
                initialValue: _repsController.text,
                isDouble: false,
              );
            },
            child: AbsorbPointer(
              child: TextFormField(
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
            ),
          ),
          GestureDetector(
            onTap: () {
              _showNumberInputSheet(
                controller: _setsController,
                label: 'Sets',
                initialValue: _setsController.text,
                isDouble: false,
              );
            },
            child: AbsorbPointer(
              child: TextFormField(
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
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _addOrUpdateExercise,
            child: Text(_isAddingNewExercise ? 'Add Exercise' : 'Save Changes'),
          ),
        ],
      ),
    );
  }
}
