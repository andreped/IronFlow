import 'package:flutter/material.dart';

final ThemeData darkTheme = ThemeData.dark().copyWith(
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
