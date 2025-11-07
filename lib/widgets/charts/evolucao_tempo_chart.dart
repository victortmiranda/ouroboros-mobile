import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EvolucaoTempoChart extends StatelessWidget {
  final Map<DateTime, Map<String, int>> dailyStats;

  const EvolucaoTempoChart({super.key, required this.dailyStats});

  @override
  Widget build(BuildContext context) {
    final sortedDates = dailyStats.keys.toList()..sort();

    final List<FlSpot> correctSpots = [];
    final List<FlSpot> incorrectSpots = [];

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final stats = dailyStats[date]!;
      correctSpots.add(FlSpot(i.toDouble(), (stats['correct'] ?? 0).toDouble()));
      incorrectSpots.add(FlSpot(i.toDouble(), (stats['incorrect'] ?? 0).toDouble()));
    }

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                    final date = sortedDates[value.toInt()];
                    return Text(DateFormat('dd/MM').format(date), style: const TextStyle(fontSize: 10));
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            _buildLineChartBarData(correctSpots, Colors.green),
            _buildLineChartBarData(incorrectSpots, Colors.red),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLineChartBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
}
