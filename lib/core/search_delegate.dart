import 'package:flutter/material.dart';
import 'theme.dart';

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
    final ThemeData theme = Theme.of(context);
    return [
      IconButton(
        icon: Icon(Icons.clear, color: theme.iconTheme.color),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return IconButton(
      icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
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
