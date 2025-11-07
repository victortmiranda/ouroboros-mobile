import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:ouroboros_mobile/providers/all_subjects_provider.dart';
import 'package:ouroboros_mobile/models/data_models.dart';
import 'package:ouroboros_mobile/providers/history_provider.dart';
import 'package:ouroboros_mobile/providers/planning_provider.dart';
import 'package:ouroboros_mobile/providers/review_provider.dart';
import 'package:ouroboros_mobile/widgets/number_picker_wheel.dart';
import 'package:ouroboros_mobile/widgets/study_register_modal.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

class StopwatchModal extends StatefulWidget {
  final String planId;
  final Function(int time, String? subjectId, Topic? topic) onSaveAndClose;
  final String? initialSubjectId;
  final String? initialTopic;
  final int? initialDurationMinutes;

  const StopwatchModal({
    super.key,
    required this.planId,
    required this.onSaveAndClose,
    this.initialSubjectId,
    this.initialTopic,
    this.initialDurationMinutes,
  });

  @override
  State<StopwatchModal> createState() => _StopwatchModalState();
}

class _StopwatchModalState extends State<StopwatchModal> with SingleTickerProviderStateMixin {
  bool _isTimerMode = false;
  final Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  String _result = '00:00:00';
  Duration _timerDuration = const Duration();
  final TextEditingController _timerController = TextEditingController();
  String? _selectedSubjectId;
  Topic? _selectedTopic;

  late AnimationController _barberPoleController;
  late Animation<double> _barberPoleAnimation;

