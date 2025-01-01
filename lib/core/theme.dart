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
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.blue),
        foregroundColor: MaterialStateProperty.all(Colors.white),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(Colors.blue),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(Colors.blue),
        side: MaterialStateProperty.all(BorderSide(color: Colors.blue)),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    iconTheme: IconThemeData(color: Colors.purple),
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
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.purple),
        foregroundColor: MaterialStateProperty.all(Colors.white),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(Colors.purple),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(Colors.purple),
        side: MaterialStateProperty.all(BorderSide(color: Colors.purple)),
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
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.pink),
        foregroundColor: MaterialStateProperty.all(Colors.white),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(Colors.pink),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(Colors.pink),
        side: MaterialStateProperty.all(BorderSide(color: Colors.pink)),
      ),
    ),
  );

  static ThemeData greenTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.green,
    iconTheme: IconThemeData(color: Colors.green),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.green,
      primary: Colors.green,
      secondary: Colors.greenAccent,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: MaterialStateProperty.all(Colors.green.shade50),
        elevation: MaterialStateProperty.all(8.0),
        shadowColor: MaterialStateProperty.all(Colors.green.withOpacity(0.5)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.green),
        foregroundColor: MaterialStateProperty.all(Colors.white),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(Colors.green),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(Colors.green),
        side: MaterialStateProperty.all(BorderSide(color: Colors.green)),
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
      case AppTheme.system:
      default:
        return brightness == Brightness.dark ? darkTheme : lightTheme;
    }
  }
}

enum AppTheme { system, light, dark, pink, green }

// Extension on ThemeData to include the primaryChartColor
extension ChartColors on ThemeData {
  Color get primaryChartColor {
    if (brightness == Brightness.dark) {
      return colorScheme.primary;
    } else if (colorScheme.primary == Colors.pink) {
      return Colors.pink;
    } else if (colorScheme.primary == Colors.green) {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }
}