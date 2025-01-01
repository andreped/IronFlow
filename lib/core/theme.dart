import 'package:flutter/material.dart';

class AppThemes {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    iconTheme: const IconThemeData(color: Colors.blue),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      primary: Colors.blue,
      secondary: Colors.blueAccent,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(8.0),
        shadowColor: WidgetStateProperty.all(Colors.black.withOpacity(0.2)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.blue),
        foregroundColor: WidgetStateProperty.all(Colors.white),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.blue),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.blue),
        side: WidgetStateProperty.all(const BorderSide(color: Colors.blue)),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    iconTheme: const IconThemeData(color: Colors.purple),
    colorScheme: const ColorScheme.dark().copyWith(
      primary: Colors.purple,
      secondary: Colors.purpleAccent,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.grey[850]),
        elevation: WidgetStateProperty.all(8.0),
        shadowColor: WidgetStateProperty.all(Colors.black.withOpacity(0.5)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.purple),
        foregroundColor: WidgetStateProperty.all(Colors.white),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.purple),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.purple),
        side: WidgetStateProperty.all(const BorderSide(color: Colors.purple)),
      ),
    ),
  );

  static ThemeData pinkTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.pink,
    iconTheme: const IconThemeData(color: Colors.pink),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.pink,
      primary: Colors.pink,
      secondary: Colors.pinkAccent,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.pink.shade50),
        elevation: WidgetStateProperty.all(8.0),
        shadowColor: WidgetStateProperty.all(Colors.pink.withOpacity(0.5)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.pink),
        foregroundColor: WidgetStateProperty.all(Colors.white),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.pink),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.pink),
        side: WidgetStateProperty.all(const BorderSide(color: Colors.pink)),
      ),
    ),
  );

  static ThemeData greenTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.green,
    iconTheme: const IconThemeData(color: Colors.green),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.green,
      primary: Colors.green,
      secondary: Colors.greenAccent,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.green.shade50),
        elevation: WidgetStateProperty.all(8.0),
        shadowColor: WidgetStateProperty.all(Colors.green.withOpacity(0.5)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.green),
        foregroundColor: WidgetStateProperty.all(Colors.white),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.green),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.green),
        side: WidgetStateProperty.all(const BorderSide(color: Colors.green)),
      ),
    ),
  );

  static ThemeData orangeTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.orange,
    iconTheme: const IconThemeData(color: Colors.orange),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.orange,
      primary: Colors.orange,
      secondary: Colors.orangeAccent,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.orange.shade50),
        elevation: WidgetStateProperty.all(8.0),
        shadowColor: WidgetStateProperty.all(Colors.orange.withOpacity(0.5)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.orange),
        foregroundColor: WidgetStateProperty.all(Colors.white),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.orange),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.orange),
        side: WidgetStateProperty.all(const BorderSide(color: Colors.orange)),
      ),
    ),
  );

  static ThemeData redTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.red,
    iconTheme: const IconThemeData(color: Colors.red),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.red,
      primary: Colors.red,
      secondary: Colors.redAccent,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.red.shade50),
        elevation: WidgetStateProperty.all(8.0),
        shadowColor: WidgetStateProperty.all(Colors.red.withOpacity(0.5)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.red),
        foregroundColor: WidgetStateProperty.all(Colors.white),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.red),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.red),
        side: WidgetStateProperty.all(const BorderSide(color: Colors.red)),
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
      case AppTheme.green:
        return greenTheme;
      case AppTheme.orange:
        return orangeTheme;
      case AppTheme.red:
        return redTheme;
      case AppTheme.system:
      default:
        return brightness == Brightness.dark ? darkTheme : lightTheme;
    }
  }
}

enum AppTheme { system, light, dark, pink, green, orange, red }

// Extension on ThemeData to include the primaryChartColor
extension ChartColors on ThemeData {
  Color get primaryChartColor {
    if (brightness == Brightness.dark) {
      return colorScheme.primary;
    } else if (colorScheme.primary == Colors.pink) {
      return Colors.pink;
    } else if (colorScheme.primary == Colors.green) {
      return Colors.green;
    } else if (colorScheme.primary == Colors.orange) {
      return Colors.orange;
    } else if (colorScheme.primary == Colors.red) {
      return Colors.red;
    } else {
      return Colors.blue;
    }
  }
}
