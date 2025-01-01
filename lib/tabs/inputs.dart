import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/database.dart';
import '../core/convert.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';

class ExerciseSetter extends StatefulWidget {
  final Function() onExerciseAdded;
  final bool isKg;

  const ExerciseSetter({
    required this.onExerciseAdded,
    required this.isKg,
  });

  @override
  _ExerciseSetterState createState() => _ExerciseSetterState();
}

class _ExerciseSetterState extends State<ExerciseSetter> {
  final _formKey = GlobalKey<FormState>();
  final _newExerciseController = TextEditingController();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _setsController = TextEditingController(text: '1'); // Default sets to 1
  late ConfettiController _confettiController;

  // Controllers for "Fitness" logging
  final _userWeightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  String? _selectedExercise;
  bool _isAddingNewExercise = false;
  double? _lastWeight;
  int? _lastReps;
  int? _lastSets;
  bool _bodyweightEnabled = false;

  String _selectedLoggingType = 'Exercise'; // Default to 'Exercise'

  List<String> _predefinedExercises = [];

  DateTime? _lastExerciseTime;
  String _timeSinceLastExercise = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadPredefinedExercises();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 4));
    _fetchLastExerciseTime();
    _startTimer();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
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

  void _updateWeightController() {
    if (_weightController.text.isNotEmpty) {
      double weight = double.parse(_weightController.text);
      if (widget.isKg) {
        weight = convertLbsToKg(weight);
      } else {
        weight = convertKgToLbs(weight);
      }
      _weightController.text = weight.toStringAsFixed(2);
    }
  }

  Future<void> _fetchLastExerciseTime() async {
    final lastExercise = await _dbHelper.getLastLoggedExerciseTime();
    if (lastExercise != null) {
      setState(() {
        _lastExerciseTime = lastExercise;
        _updateTimeSinceLastExercise();
      });
    } else {
      setState(() {
        _lastExerciseTime = null;
        _timeSinceLastExercise = '';
      });
    }
  }

  void _startTimer() {
    if (_lastExerciseTime != null) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        _updateTimeSinceLastExercise();
      });
    }
  }

  void _updateTimeSinceLastExercise() {
    if (_lastExerciseTime != null) {
      final now = DateTime.now();
      final difference = now.difference(_lastExerciseTime!);
      if (difference.inHours >= 1) {
        setState(() {
          _timeSinceLastExercise = '';
        });
        _timer?.cancel();
      } else {
        setState(() {
          _timeSinceLastExercise =
              '${difference.inHours}h ${difference.inMinutes.remainder(60)}m ${difference.inSeconds.remainder(60)}s';
        });
      }
    } else {
      setState(() {
        _timeSinceLastExercise = '';
      });
    }
  }

  Future<void> _loadLastLoggedExercise() async {
    if (_selectedLoggingType == 'Exercise' && _selectedExercise != null) {
      final lastLogged =
          await _dbHelper.getLastLoggedExercise(_selectedExercise!);
      if (lastLogged.isNotEmpty) {
        setState(() {
          _lastWeight =
              double.tryParse(lastLogged['weight']?.toString() ?? '0');
          _lastReps = lastLogged['reps'] ?? 0;
          _lastSets = lastLogged['sets'] ?? 1;

          _weightController.text = !widget.isKg
              ? convertKgToLbs(_lastWeight ?? 0).toStringAsFixed(2)
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

  Future<void> _addOrUpdateExercise() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLoggingType == 'Exercise') {
        final exerciseName = _isAddingNewExercise
            ? _newExerciseController.text.trim()
            : (_selectedExercise ?? '');

        // Check if we have a valid exercise name
        if (exerciseName.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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
          final weight = !widget.isKg
              ? convertLbsToKg(double.tryParse(
                      _weightController.text.replaceAll(',', '.')) ??
                  0)
              : double.tryParse(_weightController.text.replaceAll(',', '.'));

          final reps = int.tryParse(_repsController.text);
          final sets = int.tryParse(_setsController.text);

          if (weight == null ||
              reps == null ||
              sets == null ||
              reps < 1 ||
              sets < 1) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text('Please enter valid values for weight, reps, and sets'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.red,
            ));
            return;
          }

          // Round weight to two decimal places before saving
          final roundedWeight = double.parse(weight.toStringAsFixed(2));

          // Check for a new high score
          final isNewHighScore =
              await _dbHelper.isNewHighScore(exerciseName, roundedWeight, reps);

          // Insert the exercise into the database
          await _dbHelper.insertExercise(
            exercise: exerciseName,
            weight: roundedWeight.toString(),
            reps: reps,
            sets: sets,
          );

          // Update the last exercise time and reset the timer
          setState(() {
            _lastExerciseTime = DateTime.now();
            _updateTimeSinceLastExercise();
            _timer?.cancel();
            _startTimer();
          });

          // Show appropriate message
          if (isNewHighScore) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('🚀🎉 New high score for $exerciseName!'),
              duration: Duration(seconds: 4),
              backgroundColor: Colors.green,
            ));

            // Start confetti
            _confettiController.play();
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
            content: Text(
                'Please fill in weight, reps, and sets or save the exercise name separately'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ));
        }
      } else {
        // Handle Fitness logging
        final userWeight =
            double.tryParse(_userWeightController.text.replaceAll(',', '.'));
        final height = int.tryParse(_heightController.text);
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
          height: height.toInt(),
          age: age.toInt(),
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

    // disallow adding predefined exercises if they already exist
    if (_predefinedExercises.contains(exerciseName)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('⛔ Exercise already exists in database'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
      ));
      return;
    }

    await _dbHelper.addPredefinedExercise(exerciseName, _bodyweightEnabled);

    setState(() {
      _predefinedExercises.add(exerciseName);
      _predefinedExercises.sort(); // Keep the list sorted
      _selectedExercise = exerciseName;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🎉 New exercise saved successfully'),
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
    return Stack(
      children: [
        Scaffold(
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
                    _buildExerciseForm(context),
                  ] else if (_selectedLoggingType == 'Fitness') ...[
                    _buildFitnessForm(context),
                  ],
                  SizedBox(height: 20),
                  if (!_isAddingNewExercise)
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _addOrUpdateExercise,
                          child: Text('Save'),
                        ),
                        if (_timeSinceLastExercise.isNotEmpty) ...[
                          SizedBox(width: 10),
                          Icon(Icons.timer,
                              color: Theme.of(context).colorScheme.primary),
                          SizedBox(width: 5),
                          Text(
                            _timeSinceLastExercise,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color ??
                                  Colors.black,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.yellow
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseForm(BuildContext context) {
    final ThemeData theme = Theme.of(context);

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
                icon: Icon(Icons.add, color: theme.iconTheme.color),
                onPressed: () {
                  setState(() {
                    _isAddingNewExercise = true;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: theme.iconTheme.color),
                onPressed: () async {
                  if (_selectedExercise != null) {
                    bool confirmDelete = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Confirm Delete'),
                          content: Text(
                              'Are you sure you want to delete this exercise?'),
                          actions: <Widget>[
                            TextButton(
                              child: Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                            ),
                            TextButton(
                              child: Text('Delete'),
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmDelete) {
                      bool isUsed =
                          await _dbHelper.isExerciseUsed(_selectedExercise!);
                      if (!isUsed) {
                        await _dbHelper.deleteExercise(_selectedExercise!);
                        setState(() {
                          _predefinedExercises.remove(_selectedExercise);
                          _selectedExercise = null;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('✅ Exercise successfully deleted.'),
                              duration: Duration(seconds: 2)),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  '🚫 Cannot delete exercise that is in use!'),
                              duration: Duration(seconds: 2)),
                        );
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('❗ No exercise selected to delete.'),
                          duration: Duration(seconds: 2)),
                    );
                  }
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
                icon: Icon(Icons.cancel, color: theme.iconTheme.color),
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
              label: 'Weight (${widget.isKg ? 'kg' : 'lbs'})',
              initialValue: _weightController.text,
              isDouble: true,
            ),
            child: AbsorbPointer(
              child: TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: 'Weight (${widget.isKg ? 'kg' : 'lbs'})',
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
          SizedBox(height: 20),
        ] else ...[
          Row(
            children: [
              Checkbox(
                value: _bodyweightEnabled,
                onChanged: (bool? value) {
                  setState(() {
                    _bodyweightEnabled = value ?? false;
                  });
                },
              ),
              Expanded(
                child: Text(
                  'Include bodyweight in weight calculations',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          // Save New Exercise Name Button (Only when adding a new exercise)
          ElevatedButton(
            onPressed: _saveNewExerciseName,
            child: Text('Save New Exercise'),
          ),
        ],
      ],
    );
  }

  Widget _buildFitnessForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User Weight Input
        GestureDetector(
          onTap: () => _showNumberInputSheet(
            controller: _userWeightController,
            label: 'Weight (${widget.isKg ? 'kg' : 'lbs'})',
            initialValue: _userWeightController.text,
            isDouble: true,
          ),
          child: AbsorbPointer(
            child: TextFormField(
              controller: _userWeightController,
              decoration: InputDecoration(
                labelText: 'Weight (${widget.isKg ? 'kg' : 'lbs'})',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your weight';
                }
                if (value == '0.0') {
                  return 'Weight cannot be 0';
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
            isDouble: false,
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
                if (value == '0') {
                  return 'Height cannot be 0';
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
                if (value == '0') {
                  return 'Age cannot be 0';
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
