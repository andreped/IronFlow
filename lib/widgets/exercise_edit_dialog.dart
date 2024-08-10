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
  late TextEditingController _timestampController;

  @override
  void initState() {
    super.initState();
    _exerciseController =
        TextEditingController(text: widget.exerciseData['exercise']);
    _weightController =
        TextEditingController(text: widget.exerciseData['weight']);
    _repsController =
        TextEditingController(text: widget.exerciseData['reps'].toString());
    _setsController =
        TextEditingController(text: widget.exerciseData['sets'].toString());
    _timestampController =
        TextEditingController(text: widget.exerciseData['timestamp']);
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
            TextFormField(
              controller: _timestampController,
              decoration:
                  const InputDecoration(labelText: 'Timestamp (ISO8601)'),
              keyboardType: TextInputType.datetime,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a timestamp';
                }
                try {
                  DateTime.parse(value);
                } catch (e) {
                  return 'Please enter a valid ISO8601 timestamp';
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
              // Ensure weight has a trailing .0 if necessary
              String weight = _weightController.text;
              if (double.tryParse(weight)?.truncateToDouble() == double.tryParse(weight)) {
                weight = '${weight}.0';
              }

              Navigator.of(context).pop({
                'id': widget.exerciseData['id'], // Include the id
                'exercise': _exerciseController.text,
                'weight': weight,
                'reps': int.parse(_repsController.text),
                'sets': int.parse(_setsController.text),
                'timestamp': _timestampController.text,
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
    _timestampController.dispose();
    super.dispose();
  }
}
