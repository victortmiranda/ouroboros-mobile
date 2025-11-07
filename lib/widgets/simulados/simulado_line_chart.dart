import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ouroboros_mobile/models/simulado_record.dart';

class SimuladoLineChart extends StatelessWidget {
  final List<SimuladoRecord> simulados;
  final String chartType;

  const SimuladoLineChart({
    Key? key,
    required this.simulados,
    required this.chartType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (simulados.isEmpty) {
      return const Center(
        child: Text('Registre simulados para ver seu desempenho aqui.'),
      );
    }

    final List<FlSpot> spots = simulados.asMap().entries.map((entry) {
      final index = entry.key;
      final simulado = entry.value;
      final value = chartType == 'desempenho' ? simulado.performance : simulado.totalScore;
      return FlSpot(index.toDouble(), value.toDouble());
    }).toList();

    final List<String> labels = simulados.map((s) => '${s.date.day}/${s.date.month}').toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(labels[value.toInt()], style: const TextStyle(fontSize: 10)),
                );
              },
              interval: 1,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
              },
              interval: 10,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: chartType == 'desempenho' ? Colors.teal : Colors.deepPurple,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}