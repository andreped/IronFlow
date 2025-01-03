import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartWidget extends StatelessWidget {
  final List<ScatterSpot> dataPoints;
  final String chartType;
  final Color scatterColor;
  final Color lineColor;
  final Color axisTextColor;
  final bool isKg;

  ChartWidget({
    required this.dataPoints,
    required this.chartType,
    required this.scatterColor,
    required this.lineColor,
    required this.axisTextColor,
    required this.isKg,
  });

  @override
  Widget build(BuildContext context) {
    return chartType == 'Line' ? _buildLineChart() : _buildScatterChart();
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: dataPoints,
            isCurved: false,
            color: lineColor,
            belowBarData: BarAreaData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) =>
                  _bottomTitleWidgets(value, meta),
            ),
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                'Days',
                style: TextStyle(
                  color: axisTextColor,
                  fontSize: 14,
                ),
              ),
            ),
            axisNameSize: 30,
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final convertedValue = isKg ? value : value * 2.20462;
                return Text(
                  convertedValue.toStringAsFixed(1),
                  style: TextStyle(
                    color: axisTextColor,
                    fontSize: 14,
                  ),
                );
              },
              reservedSize: 50,
            ),
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                isKg ? 'Weight [kg]' : 'Weight [lbs]',
                style: TextStyle(
                  color: axisTextColor,
                  fontSize: 14,
                ),
              ),
            ),
            axisNameSize: 30,
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: axisTextColor,
            width: 0.75,
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: Colors.grey,
              strokeWidth: 0.5,
            );
          },
          getDrawingVerticalLine: (value) {
            return const FlLine(
              color: Colors.grey,
              strokeWidth: 0.5,
            );
          },
        ),
        lineTouchData: const LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
        ),
      ),
    );
  }

  Widget _buildScatterChart() {
    return ScatterChart(
      ScatterChartData(
        scatterSpots: dataPoints,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) =>
                  _bottomTitleWidgets(value, meta),
            ),
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                'Days',
                style: TextStyle(
                  color: axisTextColor,
                  fontSize: 14,
                ),
              ),
            ),
            axisNameSize: 30,
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final convertedValue = isKg ? value : value * 2.20462;
                return Text(
                  convertedValue.toStringAsFixed(1),
                  style: TextStyle(
                    color: axisTextColor,
                    fontSize: 14,
                  ),
                );
              },
              reservedSize: 50,
            ),
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                isKg ? 'Weight [kg]' : 'Weight [lbs]',
                style: TextStyle(
                  color: axisTextColor,
                  fontSize: 14,
                ),
              ),
            ),
            axisNameSize: 30,
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: axisTextColor,
            width: 0.75,
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: Colors.grey,
              strokeWidth: 0.5,
            );
          },
          getDrawingVerticalLine: (value) {
            return const FlLine(
              color: Colors.grey,
              strokeWidth: 0.5,
            );
          },
        ),
        scatterTouchData: ScatterTouchData(
          enabled: true,
          handleBuiltInTouches: true,
        ),
      ),
    );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    Widget text;
    switch (value.toInt()) {
      case 1:
        text = const Text('1', style: style);
        break;
      case 2:
        text = const Text('2', style: style);
        break;
      case 3:
        text = const Text('3', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4.0,
      child: text,
    );
  }
}
