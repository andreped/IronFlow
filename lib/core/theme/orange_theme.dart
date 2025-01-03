import 'package:flutter/material.dart';

final ThemeData orangeTheme = ThemeData(
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
