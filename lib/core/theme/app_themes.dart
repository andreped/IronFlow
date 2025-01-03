import 'package:flutter/material.dart';
import 'light_theme.dart';
import 'dark_theme.dart';
import 'pink_theme.dart';
import 'green_theme.dart';
import 'orange_theme.dart';
import 'red_theme.dart';

class AppThemes {
  static final ThemeData light = lightTheme;
  static final ThemeData dark = darkTheme;
  static final ThemeData pink = pinkTheme;
  static final ThemeData green = greenTheme;
  static final ThemeData orange = orangeTheme;
  static final ThemeData red = redTheme;

  static ThemeData getTheme(AppTheme appTheme, Brightness brightness) {
    switch (appTheme) {
      case AppTheme.light:
        return light;
      case AppTheme.dark:
        return dark;
      case AppTheme.pink:
        return pink;
      case AppTheme.green:
        return green;
      case AppTheme.orange:
        return orange;
      case AppTheme.red:
        return red;
      case AppTheme.system:
      default:
        return brightness == Brightness.dark ? dark : light;
    }
  }
}

enum AppTheme { system, light, dark, pink, green, orange, red }
