import 'package:flutter/material.dart';

final ThemeData greenTheme = ThemeData(
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
