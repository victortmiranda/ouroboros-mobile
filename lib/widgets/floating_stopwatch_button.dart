import 'package:flutter/material.dart';
import 'package:ouroboros_mobile/widgets/stopwatch_modal.dart';
import 'package:ouroboros_mobile/models/data_models.dart';
import 'package:provider/provider.dart';
import 'package:ouroboros_mobile/providers/history_provider.dart';
import 'package:ouroboros_mobile/providers/active_plan_provider.dart';
import 'package:ouroboros_mobile/providers/planning_provider.dart';
import 'package:ouroboros_mobile/providers/review_provider.dart';
import 'package:ouroboros_mobile/providers/all_subjects_provider.dart';
import 'package:ouroboros_mobile/widgets/study_register_modal.dart';

import 'package:ouroboros_mobile/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

class FloatingStopwatchButton extends StatefulWidget {
  const FloatingStopwatchButton({super.key});

  @override
  State<FloatingStopwatchButton> createState() => _FloatingStopwatchButtonState();
}

class _FloatingStopwatchButtonState extends State<FloatingStopwatchButton> {
  Offset? _position;

  void _handleStudyRecordSave(StudyRecord record) {
    Provider.of<HistoryProvider>(context, listen: false).addStudyRecord(record);
    if (record.count_in_planning) {
      Provider.of<PlanningProvider>(context, listen: false).updateProgress(record);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    if (_position == null) {
      _position = Offset(screenSize.width - 80.0, screenSize.height - 160.0);
    }

    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: Draggable(
        feedback: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.timer),
        ),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() {
            double x = details.offset.dx;
            double y = details.offset.dy;

            // Clamp the position to the screen boundaries
            x = x.clamp(0.0, screenSize.width - 80.0);
            y = y.clamp(0.0, screenSize.height - 160.0);

            _position = Offset(x, y);
          });
        },
        child: Consumer<ActivePlanProvider>(
          builder: (context, activePlanProvider, child) {
            return FloatingActionButton(
              onPressed: () {
                final planId = activePlanProvider.activePlan?.id;

                if (planId != null) {
                  showDialog(
                    context: context,
                    builder: (context) => StopwatchModal(
                      planId: planId,
                      onSaveAndClose: (int time, String? subjectId, Topic? topic) {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final initialRecord = StudyRecord(
                          id: Uuid().v4(),
                          userId: authProvider.currentUser!.name,
                          plan_id: activePlanProvider.activePlan!.id,
                          date: DateTime.now().toIso8601String(),
                          subject_id: subjectId!,
                          topic: topic?.topic_text ?? '',
                          study_time: 0,
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
                            planId: planId,
                            initialRecord: initialRecord,
                            onSave: _handleStudyRecordSave,
                          ),
                        );
                      },
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nenhum plano de estudo ativo selecionado.')),
                  );
                }
              },
              child: const Icon(Icons.timer),
            );
          },
        ),
      ),
    );
  }
}
