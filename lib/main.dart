import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tabs/home.dart';
import 'core/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppTheme _appTheme = AppTheme.system; // Default to system theme
  bool _isKg = true; // Default unit system

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appTheme = AppTheme.values[prefs.getInt('appTheme') ?? _appTheme.index];
      _isKg = prefs.getBool('isKg') ?? _isKg;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('appTheme', _appTheme.index);
    await prefs.setBool('isKg', _isKg);
  }

  void _toggleTheme(AppTheme newTheme) {
    setState(() {
      _appTheme = newTheme;
    });
    _saveSettings();
  }

  void _toggleUnit(bool newUnit) {
    setState(() {
      _isKg = newUnit;
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    // Get current brightness
    final brightness = MediaQuery.of(context).platformBrightness;
    final themeData = AppThemes.getTheme(_appTheme, brightness);

    return MaterialApp(
      title: 'IronFlow',
      theme: themeData,
      darkTheme: AppThemes.darkTheme,
      themeMode: _appTheme == AppTheme.system
          ? ThemeMode.system
          : (_appTheme == AppTheme.dark ? ThemeMode.dark : ThemeMode.light),
      home: ExerciseStoreHomePage(
        appTheme: _appTheme,
        updateTheme: _toggleTheme,
        isKg: _isKg,
        toggleUnit: _toggleUnit,
      ),
    );
  }
}
