import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HorasEstudoChart extends StatelessWidget {
  final Map<DateTime, double> dailyHours;

  const HorasEstudoChart({super.key, required this.dailyHours});

  @override
  Widget build(BuildContext context) {
    final sortedDates = dailyHours.keys.toList()..sort();

    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final hours = dailyHours[date]!;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: hours,
              color: Colors.amber,
              width: 16,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: barGroups,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final hours = rod.toY.toInt();
                final minutes = ((rod.toY - hours) * 60).toInt();
                return BarTooltipItem(
                  '${hours.toString().padLeft(2, '0')}h${minutes.toString().padLeft(2, '0')}m',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                    final date = sortedDates[value.toInt()];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(DateFormat('dd/MM').format(date), style: const TextStyle(fontSize: 10)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final hours = value.toInt();
                  final minutes = ((value - hours) * 60).toInt();
                  return Text(
                    '${hours.toString().padLeft(2, '0')}h${minutes.toString().padLeft(2, '0')}m',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }
}
