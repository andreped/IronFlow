import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../core/database.dart';
import '../core/theme.dart';

class SettingsModal extends StatefulWidget {
  final AppTheme appTheme;
  final ValueChanged<AppTheme> onThemeChanged;
  final bool isKg;
  final ValueChanged<bool> onUnitChanged;

  const SettingsModal({
    Key? key,
    required this.appTheme,
    required this.onThemeChanged,
    required this.isKg,
    required this.onUnitChanged,
  }) : super(key: key);

  @override
  _SettingsModalState createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late AppTheme _appTheme;
  late bool _isKg;
  late Future<String> _appVersion;

  @override
  void initState() {
    super.initState();
    _appTheme = widget.appTheme;
    _isKg = widget.isKg;
    _appVersion = _getAppVersion();
  }

  Future<String> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  void _handleThemeChange(AppTheme? newTheme) {
    if (newTheme != null) {
      setState(() {
        _appTheme = newTheme;
      });
      widget.onThemeChanged(newTheme);
    }
  }

  void _handleUnitChange(bool newValue) {
    setState(() {
      _isKg = newValue;
    });
    widget.onUnitChanged(newValue);
  }

  Future<void> _showConfirmationDialogs() async {
    final bool? firstDialogConfirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ Confirm Deletion'),
          content: const Text(
              '🚨 Clicking this button deletes all the recorded exercise data. Are you sure you want to do this?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (firstDialogConfirmed == true) {
      final bool? secondDialogConfirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('❗️ Are you really sure?'),
            content: const Text(
                '💥 Are you really sure you want to lose all your data? There is no going back!'),
            actions: <Widget>[
              TextButton(
                child: const Text('No'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Yes'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (secondDialogConfirmed == true) {
        await _dbHelper.clearDatabase();

        // Show success SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Database cleared successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
          ),
          FutureBuilder<String>(
            future: _appVersion,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasData) {
                return Text(
                  'v${snapshot.data}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 14),
                );
              } else {
                return Text(
                  'Version unknown',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 14),
                );
              }
            },
          ),
        ],
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
              trailing: DropdownButton<AppTheme>(
                value: _appTheme,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? Colors.purple // Use primary color for dark mode
                      : Colors.black, // Set text color for light mode
                ),
                items: [
                  DropdownMenuItem(
                    value: AppTheme.system,
                    child: Text('System Default'),
                  ),
                  DropdownMenuItem(
                    value: AppTheme.light,
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(
                    value: AppTheme.dark,
                    child: Text('Dark'),
                  ),
                  DropdownMenuItem(
                    value: AppTheme.pink,
                    child: Text('Pink'),
                  ),
                ],
                onChanged: _handleThemeChange,
              ),
            ),
            // Unit selection
            ListTile(
              title: Text(
                'Unit',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 14),
              ),
              trailing: TextButton(
                onPressed: () {
                  _handleUnitChange(!_isKg);
                },
                child: Text(
                  _isKg ? 'kg' : 'lbs',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary, // Use theme primary color
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Clear database
            ListTile(
              title: Text(
                'Clear Database',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 14),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete_sweep, color: Colors.redAccent),
                onPressed: () async {
                  await _showConfirmationDialogs();
                },
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
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
