import 'package:flutter/material.dart';

class AppThemes {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    iconTheme: IconThemeData(color: Colors.blue),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      primary: Colors.blue,
      secondary: Colors.blueAccent,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: MaterialStateProperty.all(Colors.white),
        elevation: MaterialStateProperty.all(8.0),
        shadowColor: MaterialStateProperty.all(Colors.black.withOpacity(0.2)),
      ),
    ),
    // Add button themes for light mode
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor:
            MaterialStateProperty.all(Colors.blue), // Background color
        foregroundColor: MaterialStateProperty.all(Colors.white), // Text color
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(Colors.blue), // Text color
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(Colors.blue), // Text color
        side: MaterialStateProperty.all(
            BorderSide(color: Colors.blue)), // Border color
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    colorScheme: ColorScheme.dark().copyWith(
      primary: Colors.purple,
      secondary: Colors.purpleAccent,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: MaterialStateProperty.all(Colors.grey[850]),
        elevation: MaterialStateProperty.all(8.0),
        shadowColor: MaterialStateProperty.all(Colors.black.withOpacity(0.5)),
      ),
    ),
    // Add button themes for dark mode
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor:
            MaterialStateProperty.all(Colors.purple), // Background color
        foregroundColor: MaterialStateProperty.all(Colors.white), // Text color
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(Colors.purple), // Text color
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(Colors.purple), // Text color
        side: MaterialStateProperty.all(
            BorderSide(color: Colors.purple)), // Border color
      ),
    ),
  );

  static ThemeData pinkTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.pink,
    iconTheme: IconThemeData(color: Colors.pink),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.pink,
      primary: Colors.pink,
      secondary: Colors.pinkAccent,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: MaterialStateProperty.all(Colors.pink.shade50),
        elevation: MaterialStateProperty.all(8.0),
        shadowColor: MaterialStateProperty.all(Colors.pink.withOpacity(0.5)),
      ),
    ),
    // Add button themes for pink mode
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor:
            MaterialStateProperty.all(Colors.pink), // Background color
        foregroundColor: MaterialStateProperty.all(Colors.white), // Text color
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(Colors.pink), // Text color
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(Colors.pink), // Text color
        side: MaterialStateProperty.all(
            BorderSide(color: Colors.pink)), // Border color
      ),
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

// Extension on ThemeData to include the primaryChartColor
extension ChartColors on ThemeData {
  Color get primaryChartColor {
    // Use primary color or fallback to specific colors based on brightness
    if (brightness == Brightness.dark) {
      return colorScheme.primary; // Typically purple in dark mode
    } else if (colorScheme.primary == Colors.pink) {
      return Colors.pink; // Pink theme case
    } else {
      return Colors.blue; // Default to blue in light mode
    }
  }
}
