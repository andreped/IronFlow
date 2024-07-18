import 'package:flutter/material.dart';

class ExerciseEditDialog extends StatefulWidget {
  final Map<String, dynamic> exerciseData;

  ExerciseEditDialog({required this.exerciseData});

  @override
  _ExerciseEditDialogState createState() => _ExerciseEditDialogState();
}

class _ExerciseEditDialogState extends State<ExerciseEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _exerciseController;
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late TextEditingController _setsController;

  @override
  void initState() {
    super.initState();
    _exerciseController = TextEditingController(text: widget.exerciseData['exercise']);
    _weightController = TextEditingController(text: widget.exerciseData['weight']);
    _repsController = TextEditingController(text: widget.exerciseData['reps'].toString());
    _setsController = TextEditingController(text: widget.exerciseData['sets'].toString());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Exercise'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _exerciseController,
              decoration: const InputDecoration(labelText: 'Exercise'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an exercise';
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
                  return 'Please enter the weight';
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'exercise': _exerciseController.text,
                'weight': _weightController.text,
                'reps': int.parse(_repsController.text),
                'sets': int.parse(_setsController.text),
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _weightController.dispose();
    _repsController.dispose();
    _setsController.dispose();
    super.dispose();
  }
}