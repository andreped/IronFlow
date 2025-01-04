import 'package:flutter/material.dart';

class DropdownWidget extends StatelessWidget {
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String hint;
  final ThemeData theme;

  const DropdownWidget({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure the value is in the items list
    final dropdownValue = items.contains(value) ? value : null;

    return DropdownButton<String>(
      hint:
          Text(hint, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
      value: dropdownValue,
      onChanged: onChanged,
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        );
      }).toList(),
      dropdownColor:
          theme.dropdownMenuTheme.menuStyle?.backgroundColor?.resolve({}) ??
              Colors.white,
    );
  }
}
