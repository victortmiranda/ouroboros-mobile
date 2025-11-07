import 'package:flutter/material.dart';
import 'package:ouroboros_mobile/models/simulado_record.dart';

import 'package:provider/provider.dart';
import 'package:ouroboros_mobile/providers/simulados_provider.dart';

import 'package:ouroboros_mobile/screens/simulados/add_edit_simulado_screen.dart';

class ListenableBuilder extends AnimatedWidget {
  final Listenable listenable;
  final Widget Function(BuildContext) builder;

  const ListenableBuilder({
    Key? key,
    required this.listenable,
    required this.builder,
  }) : super(key: key, listenable: listenable);

  @override
  Widget build(BuildContext context) {
    return builder(context);
  }
}

class SimuladoCard extends StatefulWidget {
  final SimuladoRecord simulado;

  const SimuladoCard({required this.simulado, super.key});

  @override
  State<SimuladoCard> createState() => _SimuladoCardState();
}

class _SimuladoCardState extends State<SimuladoCard> {
  bool _isExpanded = false;

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.yellow;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        onExpansionChanged: (isExpanded) {
          setState(() {
            _isExpanded = isExpanded;
          });
        },
        title: _buildHeader(context),
        trailing: _buildActions(context),
        children: [_buildDetails()],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.simulado.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    '${widget.simulado.date.day}/${widget.simulado.date.month}/${widget.simulado.date.year}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor,
              ),
              child: Center(
                child: Text(
                  '${widget.simulado.performance.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text('Tipo: ${widget.simulado.style}', style: TextStyle(color: Colors.grey[600])),
        Text('Tempo Gasto: ${widget.simulado.timeSpent}', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildResultItem(Icons.check_circle, widget.simulado.totalCorrect.toString(), Colors.green, 'Acertos'),
            _buildResultItem(Icons.cancel, widget.simulado.totalIncorrect.toString(), Colors.red, 'Erros'),
            _buildResultItem(Icons.remove_circle, widget.simulado.totalBlank.toString(), Colors.grey, 'Brancos'),
            _buildResultItem(Icons.star, widget.simulado.totalScore.toStringAsFixed(0), Colors.amber, 'Pontos'),
          ],
        ),
      ],
    );
  }

  Widget _buildResultItem(IconData icon, String value, Color color, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddEditSimuladoScreen(simulado: widget.simulado),
              ),
            );
          },
          tooltip: 'Editar',
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Confirmar Exclusão'),
                content: const Text('Tem certeza que deseja excluir este simulado?'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancelar'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('Excluir'),
                    onPressed: () {
                      Provider.of<SimuladosProvider>(context, listen: false).deleteSimulado(widget.simulado.id);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            );
          },
          tooltip: 'Excluir',
        ),
        Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
      ],
    );
  }

  Widget _buildDetails() {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final listenable = Listenable.merge(
      widget.simulado.subjects.expand((s) => [s.weight, s.totalQuestions, s.correct, s.incorrect]).toList(),
    );

    return ListenableBuilder(
      listenable: listenable,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Detalhes por Disciplina', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DataTable(
                columnSpacing: 12.0,
                dataRowHeight: 60.0,
                columns: const [
                  DataColumn(label: Text('Disciplina', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Peso', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('✓', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('X', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('B', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('∑', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('%', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: [
                  ...widget.simulado.subjects.map((subject) {
                    final double subjectPerformance = subject.totalQuestions.value > 0 ? (subject.correct.value / subject.totalQuestions.value) * 100 : 0.0;
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40, // Altura da linha de cor
                                color: Color(int.parse(subject.color.substring(1, 7), radix: 16) + 0xFF000000),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  subject.name,
                                  softWrap: !isLandscape, // Quebra de linha apenas em portrait
                                  maxLines: !isLandscape ? 2 : 1, // Duas linhas em portrait, 1 em landscape
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.start,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(subject.weight.value.toString())),
                        DataCell(Text(subject.correct.value.toString(), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                        DataCell(Text(subject.incorrect.value.toString(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                        DataCell(Text((subject.totalQuestions.value - subject.correct.value - subject.incorrect.value).toString(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                        DataCell(Text(subject.totalQuestions.value.toString())),
                        DataCell(
                          Row(
                            children: [
                              SizedBox(
                                width: 50, // Largura da barra de progresso
                                child: LinearProgressIndicator(
                                  value: subjectPerformance / 100,
                                  backgroundColor: Colors.grey[300],
                                  color: _getPerformanceColor(subjectPerformance),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${subjectPerformance.toStringAsFixed(0)}%'),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                  // Linha de Totais
                  DataRow(
                    cells: [
                      const DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                      const DataCell(Text('-')),
                      DataCell(Text(widget.simulado.totalCorrect.toString(), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                      DataCell(Text(widget.simulado.totalIncorrect.toString(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                      DataCell(Text(widget.simulado.totalBlank.toString(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                      DataCell(Text(widget.simulado.totalQuestions.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(
                        Row(
                          children: [
                            SizedBox(
                              width: 50,
                              child: LinearProgressIndicator(
                                value: widget.simulado.performance / 100,
                                backgroundColor: Colors.grey[300],
                                color: _getPerformanceColor(widget.simulado.performance),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${widget.simulado.performance.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}