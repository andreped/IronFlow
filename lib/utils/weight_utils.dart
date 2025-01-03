class WeightUtils {
  static double convertWeight(double weightInKg, bool isKg) {
    return isKg ? weightInKg : weightInKg * 2.20462;
  }
}
