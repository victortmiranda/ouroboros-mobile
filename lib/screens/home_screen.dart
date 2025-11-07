import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import 'package:ouroboros_mobile/providers/history_provider.dart';
import 'package:ouroboros_mobile/providers/plans_provider.dart';
import 'package:ouroboros_mobile/providers/active_plan_provider.dart';
import 'package:ouroboros_mobile/providers/all_subjects_provider.dart';
import 'package:ouroboros_mobile/models/data_models.dart';
import 'package:ouroboros_mobile/widgets/study_consistency_grid.dart';
import 'package:ouroboros_mobile/widgets/performance_table.dart';
import 'package:ouroboros_mobile/widgets/weekly_bar_chart.dart';
import 'package:ouroboros_mobile/widgets/revisions_section.dart';
import 'package:ouroboros_mobile/widgets/planning_section.dart';
import 'package:ouroboros_mobile/widgets/last_activities_section.dart';
import 'package:ouroboros_mobile/widgets/daily_study_section.dart';
import 'package:ouroboros_mobile/widgets/reminders_section.dart';
import 'package:ouroboros_mobile/providers/planning_provider.dart';

enum ChartView { time, questions }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Duration _totalStudyTime = Duration.zero;
  Duration _dailyAverage = Duration.zero;
  double _performance = 0.0;
  double _progress = 0.0;
  Set<DateTime> _studiedDays = {};
  int _studyStreak = 0;
  List<PerformanceData> _performanceData = [];
  List<Duration> _weeklyData = List.filled(7, Duration.zero);
  List<int> _weeklyQuestionsData = List.filled(7, 0); // Added this line
  Map<String, Map<String, int>> _dailySubjectStudyTime = {};
  List<Subject> _subjectColors = [];
  Duration _weeklyHours = Duration.zero;
  Duration _goalHours = Duration.zero;
  int _weeklyQuestions = 0;
  int _goalQuestions = 0;
  ChartView _chartView = ChartView.time;

  // New state for StudyConsistencyTracker
  DateTime _consistencyEndDate = DateTime.now();
  List<Map<String, dynamic>> _consistencyData = [];

  void _handleConsistencyNav(int direction) { // direction is -1 for prev, 1 for next
    final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
    setState(() {
      _consistencyEndDate = _consistencyEndDate.add(Duration(days: direction * 15));
      _calculateConsistencyData(planningProvider); // Recalculate data for the new date range
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAndCalculateData();
    });
  }

  void _calculateConsistencyData(PlanningProvider planningProvider) {
    final today = DateTime.now();
    final todayWithoutTime = DateTime(today.year, today.month, today.day);
    final endDate = DateTime(_consistencyEndDate.year, _consistencyEndDate.month, _consistencyEndDate.day);
    final startDate = endDate.subtract(const Duration(days: 29)); // 30 days total

    final studyDays = planningProvider.studyDays;
    final dayFormatter = DateFormat('EEEE', 'pt_BR');

    final List<Map<String, dynamic>> daysData = [];
    for (int i = 0; i < 30; i++) { // Loop for 30 days
      final date = startDate.add(Duration(days: i));
      final dayName = dayFormatter.format(date);
      final isStudied = _studiedDays.contains(date);
      // Correctly check if the formatted day name (e.g., 'segunda-feira') corresponds to a stored study day (e.g., 'Segunda')
      final isStudyDay = studyDays.any((d) => dayName.toLowerCase().startsWith(d.toLowerCase()));
      final isRestDay = !isStudyDay;

      String status;
      if (isRestDay) {
        status = 'rest_day';
      } else {
        status = isStudied ? 'studied' : 'not_studied';
      }

      daysData.add({
        'date': date,
        'status': status,
        'active': date.isBefore(todayWithoutTime) || date.isAtSameMomentAs(todayWithoutTime),
      });
    }
    _consistencyData = daysData;
  }

  Future<void> _fetchAndCalculateData() async {
    setState(() {
      _isLoading = true;
    });

    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
    final activePlanProvider = Provider.of<ActivePlanProvider>(context, listen: false);
    final allSubjectsProvider = Provider.of<AllSubjectsProvider>(context, listen: false);
    final planningProvider = Provider.of<PlanningProvider>(context, listen: false);

    // Assuming providers are already fetched by a higher-level widget or main.dart

    final allRecords = historyProvider.allStudyRecords;

    // Calculate Total Study Time
    final totalMs = allRecords.fold<int>(0, (sum, record) => sum + record.study_time);
    _totalStudyTime = Duration(milliseconds: totalMs);

    // Calculate Daily Average
    if (allRecords.isNotEmpty) {
      final Map<DateTime, int> dailyTotals = {};
      for (var record in allRecords) {
        try {
          final date = DateTime.parse(record.date).toLocal();
          final day = DateTime(date.year, date.month, date.day);
          dailyTotals[day] = (dailyTotals[day] ?? 0) + record.study_time;
        } catch (e) {
          print('Invalid date format in record: ${record.id}');
        }
      }
      if (dailyTotals.isNotEmpty) {
        final averageMs = totalMs / dailyTotals.length;
        _dailyAverage = Duration(milliseconds: averageMs.round());
      }
    }

    // Calculate Performance
    int totalQuestions = 0;
    int correctQuestions = 0;
    for (var record in allRecords) {
      if (record.questions.containsKey('total') && record.questions['total'] is int) {
        totalQuestions += record.questions['total'] as int;
      }
      if (record.questions.containsKey('correct') && record.questions['correct'] is int) {
        correctQuestions += record.questions['correct'] as int;
      }
    }
    _performance = totalQuestions > 0 ? (correctQuestions / totalQuestions) * 100 : 0.0;

    // Calculate Syllabus Progress
    final activePlanId = activePlanProvider.activePlanId;
    if (activePlanId != null) {
      final subjectsInPlan = allSubjectsProvider.subjects.where((s) => s.plan_id == activePlanId).toList();
      final totalTopics = subjectsInPlan.fold<int>(0, (sum, subject) => sum + (subject.total_topics_count ?? 0));
      
      final studiedTopics = <String>{};
      for (var record in allRecords.where((r) => r.plan_id == activePlanId)) {
        studiedTopics.add(record.topic);
      }
      
      _progress = totalTopics > 0 ? (studiedTopics.length / totalTopics) * 100 : 0.0;
    }

    // Calculate Studied Days and Streak
    if (allRecords.isNotEmpty) {
      final uniqueStudyDays = allRecords.map((record) {
        try {
          final date = DateTime.parse(record.date).toLocal();
          return DateTime(date.year, date.month, date.day);
        } catch (e) {
          return null;
        }
      }).where((d) => d != null).cast<DateTime>().toSet();
      _studiedDays = uniqueStudyDays;

      // Calculate streak
      _studyStreak = 0;
      var checkDate = DateTime.now();
      var today = DateTime(checkDate.year, checkDate.month, checkDate.day);
      
      if (!uniqueStudyDays.contains(today)) {
        checkDate = checkDate.subtract(const Duration(days: 1));
      }

      while (uniqueStudyDays.contains(DateTime(checkDate.year, checkDate.month, checkDate.day))) {
        _studyStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    // Calculate consistency data for the grid
    _calculateConsistencyData(planningProvider);

    // Calculate Performance Data per Subject
    final Map<String, Map<String, int>> subjectPerformance = {};
    for (var record in allRecords) {
      final subjectId = record.subject_id;
      if (subjectId != null) {
        subjectPerformance.putIfAbsent(subjectId, () => {'total': 0, 'correct': 0});
        if (record.questions.containsKey('total') && record.questions['total'] is int) {
          subjectPerformance[subjectId]!['total'] = (subjectPerformance[subjectId]!['total'] ?? 0) + (record.questions['total'] as int);
        }
        if (record.questions.containsKey('correct') && record.questions['correct'] is int) {
          subjectPerformance[subjectId]!['correct'] = (subjectPerformance[subjectId]!['correct'] ?? 0) + (record.questions['correct'] as int);
        }
      }
    }

    _performanceData = [];
    for (var entry in subjectPerformance.entries) {
      final subject = allSubjectsProvider.subjects.firstWhere((s) => s.id == entry.key, orElse: () => Subject(id: '', plan_id: '', subject: 'Desconhecido', color: '#808080', topics: [], total_topics_count: 0));
      final total = entry.value['total'] ?? 0;
      final correct = entry.value['correct'] ?? 0;
      final performance = total > 0 ? (correct / total) * 100 : 0.0;
      _performanceData.add(PerformanceData(
        subject: subject,
        totalQuestions: total,
        correctQuestions: correct,
        performance: performance,
      ));
    }
    // Sort by performance
    _performanceData.sort((a, b) => a.performance.compareTo(b.performance));

    // Calculate Weekly Data
    _weeklyData = List.filled(7, Duration.zero);
    _weeklyQuestionsData = List.filled(7, 0);
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
    for (var record in allRecords) {
      try {
        final recordDate = DateTime.parse(record.date).toLocal();
        if (recordDate.isAfter(startDate.subtract(const Duration(days: 1)))) {
          final dayIndex = recordDate.difference(startDate).inDays;
          if (dayIndex >= 0 && dayIndex < 7) {
            _weeklyData[dayIndex] += Duration(milliseconds: record.study_time);
            if (record.questions.containsKey('total') && record.questions['total'] is int) {
              _weeklyQuestionsData[dayIndex] += record.questions['total'] as int;
            }
          }
        }
      } catch (e) {
        // date parsing error already handled for daily average
      }
    }

    // Calculate Daily Subject Study Time
    _dailySubjectStudyTime = {};
    for (var record in allRecords) {
      try {
        final dateKey = DateTime.parse(record.date).toLocal().toIso8601String().split('T')[0];
        final subjectName = allSubjectsProvider.subjects.firstWhere((s) => s.id == record.subject_id, orElse: () => Subject(id: '', plan_id: '', subject: 'Desconhecido', color: '#808080', topics: [])).subject;
        _dailySubjectStudyTime.putIfAbsent(dateKey, () => {});
        _dailySubjectStudyTime[dateKey]!.update(subjectName, (value) => value + record.study_time, ifAbsent: () => record.study_time);
      } catch (e) {
        print('Error calculating daily subject study time: $e');
      }
    }

    // Populate Subject Colors
    _subjectColors = allSubjectsProvider.subjects;

    // Calculate Weekly Goals
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    _weeklyHours = Duration.zero;
    _weeklyQuestions = 0;

    for (var record in allRecords) {
      try {
        final recordDate = DateTime.parse(record.date).toLocal();
        if (recordDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) && recordDate.isBefore(endOfWeek.add(const Duration(days: 1)))) {
          _weeklyHours += Duration(milliseconds: record.study_time);
          if (record.questions.containsKey('total') && record.questions['total'] is int) {
            _weeklyQuestions += record.questions['total'] as int;
          }
        }
      } catch (e) {
        // ignore
      }
    }

    _goalHours = Duration(hours: int.tryParse(planningProvider.studyHours) ?? 0);
    _goalQuestions = int.tryParse(planningProvider.weeklyQuestionsGoal) ?? 0;

    setState(() {
      _isLoading = false;
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isLandscape = constraints.maxWidth > 600;
                      if (isLandscape) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: SummaryCard(
                              icon: MaterialCommunityIcons.clock_time_three_outline,
                              title: 'Tempo de Estudo',
                              value: _formatDuration(_totalStudyTime),
                              color: Colors.amber,
                              isLandscape: true,
                            )),
                            const SizedBox(width: 16),
                            Expanded(child: SummaryCard(
                              icon: MaterialCommunityIcons.calendar_today,
                              title: 'Média Diária',
                              value: _formatDuration(_dailyAverage),
                              color: Colors.amber,
                              isLandscape: true,
                            )),
                            const SizedBox(width: 16),
                            Expanded(child: SummaryCard(
                              icon: MaterialCommunityIcons.bullseye_arrow,
                              title: 'Desempenho',
                              value: '${_performance.toStringAsFixed(1)}%',
                              color: Colors.amber,
                              isLandscape: true,
                            )),
                            const SizedBox(width: 16),
                            Expanded(child: SummaryCard(
                              icon: MaterialCommunityIcons.file_document_outline,
                              title: 'Progresso Edital',
                              value: '${_progress.toStringAsFixed(1)}%',
                              color: Colors.amber,
                              isLandscape: true,
                            )),
                          ],
                        );
                      } else {
                        return GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.9, // Adjust card height
                          children: [
                            SummaryCard(
                              icon: MaterialCommunityIcons.clock_time_three_outline,
                              title: 'Tempo de Estudo',
                              value: _formatDuration(_totalStudyTime),
                              color: Colors.amber,
                            ),
                            SummaryCard(
                              icon: MaterialCommunityIcons.calendar_today,
                              title: 'Média Diária',
                              value: _formatDuration(_dailyAverage),
                              color: Colors.amber,
                            ),
                            SummaryCard(
                              icon: MaterialCommunityIcons.bullseye_arrow,
                              title: 'Desempenho',
                              value: '${_performance.toStringAsFixed(1)}%',
                              color: Colors.amber,
                            ),
                            SummaryCard(
                              icon: MaterialCommunityIcons.file_document_outline,
                              title: 'Progresso Edital',
                              value: '${_progress.toStringAsFixed(1)}%',
                              color: Colors.amber,
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Study Consistency Tracker
                  StudyConsistencyTracker(
                    studyStreak: _studyStreak,
                    daysData: _consistencyData,
                    startDate: _consistencyEndDate.subtract(const Duration(days: 29)),
                    endDate: _consistencyEndDate,
                    onPrev: () => _handleConsistencyNav(-1),
                    onNext: () => _handleConsistencyNav(1),
                  ),
                  const SizedBox(height: 24),

                  // Performance Panel and Goals
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 600) {
                                          return Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [                                                  Expanded(
                                                    flex: 3,
                                                    child: PerformancePanel(performanceData: _performanceData),
                                                  ),                            SizedBox(width: 24),
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
WeeklyStudyGoals(
                                    currentHours: _weeklyHours,
                                    goalHours: _goalHours,
                                    currentQuestions: _weeklyQuestions,
                                    goalQuestions: _goalQuestions,
                                  ),
                            SizedBox(height: 24),
                            WeeklyStudyChart(
                                    weeklyData: _weeklyData,
                                    weeklyQuestionsData: _weeklyQuestionsData,
                                    currentView: _chartView,
                                    onViewModeChanged: (view) {
                                      setState(() {
                                        _chartView = view;
                                      });
                                    },
                                  ),
                          ],
                              ),
                            ),
                          ],
                        );
                      } else {
                                          return Column(
                                            children: [
                                              PerformancePanel(performanceData: _performanceData),                            SizedBox(height: 24),
                            WeeklyStudyGoals(
                                    currentHours: _weeklyHours,
                                    goalHours: _goalHours,
                                    currentQuestions: _weeklyQuestions,
                                    goalQuestions: _goalQuestions,
                                  ),
                      SizedBox(height: 24),
                      WeeklyStudyChart(
                        weeklyData: _weeklyData,
                        weeklyQuestionsData: _weeklyQuestionsData,
                        currentView: _chartView,
                        onViewModeChanged: (view) {
                          setState(() {
                            _chartView = view;
                          });
                        },
                      ),
                    ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Additional Sections
                  const RevisionsSection(),
                  const SizedBox(height: 24),
                  const PlanningSection(),
                  const SizedBox(height: 24),
                  const LastActivitiesSection(),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DailyStudySection(dailySubjectStudyTime: _dailySubjectStudyTime, subjectColors: _subjectColors),
                      ),
                      const SizedBox(width: 24), // Spacing between sections
                      Expanded(
                        child: const RemindersSection(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool isLandscape;

  const SummaryCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.isLandscape = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isLandscape ? 8.0 : 12.0),
        child: Row(
          children: [
            Icon(icon, size: isLandscape ? 32 : 40, color: Colors.white),
            SizedBox(width: isLandscape ? 8 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.white, fontSize: isLandscape ? 14 : 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: isLandscape ? 20 : 24,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudyConsistencyTracker extends StatelessWidget {
  final int studyStreak;
  final List<Map<String, dynamic>> daysData;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const StudyConsistencyTracker({
    Key? key,
    required this.studyStreak,
    required this.daysData,
    required this.startDate,
    required this.endDate,
    required this.onPrev,
    required this.onNext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isNextDisabled = endDate.isAfter(DateTime.now()) || 
                           DateTime(endDate.year, endDate.month, endDate.day) == 
                           DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CONSTÂNCIA NOS ESTUDOS',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('Você está há $studyStreak dias sem falhar!'),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: onPrev,
                    ),
                    Text(
                      '${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: isNextDisabled ? null : onNext,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            StudyConsistencyGrid(daysData: daysData),
          ],
        ),
      ),
    );
  }
}

class PerformancePanel extends StatelessWidget {
  final List<PerformanceData> performanceData;

  const PerformancePanel({Key? key, required this.performanceData}) : super(key: key);

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
              'Painel de Desempenho',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            PerformanceTable(performanceData: performanceData),
          ],
        ),
      ),
    );
  }
}

