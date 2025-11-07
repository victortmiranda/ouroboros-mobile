import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ouroboros_mobile/providers/all_subjects_provider.dart';
import 'package:ouroboros_mobile/models/data_models.dart';
import 'package:ouroboros_mobile/screens/subject_detail_screen.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AllSubjectsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.subjects.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma matéria encontrada.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: <Widget>[
              // Header: Title and Description
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Visão Geral das Matérias',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Acompanhe seu progresso em todas as disciplinas.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),

              // Overall Stats Card (Placeholder for now)
              Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      _buildOverallStat(context, Icons.book, '0h 0m', 'Total de Horas'),
                      _buildOverallStat(context, Icons.quiz, '0', 'Total de Questões'),
                      _buildOverallStat(context, Icons.bar_chart, '0%', 'Desempenho Geral'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24.0),

              // List of Subject Cards
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 colunas
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 1.0, // Ajuste conforme necessário para o tamanho do card
                ),
                itemCount: provider.subjects.length,
                itemBuilder: (context, index) {
                  final subject = provider.subjects[index];
                  final planNames = provider.subjects
                      .where((s) => s.id == subject.id) // Filter for the current subject
                      .map((s) => provider.plansMap[s.plan_id]?.name ?? 'Plano Desconhecido')
                      .toList();

                  final studyHours = provider.getStudyHoursForSubject(subject.id);
                  final questions = provider.getQuestionsForSubject(subject.id);
                  final performance = provider.getPerformanceForSubject(subject.id);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubjectDetailScreen(subject: subject),
                        ),
                      );
                    },
                    child: _buildSubjectCard(context, subject, studyHours, questions.toString(), performance, planNames),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverallStat(BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: <Widget>[
        Icon(icon, size: 24, color: Colors.amber),
        const SizedBox(height: 4.0),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
      ],
    );
  }

  Widget _buildSubjectCard(BuildContext context, Subject subject, String studyHours, String questions, String performance, List<String> plans) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Color(int.parse(subject.color.replaceFirst('#', '0xFF'))), width: 2), // Use subject color
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              subject.subject,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildOverallStat(context, Icons.timer, studyHours, 'Horas'),
                const SizedBox(width: 8.0),
                _buildOverallStat(context, Icons.check_circle, questions, 'Questões'),
                const SizedBox(width: 8.0),
                _buildOverallStat(context, Icons.trending_up, performance, 'Desempenho'),
              ],
            ),
            const SizedBox(height: 8.0),
            Text('Presente nos Planos:', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4.0),
            Wrap(
              spacing: 4.0,
              runSpacing: 2.0,
              children: plans.map((plan) => Chip(label: Text(plan, style: const TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
