import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FitnessEditDialog extends StatefulWidget {
  final Map<String, dynamic> fitnessData;
  final bool isKg; // Add this parameter to manage unit selection

  const FitnessEditDialog({super.key, required this.fitnessData, required this.isKg});

  @override
  FitnessEditDialogState createState() => FitnessEditDialogState();
}

class FitnessEditDialogState extends State<FitnessEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _ageController;
  late TextEditingController _timestampController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
        text: _formatWeight(widget.fitnessData['weight']));
    _heightController =
        TextEditingController(text: widget.fitnessData['height'].toString());
    _ageController =
        TextEditingController(text: widget.fitnessData['age'].toString());
    _timestampController =
        TextEditingController(text: widget.fitnessData['timestamp']);
  }

  String _formatWeight(String weight) {
    final double weightInKg = double.parse(weight);
    return widget.isKg
        ? weightInKg.toStringAsFixed(2)
        : (weightInKg * 2.20462).toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).pop();
      },
      child: AlertDialog(
        title: const Text('Edit Fitness'),
        content: GestureDetector(
          onTap: () {}, // Prevents dialog from closing when tapping inside
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^[\d,.]+$')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the weight';
                        }
                        final parsedWeight =
                            double.tryParse(value.replaceAll(',', '.'));
                        if (parsedWeight == null || !_isValidWeight(value)) {
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
                      controller: _heightController,
                      label: 'Height',
                      initialValue: _heightController.text,
                      isDouble: false,
                    );
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(labelText: 'Height'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the height';
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
                      controller: _ageController,
                      label: 'Age',
                      initialValue: _ageController.text,
                      isDouble: false,
                    );
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the age';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid integer';
                        }
                        return null;
                      },
                    ),
                  ),
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
                final weight = widget.isKg
                    ? _weightController.text
                    : (double.parse(_weightController.text) / 2.20462)
                        .toStringAsFixed(2);
                final height = int.tryParse(_heightController.text);
                final age = int.tryParse(_ageController.text);

                if (height == null || age == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please enter valid values'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }

                Navigator.of(context).pop({
                  'id': widget.fitnessData['id'],
                  'weight': weight,
                  'height': height,
                  'age': age,
                  'timestamp': _timestampController.text,
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
                Text(label, style: const TextStyle(fontSize: 18)),
                TextField(
                  focusNode: focusNode,
                  controller: localController,
                  keyboardType: isDouble
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[\d,.]+$')),
                  ],
                  decoration: InputDecoration(
                    labelText: label,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    final value = isDouble
                        ? double.tryParse(
                            localController.text.replaceAll(',', '.'))
                        : int.tryParse(localController.text);

                    if (value != null) {
                      setState(() {
                        controller.text = value.toString();
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please enter a valid number'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.red,
                      ));
                    }
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isValidWeight(String value) {
    if (value.contains('..') || value.contains('..0') || value.endsWith('.')) {
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _timestampController.dispose();
    super.dispose();
  }
}
