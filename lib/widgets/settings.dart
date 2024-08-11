import 'package:flutter/material.dart';

class SettingsModal extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final bool isKg;
  final ValueChanged<bool> onUnitChanged;

  const SettingsModal({
    Key? key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.isKg,
    required this.onUnitChanged,
  }) : super(key: key);

  @override
  _SettingsModalState createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  late ThemeMode _themeMode;
  late bool _isKg;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.themeMode;
    _isKg = widget.isKg;
  }

  void _handleThemeChange(ThemeMode? newThemeMode) {
    if (newThemeMode != null) {
      setState(() {
        _themeMode = newThemeMode;
      });
      widget.onThemeChanged(newThemeMode);
    }
  }

  void _handleUnitChange(bool newValue) {
    setState(() {
      _isKg = newValue;
    });
    widget.onUnitChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Settings',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
      ),
      content: SizedBox(
        width: 300,  // Set the width of the modal
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme selection
            ListTile(
              title: Text(
                'Theme',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
              ),
              trailing: DropdownButton<ThemeMode>(
                value: _themeMode,
                style: TextStyle(fontSize: 14),  // Set font size for dropdown text
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('System Default'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text('Dark'),
                  ),
                ],
                onChanged: _handleThemeChange,
              ),
            ),
            // Unit selection
            SwitchListTile(
              title: Text(
                'Use kg (or lbs)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
              ),
              value: _isKg,
              onChanged: _handleUnitChange,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Close',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
