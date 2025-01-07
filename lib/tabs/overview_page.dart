import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/database.dart'; // Import the database helper

class OverviewPage extends StatefulWidget {
  @override
  _OverviewPageState createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  late Future<Map<String, dynamic>> _userProfileData;
  late Future<Map<String, dynamic>> _exerciseSummaryData;
  late Future<List<FlSpot>> _weightProgressData;
  late Future<List<BarChartGroupData>> _exerciseFrequencyData;

  @override
  void initState() {
    super.initState();
    _userProfileData = _fetchUserProfileData();
    _exerciseSummaryData = _fetchExerciseSummaryData();
    _weightProgressData = _fetchWeightProgressData();
    _exerciseFrequencyData = _fetchExerciseFrequencyData();
  }

  Future<Map<String, dynamic>> _fetchUserProfileData() async {
    final db = DatabaseHelper();
    final fitnessData = await db.getLastLoggedFitness();
    return fitnessData ?? {};
  }

  Future<Map<String, dynamic>> _fetchExerciseSummaryData() async {
    final db = DatabaseHelper();
    final totalWeightLifted = await db.getTotalWeightLifted();
    final mostCommonExercise = await db.getMostCommonExercise();
    final personalRecords = await db.getPersonalRecords();
    final trainingTimeData = await db.getTotalAndAverageTrainingTime();
    final totalTrainingTime = trainingTimeData['totalTrainingTime'];
    final averageTrainingTime = trainingTimeData['averageTrainingTime'];
    return {
      'totalWeightLifted': totalWeightLifted,
      'mostCommonExercise': mostCommonExercise,
      'personalRecords': personalRecords,
      'totalTrainingTime': totalTrainingTime,
      'averageTrainingTime': averageTrainingTime,
    };
  }

  Future<List<FlSpot>> _fetchWeightProgressData() async {
    final db = DatabaseHelper();
    final weightProgress = await db.getWeightProgress();
    return weightProgress
        .map((data) => FlSpot(
              DateTime.parse(data['timestamp'])
                  .millisecondsSinceEpoch
                  .toDouble(),
              data['weight'] as double,
            ))
        .toList();
  }

  Future<List<BarChartGroupData>> _fetchExerciseFrequencyData() async {
    final db = DatabaseHelper();
    final exerciseFrequency = await db.getExerciseFrequency();
    return exerciseFrequency
        .map((data) => BarChartGroupData(
              x: DateTime.parse(data['day']).millisecondsSinceEpoch,
              barRods: [
                BarChartRodData(
                    toY: (data['count'] as int).toDouble(),
                    color: Theme.of(context).colorScheme.primary)
              ],
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            FutureBuilder<Map<String, dynamic>>(
              future: _userProfileData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  final data = snapshot.data!;
                  return _buildUserProfileSection(data);
                }
              },
            ),
            const SizedBox(height: 16),
            // Fitness Progress Section
            FutureBuilder<List<FlSpot>>(
              future: _weightProgressData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  final data = snapshot.data!;
                  return _buildWeightProgressChart(data);
                }
              },
            ),
            const SizedBox(height: 16),
            // Exercise Summary Section
            FutureBuilder<Map<String, dynamic>>(
              future: _exerciseSummaryData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  final data = snapshot.data!;
                  return _buildExerciseSummarySection(data);
                }
              },
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<BarChartGroupData>>(
              future: _exerciseFrequencyData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  final data = snapshot.data!;
                  return _buildExerciseFrequencyChart(data);
                }
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileSection(Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('User Profile',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Age: ${data['age']}', style: const TextStyle(fontSize: 18)),
            Text('Weight: ${data['weight']} kg',
                style: const TextStyle(fontSize: 18)),
            Text('Height: ${data['height']} cm',
                style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseSummarySection(Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Exercise Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Most Common Exercise: ${data['mostCommonExercise']}',
                style: const TextStyle(fontSize: 18)),
            const Text('Top 3 heaviest lifts:', style: TextStyle(fontSize: 18)),
            ...data['personalRecords'].entries.map<Widget>((entry) => Text(
                '  - ${entry.key}: ${entry.value} kg',
                style: const TextStyle(fontSize: 18))),
            Text(
                'Total Weight Lifted: ${(data['totalWeightLifted'] / 1000).toStringAsFixed(3)} tons',
                style: const TextStyle(fontSize: 18)),
            Text(
                'Total Training Time: ${data['totalTrainingTime'].toStringAsFixed(3)} hours',
                style: const TextStyle(fontSize: 18)),
            Text(
                'Average Training Time: ${data['averageTrainingTime'].toStringAsFixed(3)} hours',
                style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightProgressChart(List<FlSpot> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
            child: Text('Weight Progress',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16.0), // Add padding to the left and right
          child: SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50, // Add more space for y-axis labels
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          value.toString(),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50, // Add more space for x-axis labels
                      interval:
                          7 * 24 * 60 * 60 * 1000, // Show titles every week
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final DateTime date =
                            DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return Padding(
                          padding: const EdgeInsets.only(
                              top:
                                  16.0), // Add more padding between x-axis and labels
                          child: Transform.rotate(
                            angle: -60 *
                                (3.141592653589793 /
                                    180), // Rotate by -60 degrees
                            child: Text('${date.month}/${date.day}'),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: data,
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 4,
                    belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseFrequencyChart(List<BarChartGroupData> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
            child: Text('Exercise Frequency',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16.0), // Add padding to the left and right
          child: SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50, // Add more space for y-axis labels
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          value.toString(),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50, // Add more space for x-axis labels
                      interval:
                          7 * 24 * 60 * 60 * 1000, // Show titles every week
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final DateTime date =
                            DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return Padding(
                          padding: const EdgeInsets.only(
                              top:
                                  16.0), // Add more padding between x-axis and labels
                          child: Transform.rotate(
                            angle: -60 *
                                (3.141592653589793 /
                                    180), // Rotate by -60 degrees
                            child: Text('${date.month}/${date.day}'),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                barGroups: data,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
