import 'package:flutter/material.dart';
import 'package:ouroboros_mobile/models/data_models.dart';
import 'package:provider/provider.dart';
import 'package:ouroboros_mobile/providers/all_subjects_provider.dart';
import 'package:ouroboros_mobile/providers/history_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:ouroboros_mobile/widgets/study_register_modal.dart';
import 'package:uuid/uuid.dart';

class SubjectDetailScreen extends StatefulWidget {
  final Subject subject;

  const SubjectDetailScreen({super.key, required this.subject});

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  bool _allTopicsExpanded = true;
  int _chartPeriodIndex = 2; // 0: daily, 1: weekly, 2: monthly

  void _openStudyRegisterModal({StudyRecord? record, Topic? topic}) {
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StudyRegisterModal(
        planId: widget.subject.plan_id,
        initialRecord: record,
        topic: topic,
        onSave: (newRecord) {
          historyProvider.addStudyRecord(newRecord);
        },
        onUpdate: (updatedRecord) {
          historyProvider.updateStudyRecord(updatedRecord);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSubjectsProvider = Provider.of<AllSubjectsProvider>(context);
    final historyProvider = Provider.of<HistoryProvider>(context);

    final studyHours = allSubjectsProvider.getStudyHoursForSubject(widget.subject.id);
    final performance = allSubjectsProvider.getPerformanceForSubject(widget.subject.id);

    final totalTopics = _countTopics(widget.subject.topics);
    final studiedTopics = _countStudiedTopics(widget.subject.topics, historyProvider.allStudyRecords);
    final progress = totalTopics > 0 ? (studiedTopics / totalTopics * 100).toStringAsFixed(0) : '0';

    final pagesRead = historyProvider.allStudyRecords
        .where((record) => record.subject_id == widget.subject.id)
        .fold<int>(0, (sum, record) => sum + (record.pages.isNotEmpty ? record.pages.fold<int>(0, (pSum, p) => pSum + ((p['end'] as int) - (p['start'] as int) + 1)) : 0));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.subject),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          // Header: Subject Name and Add Button
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.subject.subject,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar Estudo'),
                  onPressed: () => _openStudyRegisterModal(),
                ),
              ],
            ),
          ),

          // Four Summary Sections
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.2, // Adjust as needed
            children: <Widget>[
              _buildSummaryCard(context, 'Tempo de Estudo', studyHours),
              _buildSummaryCard(context, 'Desempenho', '$performance%'),
              _buildSummaryCard(context, 'Progresso no Edital', '$progress%'),
              _buildSummaryCard(context, 'Páginas Lidas', pagesRead.toString()),
            ],
          ),

          const SizedBox(height: 24.0),

          // Edital Verticalizado (Topics)
          Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edital Verticalizado',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(_allTopicsExpanded ? Icons.unfold_less : Icons.unfold_more),
                        onPressed: () {
                          setState(() {
                            _allTopicsExpanded = !_allTopicsExpanded;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  // Display topics
                  if (widget.subject.topics.isEmpty)
                    const Text('Nenhum tópico cadastrado para esta disciplina.')
                  else
                    ..._buildTopicList(widget.subject.topics, 0, historyProvider.allStudyRecords),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24.0),

          // Histórico de Registros
          Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Histórico de Registros',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  _buildStudyHistoryTable(context, historyProvider.allStudyRecords.where((r) => r.subject_id == widget.subject.id).toList()),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24.0),

          // Evolução no Tempo
          Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Evolução no Tempo',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  _buildChart(context, historyProvider.allStudyRecords.where((r) => r.subject_id == widget.subject.id).toList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _countTopics(List<Topic> topics) {
    int count = 0;
    for (final topic in topics) {
      count++;
      if (topic.sub_topics != null) {
        count += _countTopics(topic.sub_topics!);
      }
    }
    return count;
  }

  int _countStudiedTopics(List<Topic> topics, List<StudyRecord> records) {
    int count = 0;
    final studiedTopicTexts = records.map((r) => r.topic).toSet();
    for (final topic in topics) {
      if (studiedTopicTexts.contains(topic.topic_text)) {
        count++;
      }
      if (topic.sub_topics != null) {
        count += _countStudiedTopics(topic.sub_topics!, records);
      }
    }
    return count;
  }

  List<Widget> _buildTopicList(List<Topic> topics, int depth, List<StudyRecord> records) {
    List<Widget> topicWidgets = [];
    for (var topic in topics) {
      topicWidgets.add(
        TopicListItem(
          topic: topic,
          depth: depth,
          isInitiallyExpanded: _allTopicsExpanded,
          studiedTopicTexts: records.map((r) => r.topic).toSet(),
          onAdd: () => _openStudyRegisterModal(topic: topic),
        ),
      );
    }
    return topicWidgets;
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4.0),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int milliseconds) {
    if (milliseconds < 0) return '0h 0m';
    final totalSeconds = milliseconds / 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  Widget _buildStudyHistoryTable(BuildContext context, List<StudyRecord> records) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Text('Nenhum registro de estudo para esta matéria ainda.'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Primeiro Registro'),
              onPressed: () => _openStudyRegisterModal(),
            ),
          ],
        ),
      );
    }

    return DataTable(
      columns: const [
        DataColumn(label: Text('Data')),
        DataColumn(label: Text('Tópico')),
        DataColumn(label: Text('Ações')),
      ],
      rows: records.map((record) {
        return DataRow(cells: [
          DataCell(Text(record.date.split('T')[0])),
          DataCell(Text(record.topic)),
          DataCell(Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _openStudyRegisterModal(record: record),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  Provider.of<HistoryProvider>(context, listen: false).deleteStudyRecord(record.id);
                },
              ),
            ],
          )),
        ]);
      }).toList(),
    );
  }

  Widget _buildChart(BuildContext context, List<StudyRecord> records) {
    if (records.isEmpty) {
      return const Center(child: Text('Nenhum registro de estudo para gerar o gráfico.'));
    }

    return Column(
      children: [
        ToggleButtons(
          isSelected: [_chartPeriodIndex == 0, _chartPeriodIndex == 1, _chartPeriodIndex == 2],
          onPressed: (index) {
            setState(() {
              _chartPeriodIndex = index;
            });
          },
          children: const [
            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Diário')),
            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Semanal')),
            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Mensal')),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            _getChartData(records),
          ),
        ),
      ],
    );
  }

  LineChartData _getChartData(List<StudyRecord> records) {
    final Map<DateTime, double> aggregatedData = {};

    for (var record in records) {
      final date = DateTime.parse(record.date);
      final studyTimeHours = record.study_time / 3600000.0;
      DateTime key;

      if (_chartPeriodIndex == 0) { // Daily
        key = DateTime(date.year, date.month, date.day);
      } else if (_chartPeriodIndex == 1) { // Weekly
        key = date.subtract(Duration(days: date.weekday - 1));
        key = DateTime(key.year, key.month, key.day);
      } else { // Monthly
        key = DateTime(date.year, date.month);
      }

      aggregatedData[key] = (aggregatedData[key] ?? 0) + studyTimeHours;
    }

    final sortedKeys = aggregatedData.keys.toList()..sort();
    final List<FlSpot> spots = [];
    for (var i = 0; i < sortedKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), aggregatedData[sortedKeys[i]]!));
    }

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < sortedKeys.length) {
                final date = sortedKeys[value.toInt()];
                String format;
                if (_chartPeriodIndex == 0) {
                  format = 'dd/MM';
                } else if (_chartPeriodIndex == 1) {
                  format = 'dd/MM';
                } else {
                  format = 'MM/yy';
                }
                return Text(DateFormat(format).format(date));
              }
              return const Text('');
            },
            reservedSize: 40,
          ),
        ),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.amber,
          barWidth: 4,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(
            show: true,
            color: Colors.amber.withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}

