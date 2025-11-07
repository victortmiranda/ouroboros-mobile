import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ouroboros_mobile/providers/planning_provider.dart';
import 'package:ouroboros_mobile/widgets/cycle_creation_modal.dart';
import 'package:ouroboros_mobile/models/data_models.dart';
import 'package:ouroboros_mobile/widgets/donut_chart.dart';
import 'package:ouroboros_mobile/widgets/study_session_list.dart';
import 'package:ouroboros_mobile/widgets/study_register_modal.dart';
import 'package:ouroboros_mobile/widgets/stopwatch_modal.dart';
import 'package:ouroboros_mobile/providers/history_provider.dart';
import 'package:ouroboros_mobile/providers/all_subjects_provider.dart';
import 'package:ouroboros_mobile/providers/active_plan_provider.dart';
import 'package:ouroboros_mobile/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

class PlanningScreen extends StatefulWidget {
  final bool isEditMode;
  final VoidCallback onToggleEditMode;
  final VoidCallback onResetCycle;

  const PlanningScreen({super.key, required this.isEditMode, required this.onToggleEditMode, required this.onResetCycle});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  Subject? _subjectToAdd;
  final TextEditingController _durationToAddController = TextEditingController();

  void _onStartStudy(BuildContext context, StudySession session) async { // Make async
    final activePlanProvider = Provider.of<ActivePlanProvider>(context, listen: false);
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
    final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
    final planId = activePlanProvider.activePlan?.id;

    if (planId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum plano de estudo ativo selecionado.')),
      );
      return;
    }

