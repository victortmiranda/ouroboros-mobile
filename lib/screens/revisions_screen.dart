import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ouroboros_mobile/models/data_models.dart';
import 'package:ouroboros_mobile/providers/review_provider.dart';
import 'package:ouroboros_mobile/providers/history_provider.dart';
import 'package:ouroboros_mobile/providers/active_plan_provider.dart';
import 'package:ouroboros_mobile/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

// --- Helper for time formatting ---
String formatTime(int milliseconds) {
  final totalSeconds = (milliseconds / 1000).floor();
  final hours = (totalSeconds / 3600).floor();
  final minutes = ((totalSeconds % 3600) / 60).floor();
  final seconds = totalSeconds % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

// --- Category Display Map ---
const Map<StudyCategory, String> categoryDisplayMap = {
  StudyCategory.teoria: 'Teoria',
  StudyCategory.revisao: 'Revisão',
  StudyCategory.questoes: 'Questões',
  StudyCategory.leituraLei: 'Leitura de Lei',
  StudyCategory.jurisprudencia: 'Jurisprudência',
};

// --- Category Color Map ---
Map<StudyCategory, Color> categoryColorMap = {
  StudyCategory.teoria: Colors.blue.shade200,
  StudyCategory.revisao: Colors.purple.shade200,
  StudyCategory.questoes: Colors.green.shade200,
  StudyCategory.leituraLei: Colors.yellow.shade200,
  StudyCategory.jurisprudencia: Colors.indigo.shade200,
};

// --- Subject Color Map (Placeholder) ---
const Map<String, Color> subjectColorMap = {
  'Língua Portuguesa': Colors.blue,
  'Direito Administrativo': Colors.red,
  'Direito Constitucional': Colors.green,
  'Informática': Colors.purple,
};

// --- Main Screen Widget ---
class RevisionsScreen extends StatefulWidget {
  const RevisionsScreen({super.key});

  @override
  State<RevisionsScreen> createState() => _RevisionsScreenState();
}

enum ReviewTab {
  scheduled,
  overdue,
  ignored,
  completed,
}

const Map<ReviewTab, String> _reviewTabNames = {
  ReviewTab.scheduled: 'Programadas',
  ReviewTab.overdue: 'Atrasadas',
  ReviewTab.ignored: 'Ignoradas',
  ReviewTab.completed: 'Concluídas',
};

class _RevisionsScreenState extends State<RevisionsScreen> {
  ReviewTab _activeTab = ReviewTab.scheduled;

  @override
  void initState() {
    super.initState();
  }

  String _getDaysRemainingText(DateTime scheduledDate) {
    final today = DateTime.now();
    final diff = scheduledDate.difference(today);
    final diffDays = diff.inDays;

    if (diffDays == 0) return 'HOJE';
    if (diffDays == 1) return 'AMANHÃ';
    if (diffDays > 1) return '${diffDays} DIAS';
    return '${diffDays.abs()} DIAS ATRASADOS';
  }

  List<ReviewRecord> _filteredReviewRecords(List<ReviewRecord> allReviewRecords) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return allReviewRecords.where((record) {
      final scheduledDate = DateTime.parse(record.scheduled_date);

      if (_activeTab == ReviewTab.scheduled) {
        return !record.ignored && record.completed_date == null && scheduledDate.isAfter(today) || scheduledDate.isAtSameMomentAs(today);
      } else if (_activeTab == ReviewTab.overdue) {
        return !record.ignored && record.completed_date == null && scheduledDate.isBefore(today);
      } else if (_activeTab == ReviewTab.ignored) {
        return record.ignored;
      } else if (_activeTab == ReviewTab.completed) {
        return record.completed_date != null;
      }
      return true;
    }).toList();
  }

  Map<String, List<ReviewRecord>> _groupedReviewRecords(List<ReviewRecord> allReviewRecords) {
    final Map<String, List<ReviewRecord>> groups = {};
    for (var record in _filteredReviewRecords(allReviewRecords)) {
      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.parse(record.scheduled_date));
      if (!groups.containsKey(dateKey)) {
        groups[dateKey] = [];
      }
      groups[dateKey]!.add(record);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    print('RevisionsScreen: build chamado.');
    return Consumer2<ReviewProvider, HistoryProvider>(
      builder: (context, reviewProvider, historyProvider, child) {
        print('RevisionsScreen Consumer: reviewProvider.isLoading=${reviewProvider.isLoading}, historyProvider.isLoading=${historyProvider.isLoading}');
        if (reviewProvider.isLoading || historyProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<ReviewRecord> allReviewRecords = reviewProvider.allReviewRecords;
        final List<StudyRecord> allStudyRecords = historyProvider.allStudyRecords;
        print('RevisionsScreen Consumer: allReviewRecords.length=${allReviewRecords.length}, allStudyRecords.length=${allStudyRecords.length}');

        return Scaffold(
          body: Column(
            children: [
              _buildTabButtons(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _filteredReviewRecords(allReviewRecords).isEmpty
                          ? _buildNoRecordsMessage()
                          : Column(
                              children: _groupedReviewRecords(allReviewRecords).entries.map((entry) {
                                final dateKey = entry.key;
                                final recordsForDate = entry.value;
                                return _buildDateSection(context, dateKey, recordsForDate, allStudyRecords, reviewProvider, historyProvider);
                              }).toList() as List<Widget>,
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).scaffoldBackgroundColor, // Match background
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ReviewTab.values.map((tab) {
          return Expanded(
            child: TextButton(
              onPressed: () => setState(() => _activeTab = tab),
              style: TextButton.styleFrom(
                foregroundColor: _activeTab == tab ? Colors.white : Colors.grey[700],
                backgroundColor: _activeTab == tab ? Theme.of(context).primaryColor : Colors.grey[200],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(_reviewTabNames[tab]!),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNoRecordsMessage() {
    String message;
    switch (_activeTab) {
      case ReviewTab.scheduled: message = 'Nenhuma revisão programada.'; break;
      case ReviewTab.overdue: message = 'Nenhuma revisão atrasada.'; break;
      case ReviewTab.ignored: message = 'Nenhuma revisão ignorada.'; break;
      case ReviewTab.completed: message = 'Nenhuma revisão concluída.'; break;
    }
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Text(message, style: const TextStyle(fontSize: 16, color: Colors.grey)),
      ),
    );
  }

  Widget _buildDateSection(BuildContext context, String dateKey, List<ReviewRecord> records, List<StudyRecord> allStudyRecords, ReviewProvider reviewProvider, HistoryProvider historyProvider) {
    final scheduledDate = DateTime.parse(dateKey);
    final daysText = _getDaysRemainingText(scheduledDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Text(
                daysText,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Container(
                  height: 2,
                  color: Theme.of(context).primaryColor,
                  margin: const EdgeInsets.only(left: 16.0),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: records.map((record) => _ReviewRecordCard(
            reviewRecord: record,
            studyRecords: allStudyRecords,
            reviewProvider: reviewProvider,
            historyProvider: historyProvider,
            getDaysRemainingText: _getDaysRemainingText,
          )).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

}

class _ReviewRecordCard extends StatelessWidget {
  final ReviewRecord reviewRecord;
  final List<StudyRecord> studyRecords;
  final ReviewProvider reviewProvider;
  final HistoryProvider historyProvider;
  final Function(DateTime) getDaysRemainingText;

  const _ReviewRecordCard({
    required this.reviewRecord,
    required this.studyRecords,
    required this.reviewProvider,
    required this.historyProvider,
    required this.getDaysRemainingText,
  });

  StudyCategory _getStudyCategoryFromString(String categoryString) {
    switch (categoryString) {
      case 'teoria':
        return StudyCategory.teoria;
      case 'revisao':
        return StudyCategory.revisao;
      case 'questoes':
        return StudyCategory.questoes;
      case 'leitura_lei':
        return StudyCategory.leituraLei;
      case 'jurisprudencia':
        return StudyCategory.jurisprudencia;
      default:
        return StudyCategory.teoria; // Valor padrão ou tratamento de erro
    }
  }

  @override
  Widget build(BuildContext context) {
    final studyRecord = studyRecords.firstWhere(
      (sr) => sr.id == reviewRecord.study_record_id,
      orElse: () {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        return StudyRecord(
          id: '',
          userId: authProvider.currentUser?.name ?? '',
          plan_id: '',
          date: DateTime.now().toIso8601String(),
          subject_id: '',
          topic: 'Tópico não encontrado',
          study_time: 0,
          category: 'revisao',
          questions: {},
          review_periods: [],
          teoria_finalizada: false,
          count_in_planning: false,
          pages: [],
          videos: [],
        );
      },
    );

    final Color subjectColor = subjectColorMap[studyRecord.subject_id] ?? Colors.grey;
    final String daysText = getDaysRemainingText(DateTime.parse(reviewRecord.scheduled_date));

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Days Seal
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Theme.of(context).primaryColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    daysText,
                    style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                // Main Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Buttons and Subject
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(icon: const Icon(Icons.play_arrow), onPressed: () {
                                // TODO: Implementar lógica para iniciar revisão
                              }, tooltip: 'Iniciar Revisão'),
                              IconButton(icon: const Icon(Icons.check_circle), onPressed: () {
                                reviewProvider.markReviewAsCompleted(reviewRecord);
                              }, tooltip: 'Concluir'),
                              IconButton(icon: const Icon(Icons.cancel), onPressed: () {
                                reviewProvider.ignoreReview(reviewRecord);
                              }, tooltip: 'Ignorar'),
                            ],
                          ),
                          Text(
                            (historyProvider.allSubjectsMap[studyRecord.subject_id]?.subject ?? 'Desconhecido').toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Gray Indented Card Content
                      Card(
                        color: Colors.grey[100],
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Group 1: Identification
                              Row(
                                children: [
                                  Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(reviewRecord.scheduled_date))),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(reviewRecord.topic)),
                                  Chip(
                                    label: Text(categoryDisplayMap[_getStudyCategoryFromString(studyRecord.category)] ?? 'N/A'),
                                    backgroundColor: categoryColorMap[_getStudyCategoryFromString(studyRecord.category)] ?? Colors.grey[200],
                                    labelStyle: TextStyle(color: Colors.grey[800], fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Group 2: Metrics
                              Wrap(
                                spacing: 16.0,
                                runSpacing: 8.0,
                                children: [
                                  if (studyRecord.study_time > 0)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [const Icon(Icons.access_time, size: 16), const SizedBox(width: 4), Text(formatTime(studyRecord.study_time))],
                                    ),
                                  if ((studyRecord.questions['total'] ?? 0) > 0)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                        const SizedBox(width: 4),
                                        Text('${studyRecord.questions['correct'] ?? 0}'),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.cancel, size: 16, color: Colors.red),
                                        const SizedBox(width: 4),
                                        Text('${(studyRecord.questions['total'] ?? 0) - (studyRecord.questions['correct'] ?? 0)}'),
                                      ],
                                    ),
                                  if ((studyRecord.questions['total'] ?? 0) > 0)
                                    Text(
                                      '${((studyRecord.questions['correct'] ?? 0) / (studyRecord.questions['total'] ?? 1) * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Group 3: Materials and Action
                              Wrap(
                                spacing: 16.0,
                                runSpacing: 8.0,
                                children: [
                                  if (studyRecord.material != null && studyRecord.material!.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [const Icon(Icons.book, size: 16), const SizedBox(width: 4), Text(studyRecord.material!)],
                                    ),
                                  if (studyRecord.pages != null && studyRecord.pages!.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [const Icon(Icons.menu_book, size: 16), const SizedBox(width: 4), Text('Páginas: ${studyRecord.pages!.map((p) => '${p['start']}-${p['end']}').join(', ')}')],
                                    ),
                                  if (studyRecord.videos != null && studyRecord.videos!.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [const Icon(Icons.videocam, size: 16), const SizedBox(width: 4), Text('Vídeos: ${studyRecord.videos!.map((v) => '${v['title']} (${v['start']} - ${v['end']})').join(', ')}')],
                                    ),
                                  if (studyRecord.notes != null && studyRecord.notes!.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.comment, size: 16),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(studyRecord.notes!)),
                                        );
                                      },
                                      tooltip: 'Ver Comentários',
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ), // <--- THIS IS THE MISSING PARENTHESIS
          ],
        ),
      ),
    );
  }
}
