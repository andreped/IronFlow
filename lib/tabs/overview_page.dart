import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class OverviewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            _buildUserProfileSection(),
            const SizedBox(height: 16),
            // Exercise Summary Section
            _buildExerciseSummarySection(),
            const SizedBox(height: 16),
            // Fitness Progress Section
            _buildFitnessProgressSection(),
            const SizedBox(height: 16),
            // Achievements and Goals Section
            _buildAchievementsAndGoalsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileSection() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Age: 25', style: TextStyle(fontSize: 18)),
            Text('Weight: 70 kg', style: TextStyle(fontSize: 18)),
            Text('Height: 175 cm', style: TextStyle(fontSize: 18)),
            Text('Last Logged: 2023-10-01', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseSummarySection() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Exercise Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Total Weight Lifted: 5000 kg', style: TextStyle(fontSize: 18)),
            Text('Most Common Exercise: Squats', style: TextStyle(fontSize: 18)),
            Text('Personal Records:', style: TextStyle(fontSize: 18)),
            Text('  - Squats: 100 kg', style: TextStyle(fontSize: 18)),
            Text('  - Bench Press: 80 kg', style: TextStyle(fontSize: 18)),
            Text('Recent Activity:', style: TextStyle(fontSize: 18)),
            Text('  - Squats: 80 kg, 5 reps, 3 sets', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildFitnessProgressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fitness Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildWeightProgressChart(),
            const SizedBox(height: 16),
            _buildExerciseFrequencyChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightProgressChart() {
    return Container(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(show: true),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: [
                const FlSpot(0, 70),
                const FlSpot(1, 72),
                const FlSpot(2, 71),
                const FlSpot(3, 73),
                const FlSpot(4, 74),
              ],
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

  Widget _buildExerciseFrequencyChart() {
    return Container(
      height: 200,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(show: true),
          borderData: FlBorderData(show: true),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 5, color: Colors.blue)]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 6, color: Colors.blue)]),
            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 8, color: Colors.blue)]),
            BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 7, color: Colors.blue)]),
            BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 9, color: Colors.blue)]),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsAndGoalsSection() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Achievements and Goals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('New High Scores:', style: TextStyle(fontSize: 18)),
            Text('  - Squats: 100 kg', style: TextStyle(fontSize: 18)),
            Text('Goals:', style: TextStyle(fontSize: 18)),
            Text('  - Reach 75 kg body weight', style: TextStyle(fontSize: 18)),
            Text('  - Squat 120 kg', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}