import 'package:flutter/material.dart';
import '../core/database.dart';
import '../models/exercise.dart';
import '../models/fitness_data.dart';
import '../utils/date_utils.dart' as custom_date_utils;

class DataService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Exercise>> fetchExercises() async {
    final data = await _dbHelper.getExercises();
    return data.map((map) => Exercise.fromMap(map)).toList();
  }

  Future<List<FitnessData>> fetchFitnessData() async {
    final data = await _dbHelper.getFitnessData();
    return data.map((map) => FitnessData.fromMap(map)).toList();
  }

  Future<Set<String>> fetchUniqueExerciseNames() async {
    final exercises = await fetchExercises();
    return exercises.map((exercise) => exercise.name).toSet();
  }

  List<T> filterDataByDateRange<T>(List<T> data, DateTimeRange? dateRange) {
    if (dateRange == null) return data;
    return data.where((record) {
      final dateTime =
          custom_date_utils.DateUtils.dateOnly((record as dynamic).timestamp);
      return dateTime
              .isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
          dateTime.isBefore(dateRange.end.add(const Duration(days: 1)));
    }).toList();
  }

  double aggregateMax(List<dynamic> records, String attribute) {
    return records
        .map((record) => (record[attribute] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
  }

  double aggregateAverage(List<dynamic> records, String attribute) {
    double totalValue = 0.0;
    double totalRepsSets = 0.0;

    for (var record in records) {
      double value = (record[attribute] as num).toDouble();
      if (record is Exercise) {
        totalValue += (record.sets * record.reps) * value;
        totalRepsSets += record.sets * record.reps;
      } else {
        totalValue += value;
        totalRepsSets += 1;
      }
    }

    return totalRepsSets > 0 ? totalValue / totalRepsSets : 0.0;
  }

  double aggregateTotal(List<dynamic> records, String attribute) {
    return records.fold(0.0, (sum, record) {
      double value = (record[attribute] as num).toDouble();
      if (record is Exercise) {
        return sum + (record.sets * record.reps * value);
      } else {
        return sum + value;
      }
    });
  }

  double aggregateTop3Avg(List<dynamic> records, String attribute) {
    List<double> values =
        records.map((record) => (record[attribute] as num).toDouble()).toList();
    values.sort((a, b) => b.compareTo(a)); // Sort in descending order
    List<double> top3Values = values.take(3).toList();
    return top3Values.isNotEmpty
        ? top3Values.reduce((a, b) => a + b) / top3Values.length
        : 0.0;
  }

  double aggregateTop3Tot(List<dynamic> records, String attribute) {
    List<double> values =
        records.map((record) => (record[attribute] as num).toDouble()).toList();
    values.sort((a, b) => b.compareTo(a)); // Sort in descending order
    List<double> top3Values = values.take(3).toList();
    return top3Values.isNotEmpty ? top3Values.reduce((a, b) => a + b) : 0.0;
  }
}
