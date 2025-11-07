import 'package:flutter/material.dart';
import 'package:ouroboros_mobile/models/data_models.dart';

class PerformanceData {
  final Subject subject;
  final int totalQuestions;
  final int correctQuestions;
  final double performance;

  PerformanceData({
    required this.subject,
    required this.totalQuestions,
    required this.correctQuestions,
    required this.performance,
  });
}

class PerformanceTable extends StatelessWidget {
  final List<PerformanceData> performanceData;

  const PerformanceTable({Key? key, required this.performanceData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (performanceData.isEmpty) {
      return const Center(child: Text('Nenhum dado de desempenho ainda.'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: performanceData.length,
      itemBuilder: (context, index) {
        final data = performanceData[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(int.parse(data.subject.color.replaceFirst('#', '0xFF'))),
              child: Text(
                data.subject.subject.substring(0, 1),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(data.subject.subject),
            subtitle: Text('${data.correctQuestions}/${data.totalQuestions} questões corretas'),
            trailing: Text(
              '${data.performance.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: data.performance >= 70 ? Colors.green : (data.performance >= 50 ? Colors.orange : Colors.red),
              ),
            ),
          ),
        );
      },
    );
  }
}
