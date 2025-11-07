import 'package:flutter/material.dart';
import 'package:ouroboros_mobile/models/simulado_record.dart';
import 'dart:collection';

class SimuladosProvider extends ChangeNotifier {
  final List<SimuladoRecord> _simulados = [];

  UnmodifiableListView<SimuladoRecord> get simulados => UnmodifiableListView(_simulados);

  void addSimulado(SimuladoRecord simulado) {
    _simulados.add(simulado);
    notifyListeners();
  }

  void updateSimulado(SimuladoRecord simulado) {
    final index = _simulados.indexWhere((s) => s.id == simulado.id);
    if (index != -1) {
      _simulados[index] = simulado;
      notifyListeners();
    }
  }

  void deleteSimulado(String id) {
    _simulados.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}