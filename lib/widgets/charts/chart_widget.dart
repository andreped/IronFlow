import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ChartWidget extends StatelessWidget {
  final List<ScatterSpot> dataPoints;
  final String chartType;
  final Color scatterColor;
  final Color lineColor;
  final Color axisTextColor;
  final bool isKg;

  const ChartWidget({
    super.key,
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
              reservedSize: 45,
              getTitlesWidget: (value, meta) =>
                  _bottomTitleWidgets(value, meta),
            ),
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                'Date',
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
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipMargin: 8,
            tooltipHorizontalAlignment: FLHorizontalAlignment.left,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                return LineTooltipItem(
                  _formatTooltip(touchedSpot.x, touchedSpot.y),
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
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
              reservedSize: 45,
              getTitlesWidget: (value, meta) =>
                  _bottomTitleWidgets(value, meta),
            ),
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                'Date',
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
          touchTooltipData: ScatterTouchTooltipData(
            getTooltipColor: (ScatterSpot spot) => Colors.blueGrey,
            tooltipHorizontalAlignment: FLHorizontalAlignment.left,
            getTooltipItems: (ScatterSpot touchedSpot) {
              return ScatterTooltipItem(
                _formatTooltip(touchedSpot.x, touchedSpot.y),
                textStyle: const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final style = TextStyle(
      color: axisTextColor,
      fontSize: 14, // Increased font size
    );
    final date = DateTime.now().add(Duration(days: value.toInt()));
    final formattedDate = DateFormat('dd/MM').format(date);
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8.0, // Increased space to move the labels downwards
      child: Transform.rotate(
        angle: -45 * 3.1415927 / 180,
        child: Text(formattedDate, style: style),
      ),
    );
  }

  String _formatTooltip(double x, double y) {
    final date = DateTime.now().add(Duration(days: x.toInt()));
    final formattedDate = DateFormat('dd/MM').format(date);
    return 'x=$formattedDate\ny=${y.toStringAsFixed(2)}';
  }
}
