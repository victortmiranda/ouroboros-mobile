import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ouroboros_mobile/models/data_models.dart';

class DisciplinasDesempenhoChart extends StatelessWidget {
  final Map<Subject, SubjectPerformanceData> subjectPerformanceData;

  const DisciplinasDesempenhoChart({super.key, required this.subjectPerformanceData});

  @override
  Widget build(BuildContext context) {
    // Etapa 1: Ordenar alfabeticamente
    final sortedSubjects = subjectPerformanceData.keys.toList();
    sortedSubjects.sort((a, b) => a.subject.compareTo(b.subject));

    if (sortedSubjects.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(child: Text('Nenhum dado de desempenho para exibir.')),
      );
    }

    // Etapa 2: Construir os grupos de barras
    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < sortedSubjects.length; i++) {
      final subject = sortedSubjects[i];
      final data = subjectPerformanceData[subject]!;
      
      final barRodWidth = 8.0;
      final spaceBetweenBars = 2.0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barsSpace: spaceBetweenBars,
          barRods: [
            // Barra de Acertos
            BarChartRodData(
              toY: data.correctPercentage,
              color: Colors.amber, // Etapa 3: Ajustar cor
              width: barRodWidth,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(2),
              ),
            ),
            // Barra de Erros
            BarChartRodData(
              toY: data.incorrectPercentage,
              color: Colors.deepOrangeAccent, // Etapa 3: Ajustar cor
              width: barRodWidth,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(2),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 400,
          width: double.infinity,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: barGroups,
              minY: 0,
              maxY: 100,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value % 20 == 0) {
                        return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10));
                      }
                      return const Text('');
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 120, 
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < sortedSubjects.length) {
                        final subject = sortedSubjects[value.toInt()];
                        return RotatedBox(
                          quarterTurns: -1,
                          child: Text(
                            subject.subject,
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.end,
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final subject = sortedSubjects[group.x.toInt()];
                    String label = rodIndex == 0 ? 'Acertos' : 'Erros';
                    return BarTooltipItem(
                      '${subject.subject}\n$label: ${rod.toY.toStringAsFixed(1)}%',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return const FlLine(
                    color: Colors.grey,
                    strokeWidth: 0.2,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Etapa 4: Legenda
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(Colors.amber, 'Acertos'),
        const SizedBox(width: 16),
        _legendItem(Colors.deepOrangeAccent, 'Erros'),
      ],
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
