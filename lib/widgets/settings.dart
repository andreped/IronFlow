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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Text(
        'Settings',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme selection
            ListTile(
              title: Text(
                'Theme',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 14),
              ),
              trailing: DropdownButton<ThemeMode>(
                value: _themeMode,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? Colors.white
                      : Colors.black, // Set text color based on theme
                ),
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
            ListTile(
              title: Text(
                'Use kg (or lbs)',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 14),
              ),
              trailing: Transform.scale(
                scale: 0.8, // Adjust the scale to resize the switch
                child: Switch(
                  value: _isKg,
                  onChanged: _handleUnitChange,
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveTrackColor:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                ),
              ),
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
            style:
                Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
