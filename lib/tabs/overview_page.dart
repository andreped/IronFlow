import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/database.dart'; // Import the database helper

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  OverviewPageState createState() => OverviewPageState();
}

class OverviewPageState extends State<OverviewPage> {
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
    final totalTrainingTime = await db.getTotalTrainingTime();
    return {
      'totalWeightLifted': totalWeightLifted,
      'mostCommonExercise': mostCommonExercise,
      'personalRecords': personalRecords,
      'totalTrainingTime': totalTrainingTime,
    };
  }

  Future<List<FlSpot>> _fetchWeightProgressData() async {
    final db = DatabaseHelper();
    final weightProgress = await db.getWeightProgress();
    return weightProgress.map((data) => FlSpot(
      DateTime.parse(data['timestamp']).millisecondsSinceEpoch.toDouble(),
      data['weight'] as double,
    )).toList();
  }

  Future<List<BarChartGroupData>> _fetchExerciseFrequencyData() async {
    final db = DatabaseHelper();
    final exerciseFrequency = await db.getExerciseFrequency();
    return exerciseFrequency.map((data) => BarChartGroupData(
      x: DateTime.parse(data['day']).millisecondsSinceEpoch,
      barRods: [BarChartRodData(toY: data['count'] as double, color: Colors.blue)],
    )).toList();
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
            const Text('User Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Age: ${data['age']}', style: const TextStyle(fontSize: 18)),
            Text('Weight: ${data['weight']} kg', style: const TextStyle(fontSize: 18)),
            Text('Height: ${data['height']} cm', style: const TextStyle(fontSize: 18)),
            Text('Last Logged: ${data['timestamp']}', style: const TextStyle(fontSize: 18)),
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
            const Text('Exercise Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Total Weight Lifted: ${data['totalWeightLifted']} kg', style: const TextStyle(fontSize: 18)),
            Text('Most Common Exercise: ${data['mostCommonExercise']}', style: const TextStyle(fontSize: 18)),
            const Text('Personal Records:', style: TextStyle(fontSize: 18)),
            ...data['personalRecords'].entries.map<Widget>((entry) => Text('  - ${entry.key}: ${entry.value} kg', style: const TextStyle(fontSize: 18))),
            Text('Total Training Time: ${data['totalTrainingTime']} hours', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightProgressChart(List<FlSpot> data) {
    return Container(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(show: true),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: data,
              isCurved: true,
              color: Colors.blue,
              barWidth: 4,
              belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.3)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseFrequencyChart(List<BarChartGroupData> data) {
    return Container(
      height: 200,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(show: true),
          borderData: FlBorderData(show: true),
          barGroups: data,
        ),
      ),
    );
  }
}