import 'package:intl/intl.dart';

double convertKgToLbs(double kg) {
  return kg * 2.20462;
}

double convertLbsToKg(double lbs) {
  return lbs / 2.20462;
}

String formatDate(String timestamp) {
  final DateTime dateTime = DateTime.parse(timestamp);
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  return dateFormat.format(dateTime);
}

String formatWeight(String weight, bool isKg) {
  final double weightInKg = double.parse(weight);
  return isKg
      ? weightInKg.toStringAsFixed(2)
      : (weightInKg * 2.20462).toStringAsFixed(2);
}
