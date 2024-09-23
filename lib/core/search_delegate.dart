import 'package:flutter/material.dart';

class ExerciseSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> records;
  final bool isKg;
  final Function(double) convertWeight;

  ExerciseSearchDelegate({
    required this.records,
    required this.isKg,
    required this.convertWeight,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final filteredRecords = records.where((record) {
      final exercise = record['exercise'] as String;
      return exercise.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return _buildRecordList(filteredRecords);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final filteredRecords = records.where((record) {
      final exercise = record['exercise'] as String;
      return exercise.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return _buildRecordList(filteredRecords);
  }

  Widget _buildRecordList(List<Map<String, dynamic>> records) {
    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final exercise = record['exercise'] as String;
        final weight = record['weight'];
        final reps = record['reps'];
        final displayWeight =
            convertWeight(weight is String ? double.parse(weight) : weight);

        return ListTile(
          title: Text(exercise),
          subtitle: Text('${displayWeight.toStringAsFixed(1)} x $reps reps'),
        );
      },
    );
  }
}
