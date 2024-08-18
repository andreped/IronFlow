import 'package:flutter/material.dart';

class AppThemes {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    iconTheme: IconThemeData(color: Colors.blue), // Icon color for light theme
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      primary: Colors.blue,
      secondary: Colors.blueAccent,
    ),
  );

  static ThemeData darkTheme = ThemeData.dark();

  static ThemeData pinkTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.pink,
    iconTheme: IconThemeData(color: Colors.pink), // Icon color for pink theme
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.pink,
      primary: Colors.pink,
      secondary: Colors.pinkAccent,
    ),
  );

  static ThemeData getTheme(AppTheme appTheme, Brightness brightness) {
    switch (appTheme) {
      case AppTheme.light:
        return lightTheme;
      case AppTheme.dark:
        return darkTheme;
      case AppTheme.pink:
        return pinkTheme;
      case AppTheme.system:
      default:
        return brightness == Brightness.dark ? darkTheme : lightTheme;
    }
  }
}

enum AppTheme { system, light, dark, pink }