class WeeklyStudyGoals extends StatelessWidget {
  final Duration currentHours;
  final Duration goalHours;
  final int currentQuestions;
  final int goalQuestions;

  const WeeklyStudyGoals({
    Key? key,
    required this.currentHours,
    required this.goalHours,
    required this.currentQuestions,
    required this.goalQuestions,
  }) : super(key: key);

  String _formatHours(Duration d) {
    if (d.inMilliseconds <= 0) return 'N/A';
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    return '${hours}h${minutes.toString().padLeft(2, '0')}min';
  }

  Color _getBarColor(double percentage) {
    if (percentage >= 100) return Colors.amber.shade500;
    if (percentage > 80) return Colors.amber.shade400;
    if (percentage > 40) return Colors.orange.shade400;
    return Colors.red.shade500;
  }

  @override
  Widget build(BuildContext context) {
    final hoursPercentage = goalHours.inMilliseconds > 0 ? (currentHours.inMilliseconds / goalHours.inMilliseconds) * 100 : 0.0;
    final questionsPercentage = goalQuestions > 0 ? (currentQuestions / goalQuestions) * 100 : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'METAS DE ESTUDO SEMANAL',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildGoalBar(
              title: 'Horas de Estudo',
              currentValue: _formatHours(currentHours),
              goalValue: _formatHours(goalHours),
              percentage: hoursPercentage,
              barColor: _getBarColor(hoursPercentage),
            ),
            const SizedBox(height: 16),
            _buildGoalBar(
              title: 'Questões',
              currentValue: currentQuestions.toString(),
              goalValue: goalQuestions > 0 ? goalQuestions.toString() : 'N/A',
              percentage: questionsPercentage,
              barColor: _getBarColor(questionsPercentage),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalBar({
    required String title,
    required String currentValue,
    required String goalValue,
    required double percentage,
    required Color barColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text('$currentValue / $goalValue', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey.shade300,
          color: barColor,
          minHeight: 12,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ),
      ],
    );
  }
}

class WeeklyStudyChart extends StatelessWidget {
  final List<Duration> weeklyData;
  final List<int> weeklyQuestionsData;
  final ChartView currentView;
  final ValueChanged<ChartView> onViewModeChanged;

  const WeeklyStudyChart({
    Key? key,
    required this.weeklyData,
    required this.weeklyQuestionsData,
    required this.currentView,
    required this.onViewModeChanged,
  }) : super(key: key);

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ESTUDO SEMANAL',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ToggleButtons(
                  isSelected: [
                    currentView == ChartView.time,
                    currentView == ChartView.questions,
                  ],
                  onPressed: (int index) {
                    if (index == 0) {
                      onViewModeChanged(ChartView.time);
                    } else {
                      onViewModeChanged(ChartView.questions);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  fillColor: Theme.of(context).primaryColor,
                  color: Theme.of(context).primaryColor,
                  borderColor: Theme.of(context).primaryColor,
                  selectedBorderColor: Theme.of(context).primaryColor,
                  children: const <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('TEMPO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('QUESTÕES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            WeeklyBarChart(
              weeklyData: weeklyData,
              weeklyQuestionsData: weeklyQuestionsData,
              currentView: currentView,
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder Widgets for other sections






