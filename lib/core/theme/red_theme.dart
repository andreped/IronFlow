import 'package:flutter/material.dart';

final ThemeData redTheme = ThemeData(
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
