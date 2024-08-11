import 'package:flutter/material.dart';

class WeightUtils {
  static double kgToLbs(double kg) {
    return kg * 2.20462;
  }

  static double lbsToKg(double lbs) {
    return lbs / 2.20462;
  }

  static String formatWeight(double weight, bool isKg) {
    if (isKg) {
      return '${weight.toStringAsFixed(2)} kg';
    } else {
      return '${kgToLbs(weight).toStringAsFixed(2)} lbs';
    }
  }
}
