import 'package:flutter/material.dart';

final ThemeData pinkTheme = ThemeData(
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