  void _handleGetRecommendation() {
    final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
    final allSubjectsProvider = Provider.of<AllSubjectsProvider>(context, listen: false);

    final recommendation = planningProvider.getRecommendedSession(
      studyRecords: historyProvider.allStudyRecords,
      subjects: allSubjectsProvider.subjects,
      reviewRecords: Provider.of<ReviewProvider>(context, listen: false).allReviewRecords,
    );

    final recommendedTopic = recommendation['recommendedTopic'] as Topic?;
    final nextSession = recommendation['nextSession'] as StudySession?;

    if (nextSession != null) {
      setState(() {
        _selectedSubjectId = nextSession.subjectId;
        _selectedTopic = recommendedTopic;
        _isTimerMode = true;
        _timerDuration = Duration(minutes: nextSession.duration);
        _result = _formatTime(_timerDuration.inMilliseconds);
        _stopwatch.reset();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(recommendation['justification'] ?? 'Não há mais sessões no ciclo.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.initialSubjectId;

    if (widget.initialDurationMinutes != null) {
      _timerDuration = Duration(minutes: widget.initialDurationMinutes!);
      _isTimerMode = true;
    }

    if (widget.initialSubjectId != null && widget.initialTopic != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final allSubjectsProvider = Provider.of<AllSubjectsProvider>(context, listen: false);
        if (allSubjectsProvider.subjects.isNotEmpty) {
          final subject = allSubjectsProvider.subjects.firstWhere((s) => s.id == widget.initialSubjectId);
          setState(() {
            _selectedTopic = _findTopicByText(subject.topics, widget.initialTopic!);
          });
        }
      });
    }

    _barberPoleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _barberPoleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_barberPoleController);

    _timer = Timer.periodic(const Duration(milliseconds: 30), (Timer t) {
      setState(() {
        if (_isTimerMode) {
          final remaining = _timerDuration - _stopwatch.elapsed;
          if (remaining.isNegative) {
            _stopwatch.stop();
            _result = '00:00:00';
          } else {
            _result = 
                '${remaining.inHours.toString().padLeft(2, '0')}:'
                '${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:'
                '${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
          }
        } else {
          _result = 
              '${_stopwatch.elapsed.inHours.toString().padLeft(2, '0')}:'
              '${(_stopwatch.elapsed.inMinutes % 60).toString().padLeft(2, '0')}:'
              '${(_stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
        }
      });
    });
  }

  Topic? _findTopicByText(List<Topic> topics, String text) {
    for (var topic in topics) {
      if (topic.topic_text == text) {
        return topic;
      }
      if (topic.sub_topics != null) {
        final found = _findTopicByText(topic.sub_topics!, text);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }

  @override
  void dispose() {
    _timer.cancel();
    _stopwatch.stop();
    _timerController.dispose();
    _barberPoleController.dispose();
    super.dispose();
  }

  void _start() {
    if (!_stopwatch.isRunning) {
      if (_isTimerMode) {
        if (_stopwatch.elapsed.inMilliseconds == 0) {
          _stopwatch.reset();
        }
      }
      _stopwatch.start();
    }
  }

  void _stop() {
    _stopwatch.stop();
  }

  void _reset() {
    _stopwatch.stop();
    _stopwatch.reset();
    setState(() {
      if (_isTimerMode) {
        _timerDuration = Duration(minutes: widget.initialDurationMinutes ?? 0);
        _result = _formatTime(_timerDuration.inMilliseconds);
      } else {
        _result = '00:00:00';
      }
    });
  }

  List<DropdownMenuItem<Topic>> _buildTopicDropdownItems(List<Topic> topics, {int level = 0}) {
    List<DropdownMenuItem<Topic>> items = [];
    for (var topic in topics) {
      final isGroupingTopic = topic.sub_topics != null && topic.sub_topics!.isNotEmpty;
      items.add(DropdownMenuItem<Topic>(
        value: topic,
        enabled: !isGroupingTopic,
        child: Padding(
          padding: EdgeInsets.only(left: level * 16.0),
          child: Text(
            topic.topic_text,
            style: TextStyle(
              fontWeight: isGroupingTopic ? FontWeight.bold : FontWeight.normal,
              color: isGroupingTopic ? Colors.grey : null,
            ),
          ),
        ),
      ));
      if (isGroupingTopic) {
        items.addAll(_buildTopicDropdownItems(topic.sub_topics!, level: level + 1));
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final allSubjectsProvider = Provider.of<AllSubjectsProvider>(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 5,
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedSubjectId,
                        hint: const Text('Matéria'),
                        onChanged: (value) {
                          setState(() {
                            _selectedSubjectId = value;
                            _selectedTopic = null;
                          });
                        },
                        items: allSubjectsProvider.subjects.map((subject) {
                          return DropdownMenuItem(value: subject.id, child: Text(subject.subject, overflow: TextOverflow.ellipsis));
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    SizedBox(
                      width: 180,
                      child: DropdownButton<Topic>(
                        isExpanded: true,
                        value: _selectedTopic,
                        hint: const Text('Tópico'),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedTopic = value;
                            });
                          }
                        },
                        items: _selectedSubjectId != null
                            ? _buildTopicDropdownItems(
                                allSubjectsProvider.subjects
                                    .firstWhereOrNull((s) => s.id == _selectedSubjectId)?.topics ?? [])
                            : [],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedSubjectId != null
                            ? allSubjectsProvider.subjects.firstWhereOrNull((s) => s.id == _selectedSubjectId)?.subject ?? 'Sessão de Estudo'
                            : 'Sessão de Estudo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _isTimerMode ? _formatProgressText(_timerDuration.inMilliseconds - _stopwatch.elapsed.inMilliseconds, _timerDuration.inMilliseconds) : '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Container(
                  height: 24.0,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: _isTimerMode
                        ? LinearProgressIndicator(
                            value: _timerDuration.inMilliseconds > 0
                                ? (_timerDuration.inMilliseconds - _stopwatch.elapsed.inMilliseconds) / _timerDuration.inMilliseconds
                                : 0,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                            backgroundColor: Colors.transparent,
                          )
                        : AnimatedBuilder(
                            animation: _barberPoleAnimation,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: BarberPolePainter(animationValue: _barberPoleAnimation.value, isRunning: _stopwatch.isRunning),
                                child: Container(),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 24.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_isTimerMode && !_stopwatch.isRunning)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: NumberPickerWheel(
                                minValue: 0,
                                maxValue: 23,
                                initialValue: _timerDuration.inHours,
                                onChanged: (value) {
                                  setState(() {
                                    _timerDuration = Duration(
                                        hours: value,
                                        minutes: _timerDuration.inMinutes % 60,
                                        seconds: _timerDuration.inSeconds % 60);
                                    _result = _formatTime(_timerDuration.inMilliseconds);
                                  });
                                },
                                textStyle: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                                itemExtent: 60.0,
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              ),
                            ),
                            const Text(':', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                            Expanded(
                              child: NumberPickerWheel(
                                minValue: 0,
                                maxValue: 59,
                                initialValue: _timerDuration.inMinutes % 60,
                                onChanged: (value) {
                                  setState(() {
                                    _timerDuration = Duration(
                                        hours: _timerDuration.inHours,
                                        minutes: value,
                                        seconds: _timerDuration.inSeconds % 60);
                                    _result = _formatTime(_timerDuration.inMilliseconds);
                                  });
                                },
                                textStyle: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                                itemExtent: 60.0,
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              ),
                            ),
                            const Text(':', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                            Expanded(
                              child: NumberPickerWheel(
                                minValue: 0,
                                maxValue: 59,
                                initialValue: _timerDuration.inSeconds % 60,
                                onChanged: (value) {
                                  setState(() {
                                    _timerDuration = Duration(
                                        hours: _timerDuration.inHours,
                                        minutes: _timerDuration.inMinutes % 60,
                                        seconds: value);
                                    _result = _formatTime(_timerDuration.inMilliseconds);
                                  });
                                },
                                textStyle: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                                itemExtent: 60.0,
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Expanded(
                        child: Text(
                          _result,
                          style: const TextStyle(fontSize: 48, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(width: 16.0),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isTimerMode = false;
                              _stopwatch.reset();
                              _result = '00:00:00';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !_isTimerMode ? const Color(0xFFF59E0B) : Colors.grey[300],
                            foregroundColor: !_isTimerMode ? Colors.white : Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('CRONÔMETRO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8.0),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isTimerMode = true;
                              _stopwatch.reset();
                              _timerDuration = Duration(
                                  hours: _timerDuration.inHours,
                                  minutes: _timerDuration.inMinutes % 60,
                                  seconds: _timerDuration.inSeconds % 60);
                              _result = _formatTime(_timerDuration.inMilliseconds);
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isTimerMode ? const Color(0xFFF59E0B) : Colors.grey[300],
                            foregroundColor: _isTimerMode ? Colors.white : Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('TIMER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16.0),
                    SizedBox(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FloatingActionButton(
                            onPressed: _handleGetRecommendation,
                            tooltip: 'Sugerir Próximo Estudo',
                            child: const Icon(Icons.lightbulb_outline),
                          ),
                          const SizedBox(height: 8.0),
                          const Text('Sugestão', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 64.0,
                      icon: Icon(_stopwatch.isRunning ? Icons.pause_circle_filled : Icons.play_circle_filled),
                      color: const Color(0xFFF59E0B),
                      onPressed: _stopwatch.isRunning ? _stop : _start,
                    ),
                    const SizedBox(width: 24.0),
                    if (_stopwatch.elapsed.inMilliseconds > 0)
                      IconButton(
                        iconSize: 64.0,
                        icon: const Icon(Icons.refresh),
                        color: const Color(0xFFF3C363),
                        onPressed: _reset,
                      ),
                    const SizedBox(width: 24.0),
                                        IconButton(
                                          iconSize: 64.0,
                                                                icon: const Icon(Icons.save),
                                                                color: const Color(0xFFF59E0B),                                          onPressed: () {
                                            if (_selectedSubjectId == null || _selectedTopic == null) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Por favor, selecione uma matéria e um tópico.')),
                                              );
                                              return;
                                            }
                    
                                            widget.onSaveAndClose(
                                              _stopwatch.elapsed.inMilliseconds,
                                              _selectedSubjectId,
                                              _selectedTopic,
                                            );
                                          },
                                        ),                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 8.0,
            right: 8.0,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int milliseconds) {
    final totalSeconds = (milliseconds / 1000).floor();
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatProgressText(int currentMs, int initialTargetMs) {
    final currentMinutes = (currentMs / (1000 * 60)).floor();
    final currentHours = (currentMinutes ~/ 60).toString().padLeft(2, '0');
    final remainingMinutes = (currentMinutes % 60).toString().padLeft(2, '0');

    final targetMinutes = (initialTargetMs / (1000 * 60)).floor();
    final targetHours = (targetMinutes ~/ 60).toString().padLeft(2, '0');
    final targetMins = (targetMinutes % 60).toString().padLeft(2, '0');

    return '${currentHours}h${remainingMinutes} / ${targetHours}h${targetMins}';
  }
}

class BarberPolePainter extends CustomPainter {
  final double animationValue;
  final bool isRunning;

  BarberPolePainter({required this.animationValue, required this.isRunning});

  @override
  void paint(Canvas canvas, Size size) {
    final List<Color> colors = [
      const Color(0xFFF6D86B),
      const Color(0xFFF3C363),
      const Color(0xFFF1E9BB),
    ];
    final double singleStripeWidth = 20.0;
    final double totalPatternWidth = singleStripeWidth * colors.length;
    final double diagonalLength = size.height + size.width;
    final double offset = isRunning ? animationValue * totalPatternWidth : 0;

    for (int colorIndex = 0; colorIndex < colors.length; colorIndex++) {
      final Paint paint = Paint()
        ..color = colors[colorIndex]
        ..style = PaintingStyle.fill;

      for (double i = -diagonalLength; i < diagonalLength; i += totalPatternWidth) {
        final double startX = i + (singleStripeWidth * colorIndex) + offset;
        final double endX = startX + singleStripeWidth;

        canvas.drawPath(
          Path()
            ..moveTo(startX, 0)
            ..lineTo(endX, 0)
            ..lineTo(endX + size.height / 2, size.height)
            ..lineTo(startX + size.height / 2, size.height)
            ..close(),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant BarberPolePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.isRunning != isRunning;
  }
}
