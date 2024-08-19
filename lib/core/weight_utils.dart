class WeightUtils {
  // Conversion constants
  static const double kgToLbRatio = 2.20462;

  // Converts kg to lbs
  static double kgToLbs(double kg) {
    return kg * kgToLbRatio;
  }

  // Converts lbs to kg
  static double lbsToKg(double lbs) {
    return lbs / kgToLbRatio;
  }

  // Formats the weight according to the selected unit system (kg or lbs)
  static String formatWeight(double weightInKg, bool isKg) {
    if (isKg) {
      return weightInKg.toStringAsFixed(1); // 1 decimal place for kg
    } else {
      return kgToLbs(weightInKg)
          .toStringAsFixed(1); // Convert to lbs with 1 decimal place
    }
  }
}
