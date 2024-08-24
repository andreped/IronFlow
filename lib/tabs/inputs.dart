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

  // Controllers for "Fitness" logging
  final _userWeightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  String? _selectedExercise;
  bool _isAddingNewExercise = false;
  String? _lastExerciseName;
  double? _lastWeight;
  int? _lastReps;
  int? _lastSets;
  bool _isLbs = false; // State variable to track weight unit

  String _selectedLoggingType = 'Exercise'; // Default to 'Exercise'

  List<String> _predefinedExercises = [];

  @override
  void initState() {
    super.initState();
    _loadPredefinedExercises();
  }

  Future<void> _loadPredefinedExercises() async {
    _selectedExercise = await _dbHelper.getLastLoggedExerciseName();
    List<String> exercises = await _dbHelper.getPredefinedExercises();
    exercises.sort(); // Sort alphabetically
    setState(() {
      _predefinedExercises = exercises;
      if (_selectedExercise != null) {
        _loadLastLoggedExercise();
      }
    });
  }

  Future<void> _loadLastLoggedExercise() async {
    if (_selectedLoggingType == 'Exercise' && _selectedExercise != null) {
      final lastLogged =
          await _dbHelper.getLastLoggedExercise(_selectedExercise!);
      if (lastLogged != null && lastLogged.isNotEmpty) {
        setState(() {
          _lastExerciseName = lastLogged['exercise'] ?? '';
          _lastWeight = double.tryParse(
              lastLogged['weight']?.toString() ?? '0');
          _lastReps = lastLogged['reps'] ?? 0;
          _lastSets = lastLogged['sets'] ?? 1;

          _weightController.text = _isLbs
              ? _convertKgToLbs(_lastWeight ?? 0).toStringAsFixed(2)
              : _lastWeight?.toString() ?? '';
          _repsController.text = _lastReps?.toString() ?? '';
          _setsController.text = _lastSets?.toString() ?? '1';
        });
      } else {
        // Clear the fields if no previous exercise was logged
        setState(() {
          _weightController.clear();
          _repsController.clear();
          _setsController.text = '1';
        });
      }
    } else if (_selectedLoggingType == 'Fitness') {
      final lastLoggedFitness = await _dbHelper.getLastLoggedFitness();
      if (lastLoggedFitness != null && lastLoggedFitness.isNotEmpty) {
        setState(() {
          _userWeightController.text =
              lastLoggedFitness['weight']?.toString() ?? '';
          _heightController.text =
              lastLoggedFitness['height']?.toString() ?? '';
          _ageController.text = lastLoggedFitness['age']?.toString() ?? '';
        });
      }
    }
  }

  double _convertKgToLbs(double kg) {
    return kg * 2.20462;
  }

  double _convertLbsToKg(double lbs) {
    return lbs / 2.20462;
  }

  Future<void> _addOrUpdateExercise() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLoggingType == 'Exercise') {
        final exerciseName = _isAddingNewExercise
            ? _newExerciseController.text.trim()
            : _selectedExercise!;

        // Check if we have a valid exercise name
        if (exerciseName.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Please enter a valid exercise name'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ));
          return;
        }

        // Check if weight, reps, and sets are provided
        final hasFullData = _weightController.text.isNotEmpty &&
            _repsController.text.isNotEmpty &&
            _setsController.text.isNotEmpty;

        if (hasFullData) {
          // Parse and validate the input fields
          final weight = _isLbs
              ? _convertLbsToKg(
                  double.tryParse(_weightController.text.replaceAll(',', '.')) ??
                      0)
              : double.tryParse(_weightController.text.replaceAll(',', '.'));

          final reps = int.tryParse(_repsController.text);
          final sets = int.tryParse(_setsController.text);

          if (weight == null || reps == null || sets == null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Please enter valid values for weight, reps, and sets'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.red,
            ));
            return;
          }

          // Round weight to two decimal places before saving
          final roundedWeight = double.parse(weight.toStringAsFixed(2));

          // Check for a new high score
          final isNewHighScore = await _dbHelper.isNewHighScore(
              exerciseName, roundedWeight, reps);

          // Insert the exercise into the database
          await _dbHelper.insertExercise(
            exercise: exerciseName,
            weight: roundedWeight.toString(),
            reps: reps,
            sets: sets,
          );

          // Show appropriate message
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

          // Clear the new exercise text field and reset the state
          _newExerciseController.clear();
          setState(() {
            _isAddingNewExercise = false;
          });

          widget.onExerciseAdded();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Please fill in weight, reps, and sets or save the exercise name separately'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ));
        }
      } else {
        // Handle Fitness logging
        final userWeight = double.tryParse(_userWeightController.text.replaceAll(',', '.'));
        final height = double.tryParse(_heightController.text.replaceAll(',', '.'));
        final age = int.tryParse(_ageController.text);

        if (userWeight == null || height == null || age == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Please enter valid values'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ));
          return;
        }

        // Save the weight, height, and age to the database
        await _dbHelper.insertFitness(
          weight: userWeight.toDouble(),
          height: height.toDouble(),
          age: age.toDouble(),
        );

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🎯 Fitness data added successfully'),
          duration: Duration(seconds: 2),
        ));

        _userWeightController.clear();
        _heightController.clear();
        _ageController.clear();
      }
    }
  }

  Future<void> _saveNewExerciseName() async {
    final exerciseName = _newExerciseController.text.trim();

    if (exerciseName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter a valid exercise name'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
      ));
      return;
    }

    await _dbHelper.addPredefinedExercise(exerciseName);

    setState(() {
      _predefinedExercises.add(exerciseName);
      _predefinedExercises.sort(); // Keep the list sorted
      _selectedExercise = exerciseName;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🎉 New exercise name saved successfully'),
      duration: Duration(seconds: 2),
      backgroundColor: Colors.blue,
    ));

    _newExerciseController.clear();
    setState(() {
      _isAddingNewExercise = false;
    });

    widget.onExerciseAdded();
  }

  void _showNumberInputSheet({
    required TextEditingController controller,
    required String label,
    required String initialValue,
    required bool isDouble,
  }) {
    final FocusNode focusNode = FocusNode();
    final TextEditingController localController =
        TextEditingController(text: initialValue);

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        localController.text = '';
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      builder: (BuildContext context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus(focusNode);
        });

        return WillPopScope(
          onWillPop: () async {
            _updateValueAndClose(
                context, localController, controller, isDouble);
            return true;
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _updateValueAndClose(
                  context, localController, controller, isDouble);
            },
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: GestureDetector(
                onTap: () {},
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
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^[\d,.]+$')),
                        ],
                        decoration: InputDecoration(
                          labelText: label,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          _updateValueAndClose(
                              context, localController, controller, isDouble);
                        },
                        child: Text('Done'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _updateValueAndClose(
    BuildContext context,
    TextEditingController localController,
    TextEditingController controller,
    bool isDouble,
  ) {
    Navigator.pop(context);
    final value = isDouble
        ? double.tryParse(localController.text.replaceAll(',', '.'))
        : int.tryParse(localController.text);
    if (value != null) {
      controller.text = value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Exercise'),
        actions: [
          // Dropdown to select "Exercise" or "Fitness" logging
          DropdownButton<String>(
            value: _selectedLoggingType,
            onChanged: (String? newValue) async {
              setState(() {
                _selectedLoggingType = newValue!;
              });

              // Load the last logged data for the selected type
              await _loadLastLoggedExercise();
            },
            items: <String>['Exercise', 'Fitness']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedLoggingType == 'Exercise') ...[
                _buildExerciseForm(),
              ] else if (_selectedLoggingType == 'Fitness') ...[
                _buildFitnessForm(),
              ],
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addOrUpdateExercise,
                child: Text('Save'),
              ),
              if (_isAddingNewExercise) ...[
                ElevatedButton(
                  onPressed: _saveNewExerciseName,
                  child: Text('Save New Exercise Name'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exercise Selection and Input
        Row(
          children: [
            if (!_isAddingNewExercise)
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedExercise,
                  hint: Text('Select an exercise'),
                  items: _predefinedExercises.map((exercise) {
                    return DropdownMenuItem<String>(
                      value: exercise,
                      child: Text(exercise),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedExercise = value;
                      _isAddingNewExercise = false;
                      _loadLastLoggedExercise();
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Exercise',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            if (!_isAddingNewExercise) ...[
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _isAddingNewExercise = true;
                  });
                },
              ),
            ] else ...[
              Expanded(
                child: TextFormField(
                  controller: _newExerciseController,
                  decoration: InputDecoration(
                    labelText: 'New Exercise Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.cancel),
                onPressed: () {
                  setState(() {
                    _isAddingNewExercise = false;
                  });
                },
              ),
            ],
          ],
        ),
        SizedBox(height: 20),
        if (!_isAddingNewExercise) ...[
          // Weight Input
          GestureDetector(
            onTap: () => _showNumberInputSheet(
              controller: _weightController,
              label: 'Weight (${_isLbs ? 'lbs' : 'kg'})',
              initialValue: _weightController.text,
              isDouble: true,
            ),
            child: AbsorbPointer(
              child: TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: 'Weight (${_isLbs ? 'lbs' : 'kg'})',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a weight';
                  }
                  return null;
                },
              ),
            ),
          ),
          SizedBox(height: 20),
          // Reps Input
          GestureDetector(
            onTap: () => _showNumberInputSheet(
              controller: _repsController,
              label: 'Reps',
              initialValue: _repsController.text,
              isDouble: false,
            ),
            child: AbsorbPointer(
              child: TextFormField(
                controller: _repsController,
                decoration: InputDecoration(
                  labelText: 'Reps',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the number of reps';
                  }
                  return null;
                },
              ),
            ),
          ),
          SizedBox(height: 20),
          // Sets Input
          GestureDetector(
            onTap: () => _showNumberInputSheet(
              controller: _setsController,
              label: 'Sets',
              initialValue: _setsController.text,
              isDouble: false,
            ),
            child: AbsorbPointer(
              child: TextFormField(
                controller: _setsController,
                decoration: InputDecoration(
                  labelText: 'Sets',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the number of sets';
                  }
                  return null;
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFitnessForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User Weight Input
        GestureDetector(
          onTap: () => _showNumberInputSheet(
            controller: _userWeightController,
            label: 'Weight (${_isLbs ? 'lbs' : 'kg'})',
            initialValue: _userWeightController.text,
            isDouble: true,
          ),
          child: AbsorbPointer(
            child: TextFormField(
              controller: _userWeightController,
              decoration: InputDecoration(
                labelText: 'Weight (${_isLbs ? 'lbs' : 'kg'})',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your weight';
                }
                return null;
              },
            ),
          ),
        ),
        SizedBox(height: 20),
        // Height Input
        GestureDetector(
          onTap: () => _showNumberInputSheet(
            controller: _heightController,
            label: 'Height (cm)',
            initialValue: _heightController.text,
            isDouble: true,
          ),
          child: AbsorbPointer(
            child: TextFormField(
              controller: _heightController,
              decoration: InputDecoration(
                labelText: 'Height (cm)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your height';
                }
                return null;
              },
            ),
          ),
        ),
        SizedBox(height: 20),
        // Age Input
        GestureDetector(
          onTap: () => _showNumberInputSheet(
            controller: _ageController,
            label: 'Age',
            initialValue: _ageController.text,
            isDouble: false,
          ),
          child: AbsorbPointer(
            child: TextFormField(
              controller: _ageController,
              decoration: InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your age';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }
}
