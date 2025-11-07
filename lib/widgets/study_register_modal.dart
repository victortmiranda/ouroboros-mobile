import 'package:flutter/material.dart';
import 'package:ouroboros_mobile/models/data_models.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ouroboros_mobile/widgets/add_subject_modal.dart';
import 'package:ouroboros_mobile/providers/all_subjects_provider.dart';
import 'package:ouroboros_mobile/providers/active_plan_provider.dart';
import 'package:ouroboros_mobile/providers/auth_provider.dart';

class StudyRegisterModal extends StatefulWidget {
  final String planId;
  final Function(StudyRecord) onSave;
  final Function(StudyRecord)? onUpdate;
  final StudyRecord? initialRecord;
  final Topic? topic;
  final String? justification;
  final int? initialTime;
  final bool showDeleteButton;
  final Function()? onDelete;

  const StudyRegisterModal({
    super.key,
    required this.planId,
    required this.onSave,
    this.onUpdate,
    this.initialRecord,
    this.topic,
    this.justification,
    this.initialTime,
    this.showDeleteButton = false,
    this.onDelete,
  });

  @override
  State<StudyRegisterModal> createState() => _StudyRegisterModalState();
}

class _StudyRegisterModalState extends State<StudyRegisterModal> {
  final _formKey = GlobalKey<FormState>();

