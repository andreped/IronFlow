import 'package:flutter/material.dart';
import '../core/database.dart';

class RecordsTab extends StatefulWidget {
  @override
  _RecordsTabState createState() => _RecordsTabState();
}

class _RecordsTabState extends State<RecordsTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Map<String, double>> _getMaxWeights() async {
    return await _dbHelper.getMaxWeightsForExercises();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FutureBuilder<Map<String, double>>(
        future: _getMaxWeights(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No records available'));
          }

          final maxWeights = snapshot.data!;
          return ListView.builder(
            itemCount: maxWeights.length,
            itemBuilder: (context, index) {
              final exercise = maxWeights.keys.elementAt(index);
              final weight = maxWeights[exercise];
              return ListTile(
                title: Text(exercise),
                trailing: Text('${weight!.toStringAsFixed(2)} kg'),
              );
            },
          );
        },
      ),
    );
  }
}
