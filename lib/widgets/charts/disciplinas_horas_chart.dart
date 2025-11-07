import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ouroboros_mobile/models/data_models.dart';

class DisciplinasHorasChart extends StatelessWidget {
  final Map<Subject, double> subjectHours;
  final String sortOrder;

  const DisciplinasHorasChart({super.key, required this.subjectHours, this.sortOrder = 'desc'});

  static String _formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final sortedSubjects = subjectHours.keys.toList();

    if (sortOrder == 'desc') {
      sortedSubjects.sort((a, b) => subjectHours[b]!.compareTo(subjectHours[a]!));
    } else if (sortOrder == 'asc') {
      sortedSubjects.sort((a, b) => subjectHours[a]!.compareTo(subjectHours[b]!));
    } else { // alpha
      sortedSubjects.sort((a, b) => a.subject.compareTo(b.subject));
    }

    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < sortedSubjects.length; i++) {
      final subject = sortedSubjects[i];
      final hours = subjectHours[subject]!;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: hours,
              color: Colors.amber,
              width: 16,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 400,
      width: double.infinity, // Ajustar a largura para ocupar todo o espaço disponível
      child: RotatedBox(
        quarterTurns: 1,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            barGroups: barGroups,
            minY: 0,
            maxY: subjectHours.isNotEmpty ? subjectHours.values.reduce((a, b) => a > b ? a : b) * 1.2 : 1.0, // Ajusta o maxY para o maior valor + 20%
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40, // Aumentar o espaço para as horas
                  getTitlesWidget: (value, meta) {
                    if (value == meta.max) { // Não exibir o último valor
                      return const Text('');
                    }
                    return Align(
                      alignment: Alignment.centerLeft, // Alinhar as horas à esquerda
                      child: RotatedBox(
                        quarterTurns: -1,
                        child: Text(_formatHours(value), style: const TextStyle(fontSize: 10)), // Usar a função de formatação
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 150, // Espaço para os nomes das disciplinas
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < sortedSubjects.length) {
                      final subject = sortedSubjects[value.toInt()];
                      return Align(
                        alignment: Alignment.centerRight, // Alinhar os nomes das disciplinas à direita
                        child: RotatedBox(
                          quarterTurns: -1,
                          child: Text(subject.subject, style: const TextStyle(fontSize: 10)),
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
                  final hours = subjectHours[subject]!;
                  final h = hours.floor();
                  final m = ((hours - h) * 60).round();
                  return BarTooltipItem(
                    '${subject.subject}\n${h}h${m.toString().padLeft(2, '0')}min',
                    const TextStyle(color: Colors.white),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