class TopicListItem extends StatefulWidget {
  final Topic topic;
  final int depth;
  final bool isInitiallyExpanded;
  final Set<String> studiedTopicTexts;
  final VoidCallback onAdd;

  const TopicListItem({
    super.key,
    required this.topic,
    required this.depth,
    required this.isInitiallyExpanded,
    required this.studiedTopicTexts,
    required this.onAdd,
  });

  @override
  State<TopicListItem> createState() => _TopicListItemState();
}

class _TopicListItemState extends State<TopicListItem> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isInitiallyExpanded;
  }

  @override
  void didUpdateWidget(TopicListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isInitiallyExpanded != oldWidget.isInitiallyExpanded) {
      setState(() {
        _isExpanded = widget.isInitiallyExpanded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSubtopics = widget.topic.sub_topics != null && widget.topic.sub_topics!.isNotEmpty;
    final bool isGroupingTopic = widget.topic.is_grouping_topic ?? false;
    final bool isStudied = widget.studiedTopicTexts.contains(widget.topic.topic_text);

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: widget.depth * 16.0 + 16.0),
          leading: hasSubtopics
              ? IconButton(
                  icon: Icon(_isExpanded ? Icons.arrow_drop_down : Icons.arrow_right),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                )
              : const SizedBox(width: 48),
          title: Text(
            widget.topic.topic_text,
            style: TextStyle(
              fontWeight: isGroupingTopic ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Chip(
                label: Text(isStudied ? 'Concluído' : 'Pendente'),
                backgroundColor: isStudied ? Colors.green.shade100 : Colors.red.shade100,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: isGroupingTopic ? null : widget.onAdd,
              ),
            ],
          ),
        ),
        if (_isExpanded && hasSubtopics)
          ...widget.topic.sub_topics!.map((subTopic) => TopicListItem(
                topic: subTopic,
                depth: widget.depth + 1,
                isInitiallyExpanded: widget.isInitiallyExpanded,
                studiedTopicTexts: widget.studiedTopicTexts,
                onAdd: widget.onAdd, // Pass the onAdd callback to subtopics
              )),
      ],
    );
  }
}