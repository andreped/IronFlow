import 'package:flutter/material.dart';

class ToggleButtonsWidget extends StatelessWidget {
  final List<bool> isSelected;
  final ValueChanged<int> onPressed;
  final List<Icon> icons;

  ToggleButtonsWidget({
    required this.isSelected,
    required this.onPressed,
    required this.icons,
  });

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      isSelected: isSelected,
      onPressed: onPressed,
      children: icons,
    );
  }
}
