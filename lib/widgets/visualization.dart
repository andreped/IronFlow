import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database.dart';

class VisualizationTab extends StatefulWidget {
  @override
  _VisualizationTabState createState() => _VisualizationTabState();
}

class _VisualizationTabState extends State<VisualizationTab> {
  String? _selectedVariable;
  List<String> _variableNames = [];
  List<FlSpot> _dataPoints = [];

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _fetchVariableNames();
  }

  Future<void> _fetchVariableNames() async {
    final variables = await _dbHelper.getVariables();
    final names = variables.map((variable) => variable['name'] as String).toSet().toList();
    setState(() {
      _variableNames = names;
    });
  }

  Future<void> _fetchDataPoints(String variableName) async {
    final variables = await _dbHelper.getVariables();
    final filteredVariables = variables.where((variable) => variable['name'] == variableName).toList();

    final dataPoints = filteredVariables.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), double.parse(entry.value['value']));
    }).toList();

    setState(() {
      _dataPoints = dataPoints;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          DropdownButton<String>(
            hint: Text('Select a variable'),
            value: _selectedVariable,
            onChanged: (newValue) {
              setState(() {
                _selectedVariable = newValue;
                _fetchDataPoints(newValue!);
              });
            },
            items: _variableNames.map((variableName) {
              return DropdownMenuItem<String>(
                value: variableName,
                child: Text(variableName),
              );
            }).toList(),
          ),
          SizedBox(height: 16.0),
          Expanded(
            child: _dataPoints.isEmpty
                ? Center(child: Text('No data available'))
                : LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: _dataPoints,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      gridData: FlGridData(show: true),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