    // Await the result from the StopwatchModal
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) => StopwatchModal(
        planId: planId,
        initialSubjectId: session.subjectId,
        initialTopic: session.subject,
        initialDurationMinutes: session.duration,
        // The onSaveAndClose will now just pop with a value
        onSaveAndClose: (time, subjectId, topic) {
          Navigator.of(ctx).pop({
            'time': time,
            'subjectId': subjectId,
            'topic': topic,
          });
        },
      ),
    );

    // Handle the result after the dialog is closed
    if (result != null) {
      final int time = result['time'];
      final String? subjectId = result['subjectId'];
      final Topic? topic = result['topic'];

      if (subjectId != null && topic != null) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final newRecord = StudyRecord(
          id: Uuid().v4(),
          userId: authProvider.currentUser!.name,
          plan_id: activePlanProvider.activePlan!.id,
          date: DateTime.now().toIso8601String(),
          subject_id: subjectId,
          topic: topic.topic_text,
          study_time: 0,
          category: 'teoria',
          questions: {},
          review_periods: [],
          teoria_finalizada: false,
          count_in_planning: true,
          pages: [],
          videos: [],
        );

        // Use the PlanningScreen's context to show the next modal
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (modalCtx) => StudyRegisterModal(
            planId: newRecord.plan_id,
            initialRecord: newRecord,
            onSave: (record) {
              historyProvider.addStudyRecord(record);
              if (record.count_in_planning) {
                planningProvider.updateProgress(record);
              }
            },
          ),
        );
      }
    }
  }

  void _onRegisterStudy(BuildContext context, StudySession session) {
    final activePlanProvider = Provider.of<ActivePlanProvider>(context, listen: false);
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
    final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final planId = activePlanProvider.activePlan?.id;

    if (planId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum plano de estudo ativo selecionado.')),
      );
      return;
    }

    final newRecord = StudyRecord(
      id: const Uuid().v4(),
      userId: authProvider.currentUser!.name,
      plan_id: planId,
      date: DateTime.now().toIso8601String().split('T')[0],
      study_time: session.duration * 60 * 1000, // Convert minutes to milliseconds
      subject_id: session.subjectId,
      topic: session.subject,
      category: 'teoria',
      questions: {},
      review_periods: [],
      teoria_finalizada: false,
      count_in_planning: true,
      pages: [],
      videos: [],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StudyRegisterModal(
        planId: newRecord.plan_id,
        initialRecord: newRecord,
        onSave: (record) {
          historyProvider.addStudyRecord(record);
          if (record.count_in_planning) {
            planningProvider.updateProgress(record);
          }
        },
      ),
    );
  }

  void _onDeleteSession(String sessionId) {
    final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
    final updatedCycle = planningProvider.studyCycle!.where((session) => session.id != sessionId).toList();
    planningProvider.setStudyCycle(updatedCycle);
  }

  void _onDuplicateSession(StudySession session) {
    final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
    final newSession = StudySession(
      id: DateTime.now().toIso8601String(),
      subject: session.subject,
      subjectId: session.subjectId,
      duration: session.duration,
      color: session.color,
    );
    final updatedCycle = List<StudySession>.from(planningProvider.studyCycle!)..add(newSession);
    planningProvider.setStudyCycle(updatedCycle);
  }

  void _onReorderSessions(int oldIndex, int newIndex) {
    final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
    final reorderedCycle = List<StudySession>.from(planningProvider.studyCycle!);    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = reorderedCycle.removeAt(oldIndex);
    reorderedCycle.insert(newIndex, item);
    planningProvider.setStudyCycle(reorderedCycle);
  }

  @override
  void dispose() {
    _durationToAddController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlanningProvider, ActivePlanProvider>(
      builder: (context, planningProvider, activePlanProvider, child) {
        if (activePlanProvider.activePlanId == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Selecione um plano de estudos para visualizar o planejamento.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          body: planningProvider.studyCycle == null
              ? _buildWelcomeScreen(context, planningProvider)
              : _buildPlanningDashboard(context, planningProvider),
        );
      },
    );
  }

  Widget _buildWelcomeScreen(BuildContext context, PlanningProvider planningProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bem-vindo ao Planejamento!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Crie e gerencie seus ciclos de estudos personalizados. Comece definindo suas matérias, horários e metas.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const CycleCreationModal(),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Começar Novo Ciclo de Estudos'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}min';
  }

  Widget _buildPlanningDashboard(BuildContext context, PlanningProvider planningProvider) {
    final totalCycleDuration = planningProvider.studyCycle!.fold<int>(0, (sum, session) => sum + session.duration);

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Text('Ciclos Completos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text(planningProvider.completedCycles.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Progresso da Semana', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 10),
                                  LinearProgressIndicator(
                                    value: totalCycleDuration == 0 ? 0 : planningProvider.currentProgressMinutes / totalCycleDuration,
                                    minHeight: 10,
                                  ),
                                  const SizedBox(height: 10),
                                  Text('${_formatDuration(planningProvider.currentProgressMinutes)} / ${_formatDuration(totalCycleDuration)}'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DonutChart(
                      cycle: planningProvider.studyCycle!,
                      studyHours: planningProvider.studyHours,
                      sessionProgressMap: planningProvider.sessionProgressMap,
                    ),
                    const SizedBox(height: 20),
                    if (widget.isEditMode)
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Adicionar Nova Sessão', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Consumer<AllSubjectsProvider>(
                              builder: (context, allSubjectsProvider, child) {
                                return DropdownButtonFormField<Subject>(
                                  isExpanded: true,
                                  value: _subjectToAdd,
                                  hint: const Text('Selecione uma matéria'),
                                  onChanged: (Subject? newValue) {
                                    setState(() {
                                      _subjectToAdd = newValue;
                                    });
                                  },
                                  items: allSubjectsProvider.uniqueSubjectsByName.map<DropdownMenuItem<Subject>>((subject) {
                                    return DropdownMenuItem<Subject>(
                                      value: subject,
                                      child: Text(subject.subject, overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _durationToAddController,
                              decoration: const InputDecoration(
                                labelText: 'Duração (min)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                if (_subjectToAdd != null && _durationToAddController.text.isNotEmpty) {
                                  final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
                                  final newSession = StudySession(
                                    id: DateTime.now().toIso8601String(),
                                    subject: _subjectToAdd!.subject,
                                    subjectId: _subjectToAdd!.id,
                                    duration: int.parse(_durationToAddController.text),
                                    color: _subjectToAdd!.color,
                                  );
                                  final updatedCycle = List<StudySession>.from(planningProvider.studyCycle!)..add(newSession);
                                  planningProvider.setStudyCycle(updatedCycle);
                                  setState(() {
                                    _subjectToAdd = null;
                                    _durationToAddController.clear();
                                  });
                                }
                              },
                              child: const Text('Adicionar Sessão'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverAppBar(
              pinned: true,
              floating: true,
              automaticallyImplyLeading: false, // Remove back button from SliverAppBar
              title: const TabBar(
                tabs: [
                  Tab(text: 'Sequência de Estudos'),
                  Tab(text: 'Estudos Concluídos'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          children: [
            // Tab 1: Sequência de Estudos (Pending Sessions)
            Consumer<ActivePlanProvider>(
              builder: (context, activePlanProvider, child) {
                final pendingSessions = planningProvider.studyCycle!.where((s) => (planningProvider.sessionProgressMap[s.id] ?? 0) < s.duration).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Sequência de Estudos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: StudySessionList(
                        cycle: pendingSessions,
                        planId: activePlanProvider.activePlan?.id ?? '',
                        onStartStudy: (session) => _onStartStudy(context, session),
                        onRegisterStudy: (session) => _onRegisterStudy(context, session),
                        isEditMode: widget.isEditMode,
                        onDeleteSession: _onDeleteSession,
                        onDuplicateSession: _onDuplicateSession,
                        onReorder: _onReorderSessions,
                        emptyListMessage: 'Nenhuma sessão pendente.',
                        sessionProgressMap: planningProvider.sessionProgressMap,
                      ),
                    ),
                  ],
                );
              },
            ),
            // Tab 2: Estudos Concluídos (Completed Sessions)
            Consumer<ActivePlanProvider>(
              builder: (context, activePlanProvider, child) {
                final completedSessions = planningProvider.studyCycle!.where((s) => (planningProvider.sessionProgressMap[s.id] ?? 0) >= s.duration).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Estudos Concluídos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: StudySessionList(
                        cycle: completedSessions,
                        planId: activePlanProvider.activePlan?.id ?? '',
                        isEditMode: widget.isEditMode,
                        onDeleteSession: _onDeleteSession,
                        onDuplicateSession: _onDuplicateSession,
                        onReorder: _onReorderSessions,
                        emptyListMessage: 'Nenhuma sessão concluída ainda.',
                        sessionProgressMap: planningProvider.sessionProgressMap,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}