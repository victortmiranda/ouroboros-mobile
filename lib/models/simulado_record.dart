import 'package:flutter/material.dart';

// --- Data Models ---
class SimuladoSubject {
  String name;
  ValueNotifier<num> weight;
  ValueNotifier<int> totalQuestions;
  ValueNotifier<int> correct;
  ValueNotifier<int> incorrect;
  String color;

  SimuladoSubject({
    required this.name,
    num weight = 1,
    required int totalQuestions,
    required int correct,
    required int incorrect,
    this.color = '#000000',
  }) : this.weight = ValueNotifier(weight),
       this.totalQuestions = ValueNotifier(totalQuestions),
       this.correct = ValueNotifier(correct),
       this.incorrect = ValueNotifier(incorrect);
}

class SimuladoRecord {
  final String id;
  final String name;
  final DateTime date;
  final String style;
  final String banca;
  final String timeSpent;
  final String comments;
  final List<SimuladoSubject> subjects;

  SimuladoRecord({
    required this.id,
    required this.name,
    required this.date,
    required this.style,
    required this.banca,
    required this.timeSpent,
    this.comments = '',
    required this.subjects,
  });

  int get totalCorrect => subjects.fold(0, (sum, s) => sum + s.correct.value);
  int get totalIncorrect => subjects.fold(0, (sum, s) => sum + s.incorrect.value);
  int get totalQuestions => subjects.fold(0, (sum, s) => sum + s.totalQuestions.value);
  int get totalBlank => totalQuestions - totalCorrect - totalIncorrect;
  double get performance => totalQuestions > 0 ? (totalCorrect / totalQuestions) * 100 : 0.0;
  
  double get totalScore {
    return subjects.fold(0.0, (sum, sub) {
      if (style == 'Certo/Errado') {
        return sum + (sub.correct.value - sub.incorrect.value);
      } else {
        return sum + (sub.correct.value * sub.weight.value);
      }
    });
  }
}