  // State variables
  late DateTime _selectedDate;
  Subject? _selectedSubject;
  Topic? _selectedTopic;
  String? _selectedCategory;
  final TextEditingController _studyTimeController =
  TextEditingController(text: '00:00:00');
  final TextEditingController _correctQuestionsController =
  TextEditingController(text: '0');
  final TextEditingController _incorrectQuestionsController =
  TextEditingController(text: '0');
  final TextEditingController _startPageController =
  TextEditingController(text: '0');
  final TextEditingController _endPageController =
  TextEditingController(text: '0');
  List<Map<String, int>> _pages = [{'start': 0, 'end': 0}];
  List<Map<String, String>> _videos = [
    {'title': '', 'start': '00:00:00', 'end': '00:00:00'}
  ];
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isTeoriaFinalizada = false;
  bool _countInPlanning = true;
  bool _isReviewSchedulingEnabled = false;
  List<String> _reviewPeriods = [];
  Map<String, String> _errors = {};

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
  void initState() {
    super.initState();

    _selectedDate = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final allSubjectsProvider =
      Provider.of<AllSubjectsProvider>(context, listen: false);
      final subjects =
      allSubjectsProvider.subjects.where((s) => s.plan_id == widget.planId).toList();

      if (widget.initialRecord != null) {
        final record = widget.initialRecord!;
        _selectedDate = DateTime.parse(record.date);
        if (subjects.isNotEmpty) {
          _selectedSubject = subjects.firstWhere(
                  (s) => s.id == record.subject_id,
              orElse: () => subjects.first);
          
          if (_selectedSubject != null && record.topic.isNotEmpty) {
            _selectedTopic = _findTopicByText(_selectedSubject!.topics, record.topic);
          }
        }
        _selectedCategory = record.category;
        _studyTimeController.text = _formatTime(record.study_time);
        _correctQuestionsController.text =
            record.questions['correct']?.toString() ?? '0';
        _incorrectQuestionsController.text =
            ((record.questions['total'] ?? 0) -
                (record.questions['correct'] ?? 0))
                .toString();
        _pages = record.pages.isNotEmpty
            ? List.from(record.pages)
            : [{'start': 0, 'end': 0}];
        _startPageController.text = _pages.first['start']?.toString() ?? '0';
        _endPageController.text = _pages.first['end']?.toString() ?? '0';
        _videos = record.videos.isNotEmpty
            ? List.from(record.videos.map((v) => {
          'title': v['title'] ?? '',
          'start': v['start'] ?? '00:00:00',
          'end': v['end'] ?? '00:00:00',
        }))
            : [
          {'title': '', 'start': '00:00:00', 'end': '00:00:00'}
        ];
        _notesController.text = record.notes ?? '';
        _isTeoriaFinalizada = record.teoria_finalizada;
        _countInPlanning = record.count_in_planning;
        _reviewPeriods = List.from(record.review_periods);
        _isReviewSchedulingEnabled = _reviewPeriods.isNotEmpty;
      } else {
        _studyTimeController.text = _formatTime(widget.initialTime ?? 0);
        if (widget.topic != null && subjects.isNotEmpty) {
          _selectedSubject = subjects.firstWhere(
                  (s) => s.id == widget.topic!.subject_id,
              orElse: () => subjects.first);
          _selectedTopic = widget.topic;
        } else if (subjects.isNotEmpty) {
          // _selectedSubject = subjects.first; // Removido para não pré-selecionar matéria
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _studyTimeController.dispose();
    _correctQuestionsController.dispose();
    _incorrectQuestionsController.dispose();
    _startPageController.dispose();
    _endPageController.dispose();
    _materialController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatTime(int ms) {
    if (ms < 0) ms = 0;
    final totalSeconds = ms ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int _parseTime(String timeStr) {
    final parts = timeStr.split(':').map(int.tryParse).toList();
    if (parts.length == 3 && parts.every((p) => p != null)) {
      return (parts[0]! * 3600 + parts[1]! * 60 + parts[2]!) * 1000;
    }
    return 0;
  }

  void _addPagePair() {
    setState(() {
      _pages.add({'start': 0, 'end': 0});
    });
  }

  void _addVideoRow() {
    setState(() {
      _videos.add({'title': '', 'start': '00:00:00', 'end': '00:00:00'});
    });
  }

  bool _validateForm() {
    final newErrors = <String, String>{};
    final timeRegex = RegExp(r'^([0-9]?[0-9]):[0-5][0-9]:[0-5][0-9]$');
    if (_selectedSubject == null) newErrors['subject'] = 'Selecione uma disciplina';
    if (_selectedCategory == null) newErrors['category'] = 'Selecione uma categoria';
    if (_studyTimeController.text == '00:00:00') {
      newErrors['studyTime'] = 'Informe o tempo de estudo';
    }
    if (!timeRegex.hasMatch(_studyTimeController.text)) {
      newErrors['studyTime'] = 'Formato de tempo inválido (HH:MM:SS)';
    }
    if (_selectedTopic == null && (_selectedSubject?.topics.isNotEmpty ?? false)) {
      newErrors['topic'] = 'Selecione um tópico';
    }
    for (int i = 0; i < _pages.length; i++) {
      final page = _pages[i];
      if (page['start']! < 0 || page['end']! < 0) {
        newErrors['page-$i'] = 'Páginas não podem ser negativas';
      }
      if (page['end']! < page['start']!) {
        newErrors['page-$i'] = 'Página final deve ser maior ou igual à inicial';
      }
    }
    for (int i = 0; i < _videos.length; i++) {
      final video = _videos[i];
      final hasInfo = video['title']!.trim().isNotEmpty ||
          video['start'] != '00:00:00' ||
          video['end'] != '00:00:00';
      if (hasInfo) {
        if (video['title']!.trim().isEmpty) {
          newErrors['video-title-$i'] = 'Título do vídeo é obrigatório';
        }
        if (!timeRegex.hasMatch(video['start']!) ||
            !timeRegex.hasMatch(video['end']!)) {
          newErrors['video-time-$i'] = 'Formato de tempo inválido (HH:MM:SS)';
        }
        if (_parseTime(video['end']!) <= _parseTime(video['start']!)) {
          newErrors['video-time-$i'] = 'Tempo final deve ser maior que o inicial';
        }
      }
    }
    if ((int.tryParse(_correctQuestionsController.text) ?? 0) < 0 ||
        (int.tryParse(_incorrectQuestionsController.text) ?? 0) < 0) {
      newErrors['questions'] = 'Valores não podem ser negativos';
    }
    setState(() => _errors = newErrors);
    return newErrors.isEmpty;
  }

  void _showAddReviewDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar Revisão'),
        content: SizedBox(
          width: 100.0,
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Dias'),
            keyboardType: TextInputType.number,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final days = int.tryParse(controller.text);
              if (days != null && days > 0) {
                setState(() => _reviewPeriods.add('${days}d'));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _showTopicSelector() async {
    if (_selectedSubject == null) return;
    final selected = await showDialog<Topic?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selecione o Tópico'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: _buildTopicItems(_selectedSubject!.topics, 0),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar'))
        ],
      ),
    );
    if (selected != null) {
      setState(() => _selectedTopic = selected);
    }
  }

  List<Widget> _buildTopicItems(List<Topic> topics, int level) {
    List<Widget> items = [];
    for (var topic in topics) {
      final isGrouping = topic.is_grouping_topic ?? (topic.sub_topics?.isNotEmpty ?? false);
      items.add(ListTile(
        title: Text(
          isGrouping ? '* ${topic.topic_text}' : topic.topic_text,
          style: TextStyle(
            fontWeight: isGrouping ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        contentPadding: EdgeInsets.only(left: level * 16.0),
        onTap: isGrouping ? null : () => Navigator.pop(context, topic),
      ));
      if (topic.sub_topics != null) {
        items.addAll(_buildTopicItems(topic.sub_topics!, level + 1));
      }
    }
    return items;
  }

  void _saveForm() {
    if (!_validateForm()) return;

    final correct = int.tryParse(_correctQuestionsController.text) ?? 0;
    final incorrect = int.tryParse(_incorrectQuestionsController.text) ?? 0;
    final total = correct + incorrect;

    _pages.first['start'] = int.tryParse(_startPageController.text) ?? 0;
    _pages.first['end'] = int.tryParse(_endPageController.text) ?? 0;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final activePlanProvider = Provider.of<ActivePlanProvider>(context, listen: false);
    final record = StudyRecord(
      id: widget.initialRecord?.id ?? Uuid().v4(),
      userId: authProvider.currentUser!.name,
      plan_id: activePlanProvider.activePlan!.id,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      subject_id: _selectedSubject!.id,
      topic: _selectedTopic?.topic_text ?? '',
      category: _selectedCategory!,
      study_time: _parseTime(_studyTimeController.text),
      questions: {
        'total': total,
        'correct': correct,
      },
      material: _materialController.text.isEmpty ? null : _materialController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      review_periods: _reviewPeriods,
      teoria_finalizada: _isTeoriaFinalizada,
      count_in_planning: _countInPlanning,
      pages: _pages,
      videos: _videos,
    );

    if (widget.initialRecord != null && widget.onUpdate != null) {
      widget.onUpdate!(record);
    } else {
      widget.onSave(record);
    }
    Navigator.of(context).pop();
  }

  void _handleDelete() {
    if (widget.initialRecord != null && widget.onDelete != null) {
      widget.onDelete!();
      Navigator.of(context).pop();
    }
  }

  void _showEditSubjectModal() {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma disciplina selecionada para editar.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddSubjectModal(
        initialSubjectData: _selectedSubject,
        onSave: (subjectName, topics, color) async {
          final updatedSubject = Subject(
            id: _selectedSubject!.id,
            plan_id: _selectedSubject!.plan_id,
            subject: subjectName,
            topics: topics,
            color: color,
          );
          final allSubjectsProvider = Provider.of<AllSubjectsProvider>(context, listen: false);
          await allSubjectsProvider.updateSubject(updatedSubject);
          
          // Atualiza o estado local para refletir a mudança
          setState(() {
            _selectedSubject = updatedSubject;
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showAddSubjectModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddSubjectModal(
        onSave: (subjectName, topics, color) async {
          final newSubject = Subject(
            id: const Uuid().v4(),
            plan_id: widget.planId,
            subject: subjectName,
            topics: topics,
            color: color,
          );
          final allSubjectsProvider =
          Provider.of<AllSubjectsProvider>(context, listen: false);
          await allSubjectsProvider.addSubject(newSubject);
          setState(() {
            _selectedSubject = newSubject;
            _selectedTopic = null;
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.initialRecord == null ? 'Adicionar Registro' : 'Editar Registro'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.justification != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    border: Border(
                        left: BorderSide(
                            width: 4, color: theme.colorScheme.secondary)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sugestão do Algoritmo',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(widget.justification!),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildDateField(),
              const SizedBox(height: 12),
              _buildContentSelectors(),
              const SizedBox(height: 12),
              _buildTimeAndTopicSelectors(),
              const SizedBox(height: 16),
              _buildProgressFields(),
              _buildVideosFields(),
              const SizedBox(height: 16),
              _buildCheckboxes(),
              if (_isReviewSchedulingEnabled) _buildReviewPeriods(),
              const SizedBox(height: 16),
              _buildMaterialField(),
              const SizedBox(height: 16),
              _buildNotesField(),
            ],
          ),
        ),
      ),
      bottomSheet: _buildBottomBar(context),
    );
  }

  // -----------------------------------------------------------------------
  // Métodos auxiliares de UI (todos estavam faltando ou incompletos)
  // -----------------------------------------------------------------------

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => setState(() => _selectedDate = DateTime.now()),
                child: const Text('Hoje'),
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => setState(() => _selectedDate =
                    DateTime.now().subtract(const Duration(days: 1))),
                child: const Text('Ontem'),
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              flex: 2,
              child: ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: const Text('Outro'),
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              flex: 3,
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    border: OutlineInputBorder(),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentSelectors() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            isExpanded: true,
            items: {
              'teoria': 'Teoria',
              'revisao': 'Revisão',
              'questoes': 'Questões',
              'leitura_lei': 'Leitura de Lei',
              'jurisprudencia': 'Jurisprudência',
            }
                .entries
                .map((e) =>
                DropdownMenuItem<String>(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v),
            decoration: InputDecoration(
              labelText: 'Categoria',
              errorText: _errors['category'],
              border: const OutlineInputBorder(),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Consumer<AllSubjectsProvider>(
          builder: (context, allSubjectsProvider, child) {
            final subjects = allSubjectsProvider.subjects
                .where((s) => s.plan_id == widget.planId)
                .toList();

            // Removido: Lógica de pré-seleção da primeira matéria
            // if (_selectedSubject == null && subjects.isNotEmpty) {
            //   _selectedSubject = subjects.first;
            // } else if (!subjects.any((s) => s.id == _selectedSubject?.id)) {
            //   _selectedSubject = subjects.isNotEmpty ? subjects.first : null;
            // }

            return Expanded(
              child: DropdownButtonFormField<Subject>(
                value: _selectedSubject,
                isExpanded: true,
                items: subjects
                    .map((s) => DropdownMenuItem<Subject>(
                    value: s, child: Text(s.subject, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedSubject = v;
                    _selectedTopic = null;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Disciplina',
                  errorText: _errors['subject'],
                  border: const OutlineInputBorder(),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          height: 48,
          child: ElevatedButton(
            onPressed: _showAddSubjectModal,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(0),
            ),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeAndTopicSelectors() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _studyTimeController,
            decoration: InputDecoration(
              labelText: 'Tempo (HH:MM:SS)',
              errorText: _errors['studyTime'],
              border: const OutlineInputBorder(),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            keyboardType: TextInputType.datetime,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: InkWell(
            onTap: _showTopicSelector,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Tópico',
                errorText: _errors['topic'],
                border: const OutlineInputBorder(),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selectedTopic?.topic_text ?? 'Selecione um tópico',
                      style: _selectedTopic == null
                          ? TextStyle(color: Colors.grey.shade600)
                          : null,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          height: 48,
          child: ElevatedButton(
            onPressed: _showEditSubjectModal,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(0),
            ),
            child: const Icon(Icons.edit),
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialField() {
    return TextFormField(
      controller: _materialController,
      decoration: const InputDecoration(
        labelText: 'Material',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

  Widget _buildProgressFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              const Text("Questões", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _correctQuestionsController,
                          decoration: InputDecoration(
                            labelText: 'Acertos',
                            errorText: _errors['questions'],
                            border: const OutlineInputBorder(),
                            contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () {
                                  final cur = int.tryParse(_correctQuestionsController.text) ?? 0;
                                  if (cur > 0) {
                                    _correctQuestionsController.text = (cur - 1).toString();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(0),
                                ),
                                child: const Icon(Icons.remove),
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () {
                                  final cur = int.tryParse(_correctQuestionsController.text) ?? 0;
                                  _correctQuestionsController.text = (cur + 1).toString();
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(0),
                                ),
                                child: const Icon(Icons.add),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _incorrectQuestionsController,
                          decoration: const InputDecoration(
                            labelText: 'Erros',
                            border: OutlineInputBorder(),
                            contentPadding:
                            EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () {
                                  final cur = int.tryParse(_incorrectQuestionsController.text) ?? 0;
                                  if (cur > 0) {
                                    _incorrectQuestionsController.text = (cur - 1).toString();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(0),
                                ),
                                child: const Icon(Icons.remove),
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () {
                                  final cur = int.tryParse(_incorrectQuestionsController.text) ?? 0;
                                  _incorrectQuestionsController.text = (cur + 1).toString();
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(0),
                                ),
                                child: const Icon(Icons.add),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              const Text("Páginas", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _startPageController,
                          decoration: InputDecoration(
                            labelText: 'Início',
                            errorText: _errors['page-0'],
                            border: const OutlineInputBorder(),
                            contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () {
                                  final cur = int.tryParse(_startPageController.text) ?? 0;
                                  if (cur > 0) {
                                    _startPageController.text = (cur - 1).toString();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(0),
                                ),
                                child: const Icon(Icons.remove),
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () {
                                  final cur = int.tryParse(_startPageController.text) ?? 0;
                                  _startPageController.text = (cur + 1).toString();
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(0),
                                ),
                                child: const Icon(Icons.add),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _endPageController,
                          decoration: const InputDecoration(
                            labelText: 'Fim',
                            border: OutlineInputBorder(),
                            contentPadding:
                            EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () {
                                  final cur = int.tryParse(_endPageController.text) ?? 0;
                                  if (cur > 0) {
                                    _endPageController.text = (cur - 1).toString();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(0),
                                ),
                                child: const Icon(Icons.remove),
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () {
                                  final cur = int.tryParse(_endPageController.text) ?? 0;
                                  _endPageController.text = (cur + 1).toString();
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(0),
                                ),
                                child: const Icon(Icons.add),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideosFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Vídeos/Aulas", style: TextStyle(fontSize: 16)),
        ..._videos.asMap().entries.map((entry) {
          final idx = entry.key;
          final video = entry.value;
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: video['title'],
                    decoration: InputDecoration(
                      labelText: 'Título',
                      errorText: _errors['video-title-$idx'],
                      border: const OutlineInputBorder(),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    onChanged: (v) => video['title'] = v,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: video['start'],
                    decoration: InputDecoration(
                      labelText: 'Início',
                      errorText: _errors['video-time-$idx'],
                      border: const OutlineInputBorder(),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    keyboardType: TextInputType.datetime,
                    onChanged: (v) => video['start'] = v,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: video['end'],
                    decoration: const InputDecoration(
                      labelText: 'Fim',
                      border: OutlineInputBorder(),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    keyboardType: TextInputType.datetime,
                    onChanged: (v) => video['end'] = v,
                  ),
                ),
                if (_videos.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => setState(() => _videos.removeAt(idx)),
                  ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
              onPressed: _addVideoRow,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(0),
              ),
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Comentários',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      maxLines: 4,
    );
  }

  Widget _buildCheckboxes() {
    return Column(
      children: [
        Row(
          children: [
            Checkbox(
              value: _isTeoriaFinalizada,
              onChanged: (v) => setState(() => _isTeoriaFinalizada = v!),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isTeoriaFinalizada = !_isTeoriaFinalizada),
                child: const Text('Teoria Finalizada'),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: _isReviewSchedulingEnabled,
              onChanged: (v) => setState(() => _isReviewSchedulingEnabled = v!),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isReviewSchedulingEnabled = !_isReviewSchedulingEnabled),
                child: const Text('Programar Revisões'),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: _countInPlanning,
              onChanged: (v) => setState(() => _countInPlanning = v!),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _countInPlanning = !_countInPlanning),
                child: Text(
                  'Contabilizar no Planejamento',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewPeriods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        const Text("Revisões Programadas", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            ..._reviewPeriods.map((p) => Chip(
              label: Text(p),
              onDeleted: () => setState(() => _reviewPeriods.remove(p)),
            )),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('Adicionar'),
              onPressed: _showAddReviewDialog,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.initialRecord != null && widget.showDeleteButton)
            TextButton(
              onPressed: _handleDelete,
              child: const Text('Excluir Registro',
                  style: TextStyle(color: Colors.red, fontSize: 16)),
            ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _saveForm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              textStyle:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}