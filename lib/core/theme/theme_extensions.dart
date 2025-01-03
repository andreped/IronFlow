import 'package:flutter/material.dart';

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
