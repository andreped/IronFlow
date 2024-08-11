import 'dart:async';
import 'package:flutter/material.dart';
import 'tabs/home.dart';

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isKg = true; // Default unit system

  void _toggleThemeMode(ThemeMode newThemeMode) {
    setState(() {
      _themeMode = newThemeMode;
    });
  }

  void _toggleUnit(bool newUnit) {
    setState(() {
      _isKg = newUnit;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ExerciseStoreApp(
      themeMode: _themeMode,
      updateTheme: _toggleThemeMode,
      isKg: _isKg,
      toggleUnit: _toggleUnit,
    );
  }
}
