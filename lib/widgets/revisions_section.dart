import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ouroboros_mobile/providers/review_provider.dart';
import 'package:ouroboros_mobile/models/data_models.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:ouroboros_mobile/providers/all_subjects_provider.dart';


class RevisionsSection extends StatelessWidget {
  const RevisionsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Próximas Revisões',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Consumer<ReviewProvider>(
              builder: (context, reviewProvider, child) {
                if (reviewProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final now = DateTime.now();
                final todayUtc = DateTime.utc(now.year, now.month, now.day);

                final todaysReviewRecords = reviewProvider.allReviewRecords.where((record) {
                  try {
                    final scheduledDate = DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').parse(record.scheduled_date, true).toUtc();
                    return (scheduledDate.isBefore(todayUtc) || scheduledDate.isAtSameMomentAs(todayUtc)) &&
                           record.completed_date == null &&
                           !record.ignored;
                  } catch (e) {
                    try {
                      // Try parsing without time
                      final scheduledDate = DateFormat('yyyy-MM-dd').parse(record.scheduled_date, true).toUtc();
                      return (scheduledDate.isBefore(todayUtc) || scheduledDate.isAtSameMomentAs(todayUtc)) &&
                             record.completed_date == null &&
                             !record.ignored;
                    } catch (e2) {
                      return false;
                    }
                  }
                }).toList();

                todaysReviewRecords.sort((a, b) => a.scheduled_date.compareTo(b.scheduled_date));

                if (todaysReviewRecords.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text('Nenhuma revisão pendente.'),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todaysReviewRecords.length > 5 ? 5 : todaysReviewRecords.length, // Limit to 5
                  itemBuilder: (context, index) {
                    final record = todaysReviewRecords[index];
                    return RevisionCard(record: record);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RevisionCard extends StatelessWidget {
  final ReviewRecord record;

  const RevisionCard({Key? key, required this.record}) : super(key: key);

  int getDaysOverdue(String scheduledDateStr) {
    try {
      final now = DateTime.now();
      final todayUtc = DateTime.utc(now.year, now.month, now.day);
      DateTime scheduledDate;
      try {
        scheduledDate = DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').parse(scheduledDateStr, true).toUtc();
      } catch (e) {
        scheduledDate = DateFormat('yyyy-MM-dd').parse(scheduledDateStr, true).toUtc();
      }
      final diff = todayUtc.difference(scheduledDate).inDays;
      return diff;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    final allSubjectsProvider = Provider.of<AllSubjectsProvider>(context, listen: false);
    final subject = allSubjectsProvider.subjects.firstWhere((s) => s.id == record.subject_id, orElse: () => Subject(id: '', plan_id: '', subject: 'Desconhecido', color: '#808080', topics: []));

    final daysOverdue = getDaysOverdue(record.scheduled_date);
    final bool isOverdue = daysOverdue > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.amber.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.subject,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.topic,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(MaterialCommunityIcons.check_circle_outline, color: Colors.green),
                      onPressed: () {
                        reviewProvider.markReviewAsCompleted(record);
                      },
                      tooltip: 'Marcar como concluída',
                    ),
                    IconButton(
                      icon: const Icon(MaterialCommunityIcons.close_circle_outline, color: Colors.red),
                      onPressed: () {
                        reviewProvider.ignoreReview(record);
                      },
                      tooltip: 'Ignorar por agora',
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              isOverdue ? 'Atrasada em $daysOverdue dia(s)' : 'Revisar hoje',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isOverdue ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
