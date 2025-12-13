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
  final Subject? subject;
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
    this.subject,
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
  List<Topic> _selectedTopics = []; // Agora uma lista para múltiplos tópicos
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
  List<Map<String, int>> _pages = [];
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

    if (widget.initialRecord != null) {
      // This block is for editing an existing record.
      final record = widget.initialRecord!;
      _selectedDate = DateTime.parse(record.date);

      // We need the provider to find the subject object from the ID.
      // This needs context, so we do it in a post-frame callback.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final allSubjectsProvider = Provider.of<AllSubjectsProvider>(context, listen: false);
        final subjects = allSubjectsProvider.subjects.where((s) => s.plan_id == widget.planId).toList();
        
        if (subjects.isNotEmpty) {
          try {
            _selectedSubject = subjects.firstWhere((s) => s.id == record.subject_id);
            // Carrega múltiplos tópicos do registro inicial
            if (record.topic_ids.isNotEmpty) { // Agora usa topic_ids
              _selectedTopics.addAll(record.topic_ids.map((id) {
                return _findTopicById(_selectedSubject!.topics, id); // Usa findTopicById
              }).whereType<Topic>().toList()); // Filtra nulos
            }
          } catch (e) {
            // Handle case where subject is not found
          }
        }
        setState(() {}); // Update UI with found subject/topic
      });

      _selectedCategory = record.category;
      _studyTimeController.text = _formatTime(record.study_time);
      _correctQuestionsController.text = record.questions['correct']?.toString() ?? '0';
      _incorrectQuestionsController.text = ((record.questions['total'] ?? 0) - (record.questions['correct'] ?? 0)).toString();
      _pages = record.pages.isNotEmpty
          ? record.pages.map((p) => {'start': (p['start'] as num).toInt(), 'end': (p['end'] as num).toInt()}).toList()
          : [];
      _startPageController.text = _pages.isNotEmpty ? _pages.first['start']?.toString() ?? '0' : '0';
      _endPageController.text = _pages.isNotEmpty ? _pages.first['end']?.toString() ?? '0' : '0';
      _videos = record.videos.isNotEmpty
          ? record.videos.map<Map<String, String>>((v) => {
        'title': v['title']?.toString() ?? '',
        'start': v['start']?.toString() ?? '00:00:00',
        'end': v['end']?.toString() ?? '00:00:00',
      }).toList()
          : [
        {'title': '', 'start': '00:00:00', 'end': '00:00:00'}
      ];
      _notesController.text = record.notes ?? '';
      _isTeoriaFinalizada = record.teoria_finalizada;
      _countInPlanning = record.count_in_planning;
      _reviewPeriods = List.from(record.review_periods);
      _isReviewSchedulingEnabled = _reviewPeriods.isNotEmpty;
    } else {
      // This is for creating a new record.
      // Set state directly and synchronously.
      _selectedDate = DateTime.now();
      _selectedSubject = widget.subject;
      _selectedTopics = []; // Garante que nenhum tópico seja pré-selecionado na lista
      _studyTimeController.text = _formatTime(widget.initialTime ?? 0);
    }
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
    // Alterado para verificar a lista de tópicos
    if (_selectedTopics.isEmpty && (_selectedSubject?.topics.isNotEmpty ?? false)) {
      newErrors['topic'] = 'Selecione pelo menos um tópico';
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
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.calendar_today, color: theme.colorScheme.onSurface),
            const SizedBox(width: 12),
            Text('Adicionar Revisão', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Informe em quantos dias a partir da data do estudo você deseja agendar a próxima revisão.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAddChip('1d'),
                _buildQuickAddChip('7d'),
                _buildQuickAddChip('30d'),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18),
              decoration: InputDecoration(
                labelText: 'Dias para a revisão',
                labelStyle: const TextStyle(color: Colors.teal),
                prefixIcon: const Icon(Icons.timelapse, color: Colors.teal),
                filled: true,
                fillColor: theme.scaffoldBackgroundColor.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                ),
              ),
              keyboardType: TextInputType.number,
              cursorColor: Colors.teal,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Adicionar'),
            onPressed: () {
              final days = int.tryParse(controller.text);
              if (days != null && days > 0) {
                setState(() => _reviewPeriods.add('${days}d'));
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddChip(String period) {
    return ActionChip(
      label: Text(period, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: Colors.teal,
      onPressed: () {
        setState(() {
          if (!_reviewPeriods.contains(period)) {
            _reviewPeriods.add(period);
          }
        });
      },
    );
  }

  void _showTopicSelector() async {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione uma disciplina primeiro.')),
      );
      return;
    }

    final selectedTopicsFromSheet = await showModalBottomSheet<List<Topic>?>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (BuildContext context, ScrollController scrollController) {
            return _TopicSelectionSheet(
              topics: _selectedSubject!.topics,
              scrollController: scrollController,
              onTopicsSelected: (topics) {
                Navigator.of(context).pop(topics); // Retorna a lista de tópicos
              },
              // Agora passa uma lista de IDs para inicializar a seleção no modal
              initialSelectedTopicIds: _selectedTopics.map((t) => t.id.toString()).toList(),
            );
          },
        );
      },
    );

    if (selectedTopicsFromSheet != null) { // Pode ser uma lista vazia, mas não null
      setState(() {
        _selectedTopics = selectedTopicsFromSheet; // Atualiza a lista de tópicos selecionados
        if (_selectedTopics.isEmpty) {
          _errors['topic'] = 'Selecione pelo menos um tópico';
        } else {
          _errors.remove('topic');
        }
      });
    }
  }



  void _saveForm() {
    if (!_validateForm()) return;

    final correct = int.tryParse(_correctQuestionsController.text) ?? 0;
    final incorrect = int.tryParse(_incorrectQuestionsController.text) ?? 0;
    final total = correct + incorrect;

    final startPage = int.tryParse(_startPageController.text) ?? 0;
    final endPage = int.tryParse(_endPageController.text) ?? 0;

    List<Map<String, int>> pagesToSave = [];
    if (startPage > 0 || endPage > 0) {
      pagesToSave.add({'start': startPage, 'end': endPage});
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final activePlanProvider = Provider.of<ActivePlanProvider>(context, listen: false);
    final record = StudyRecord(
      id: widget.initialRecord?.id ?? const Uuid().v4(),
      userId: authProvider.currentUser!.name,
      plan_id: activePlanProvider.activePlan!.id,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      subject_id: _selectedSubject!.id,
      topic_texts: _selectedTopics.map((t) => t.topic_text).toList(), // Atualizado
      topic_ids: _selectedTopics.map((t) => t.id.toString()).toList(), // Adicionado
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
      pages: pagesToSave,
      videos: _videos,
      lastModified: DateTime.now().millisecondsSinceEpoch,
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
            lastModified: DateTime.now().millisecondsSinceEpoch,
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
      backgroundColor: Colors.white, // Set background to white
      isScrollControlled: true,
      builder: (context) {
        return Theme( // Wrap content in a Theme
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              surfaceTint: Colors.transparent, // Override surfaceTint
            ),
          ),
          child: Container( // Direct child of Theme
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: AddSubjectModal(
              onSave: (subjectName, topics, color) async {
                final newSubject = Subject(
                  id: const Uuid().v4(),
                  plan_id: widget.planId,
                  subject: subjectName,
                  topics: topics,
                  color: color,
                  lastModified: DateTime.now().millisecondsSinceEpoch,
                );
                final allSubjectsProvider =
                Provider.of<AllSubjectsProvider>(context, listen: false);
                await allSubjectsProvider.addSubject(newSubject);
                setState(() {
                  _selectedSubject = newSubject;
                  _selectedTopics = []; // Reseta a lista de tópicos
                });
                Navigator.pop(context); // Pop the modal sheet
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth > 768.0;

        return ScrollbarTheme(
          data: ScrollbarThemeData(
            thumbColor: MaterialStateProperty.all(Colors.teal),
            radius: const Radius.circular(10),
            thickness: MaterialStateProperty.all(8),
          ),
          child: Theme(
            data: theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                primary: Colors.teal,
                secondary: Colors.teal,
              ),
              textSelectionTheme: theme.textSelectionTheme.copyWith(
                cursorColor: Colors.teal,
                selectionColor: Colors.teal.withOpacity(0.4),
                selectionHandleColor: Colors.teal,
              ),
            ),
            child: isDesktop
                ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 768.0), // Limita a largura em desktop
                child: _buildModalContent(context, theme, isDesktop),
              ),
            )
                : _buildModalContent(context, theme, isDesktop),
          ),
        );
      },
    );
  }

  Widget _buildModalContent(BuildContext context, ThemeData theme, bool isDesktop) {
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
              isDesktop
                  ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildDateField(theme, isDesktop)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildContentSelectors(theme, isDesktop)),
                ],
              )
                  : Column(
                children: [
                  _buildDateField(theme, isDesktop),
                  const SizedBox(height: 12),
                  _buildContentSelectors(theme, isDesktop),
                ],
              ),
              const SizedBox(height: 12),
              _buildTimeAndTopicSelectors(theme, isDesktop),
              const SizedBox(height: 16),
              _buildProgressFields(theme, isDesktop),
              _buildVideosFields(theme),
              const SizedBox(height: 16),
              _buildCheckboxes(),
              if (_isReviewSchedulingEnabled) _buildReviewPeriods(),
              const SizedBox(height: 16),
              _buildMaterialField(theme),
              const SizedBox(height: 16),
              _buildNotesField(theme),
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

  Widget _buildDateField(ThemeData theme, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              flex: isDesktop ? 1 : 2, // Menor flex para desktop
              child: ElevatedButton(
                onPressed: () => setState(() => _selectedDate = DateTime.now()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Hoje'),
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              flex: isDesktop ? 1 : 2, // Menor flex para desktop
              child: ElevatedButton(
                onPressed: () => setState(() => _selectedDate =
                    DateTime.now().subtract(const Duration(days: 1))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ontem'),
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              flex: isDesktop ? 1 : 2, // Menor flex para desktop
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Outro'),
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              flex: isDesktop ? 3 : 3, // Maior flex para desktop
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
                  decoration: InputDecoration(
                    labelText: 'Data',
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                      color: theme.brightness == Brightness.dark ? Colors.grey[200]! : Colors.black,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: theme.brightness == Brightness.dark ? Colors.grey[200]! : Colors.black,
                        width: 2.0, // Make it slightly thicker when focused
                      ),
                    ),
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

  Widget _buildContentSelectors(ThemeData theme, bool isDesktop) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            isExpanded: true,
            dropdownColor: theme.cardColor,
            items: {
              'teoria': 'Teoria',
              'revisao': 'Revisão',
              'questoes': 'Questões',
              'leitura_lei': 'Leitura de Lei',
              'jurisprudencia': 'Jurisprudência',
            }
                .entries
                .map((e) =>
                DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(
                    e.value,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  ),
                ))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v),
            decoration: InputDecoration(
              labelText: 'Categoria',
              errorText: _errors['category'],
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.onSurface, // Use onSurface
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide( // Make it const
                  color: Colors.teal, // Change this to Colors.teal
                  width: 2.0,
                ),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Consumer<AllSubjectsProvider>(
            builder: (context, allSubjectsProvider, child) {
              final subjects = allSubjectsProvider.subjects
                  .where((s) => s.plan_id == widget.planId)
                  .toList();

              return DropdownButtonFormField<Subject>(
                value: _selectedSubject,
                isExpanded: true,
                dropdownColor: theme.cardColor,
                style: TextStyle(color: Colors.teal), // Add this
                decoration: InputDecoration(
                  labelText: 'Disciplina',
                  errorText: _errors['subject'],
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: theme.colorScheme.onSurface, // Use onSurface
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.teal,
                      width: 2.0,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                selectedItemBuilder: (BuildContext context) {
                  return subjects.map<Widget>((Subject item) {
                    return Text(
                      item.subject,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color), // Revert to theme text color
                    );
                  }).toList();
                },
                items: subjects.map((s) {
                  return DropdownMenuItem<Subject>(
                    value: s,
                    child: Card(
                      color: Color(int.parse(s.color.replaceFirst('#', '0xFF'))),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          s.subject,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedSubject = v;
                    _selectedTopics = []; // Reseta a lista de tópicos
                  });
                },
              );
            },
          ),
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
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeAndTopicSelectors(ThemeData theme, bool isDesktop) {
    return Row(
      children: [
        Expanded(
          flex: isDesktop ? 1 : 1, // Menor flex para desktop
          child: TextFormField(
            controller: _studyTimeController,
            decoration: InputDecoration(
              labelText: 'Tempo (HH:MM:SS)',
              errorText: _errors['studyTime'],
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.teal,
                  width: 2.0,
                ),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            keyboardType: TextInputType.datetime,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color), // Add this
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: isDesktop ? 3 : 2, // Maior flex para desktop
          child: InkWell(
            onTap: _showTopicSelector,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Tópico(s)', // Alterado label
                errorText: _errors['topic'],
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.teal,
                    width: 2.0,
                  ),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _selectedTopics.isEmpty // Exibe a lista de tópicos
                        ? Text(
                      'Selecione um tópico',
                      style: TextStyle(color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    )
                        : Wrap( // Usa Wrap para exibir múltiplos tópicos como Chips
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _selectedTopics.map((topic) => Chip(
                        label: Text(topic.topic_text),
                        backgroundColor: Colors.teal.shade50,
                        labelStyle: TextStyle(color: Colors.teal.shade800),
                        deleteIcon: const Icon(Icons.close, size: 18), // Make it const
                        onDeleted: () {
                          setState(() {
                            _selectedTopics.remove(topic);
                            if (_selectedTopics.isEmpty) {
                              _errors['topic'] = 'Selecione pelo menos um tópico';
                            } else {
                              _errors.remove('topic');
                            }
                          });
                        },
                      )).toList(),
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
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Icon(Icons.edit),
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialField(ThemeData theme) {
    return TextFormField(
      controller: _materialController,
      decoration: InputDecoration(
        labelText: 'Material',
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.colorScheme.onSurface,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.teal,
            width: 2.0,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      style: TextStyle(color: theme.textTheme.bodyLarge?.color), // Add this
    );
  }

  Widget _buildProgressFields(ThemeData theme, bool isDesktop) {
    return Column(
      children: [
        _buildQuestionsSection(theme),
        const SizedBox(height: 16),
        _buildPagesSection(theme),
      ],
    );
  }

  Widget _buildQuestionsSection(ThemeData theme) {
    return Column(
      children: [
        const Text("Questões", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  TextFormField(
                    controller: _correctQuestionsController,
                    decoration: InputDecoration(
                      labelText: 'Acertos',
                      errorText: _errors['questions'],
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.teal,
                          width: 2.0,
                        ),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 4),
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
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
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
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
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
                    decoration: InputDecoration(
                      labelText: 'Erros',
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.teal,
                          width: 2.0,
                        ),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 4),
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
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
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
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
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
    );
  }

  Widget _buildPagesSection(ThemeData theme) {
    return Column(
      children: [
        const Text("Páginas", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  TextFormField(
                    controller: _startPageController,
                    decoration: InputDecoration(
                      labelText: 'Início',
                      errorText: _errors['page-0'],
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.teal,
                          width: 2.0,
                        ),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 4),
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
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
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
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
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
                    decoration: InputDecoration(
                      labelText: 'Fim',
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.teal,
                          width: 2.0,
                        ),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 4),
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
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
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
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
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
    );
  }

  Widget _buildVideosFields(ThemeData theme) {
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
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.teal,
                          width: 2.0,
                        ),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    onChanged: (v) => video['title'] = v,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color), // Add this
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
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.teal,
                          width: 2.0,
                        ),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    keyboardType: TextInputType.datetime,
                    onChanged: (v) => video['start'] = v,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color), // Add this
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: video['end'],
                    decoration: InputDecoration(
                      labelText: 'Fim',
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.teal,
                          width: 2.0,
                        ),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    keyboardType: TextInputType.datetime,
                    onChanged: (v) => video['end'] = v,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color), // Add this
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
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField(ThemeData theme) {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: 'Comentários',
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.colorScheme.onSurface,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.teal,
            width: 2.0,
          ),
        ),
        alignLabelWithHint: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      maxLines: 4,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color), // Add this
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
              activeColor: Colors.teal,
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
              activeColor: Colors.teal,
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
              activeColor: Colors.teal,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _countInPlanning = !_countInPlanning),
                child: Text(
                  'Contabilizar no Planejamento',
                  style: TextStyle(color: Colors.teal),
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
              avatar: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('Adicionar', style: TextStyle(color: Colors.white)),
              onPressed: _showAddReviewDialog,
              backgroundColor: Colors.teal,
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
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              textStyle:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
  Topic? _findTopicById(List<Topic> topics, String id) {
    for (var topic in topics) {
      if (topic.id.toString() == id) {
        return topic;
      }
      if (topic.sub_topics != null) {
        final found = _findTopicById(topic.sub_topics!, id);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }
} // Fim da classe _StudyRegisterModalState

// Novo Widget para renderizar a árvore de tópicos
class _TopicTreeWidget extends StatelessWidget {
  final List<Topic> topics;
  final int level;
  final ValueChanged<Topic> onToggleTopicSelection; // Alterado
  final Set<Topic> selectedTopics; // Alterado

  const _TopicTreeWidget({
    required this.topics,
    required this.level,
    required this.onToggleTopicSelection, // Alterado
    required this.selectedTopics, // Alterado
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    List<Widget> items = [];
    for (var topic in topics) {
      final isGrouping = (topic.sub_topics?.isNotEmpty ?? false) || (topic.is_grouping_topic ?? false);
      
      if (isGrouping) {
        items.add(
          Padding(
            padding: EdgeInsets.only(left: level * 16.0),
            child: ExpansionTile(
              leading: const Icon(Icons.folder, color: Colors.teal),
              title: Text(
                topic.topic_text,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              children: [
                _TopicTreeWidget(
                  topics: topic.sub_topics ?? [],
                  level: level + 1,
                  onToggleTopicSelection: onToggleTopicSelection, // Ajustado
                  selectedTopics: selectedTopics, // Ajustado
                ),
              ],
              tilePadding: EdgeInsets.zero,
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              iconColor: Colors.teal,
              collapsedIconColor: Colors.teal,
            ),
          ),
        );
      } else {
        items.add(
          Padding(
            padding: EdgeInsets.only(left: level * 16.0 + 4.0, right: 4.0, top: 2.0, bottom: 2.0),
            child: ListTile(
              leading: Checkbox(
                value: selectedTopics.contains(topic), // Ajustado
                onChanged: (bool? value) {
                  onToggleTopicSelection(topic); // Ajustado: apenas alterna
                },
                activeColor: Colors.teal,
              ),
              title: Text(
                topic.topic_text,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              onTap: () => onToggleTopicSelection(topic), // Ajustado: apenas alterna
              selected: selectedTopics.contains(topic), // Ajustado
              selectedTileColor: Colors.teal.withOpacity(0.1),
            ),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }
}

// Nova classe para o BottomSheet de seleção de tópico
class _TopicSelectionSheet extends StatefulWidget {
  final List<Topic> topics;
  final ScrollController scrollController;
  final ValueChanged<List<Topic>> onTopicsSelected; // Alterado para List<Topic>
  final List<String> initialSelectedTopicIds; // Alterado para lista de IDs

  const _TopicSelectionSheet({
    required this.topics,
    required this.scrollController,
    required this.onTopicsSelected,
    this.initialSelectedTopicIds = const [], // Default para lista vazia
  });

  @override
  State<_TopicSelectionSheet> createState() => _TopicSelectionSheetState();
}

class _TopicSelectionSheetState extends State<_TopicSelectionSheet> {
  final Set<Topic> _selectedTopics = {}; // Set para multi-seleção

  @override
  void initState() {
    super.initState();
    // Inicializa o Set com os IDs dos tópicos pré-selecionados
    for (String id in widget.initialSelectedTopicIds) {
      final topic = _findTopicById(widget.topics, id);
      if (topic != null) {
        _selectedTopics.add(topic);
      }
    }
  }

  // Função auxiliar para encontrar um tópico pelo ID em uma lista hierárquica
  Topic? _findTopicById(List<Topic> topics, String id) {
    for (var topic in topics) {
      if (topic.id.toString() == id) { // Comparar como String
        return topic;
      }
      if (topic.sub_topics != null) {
        final found = _findTopicById(topic.sub_topics!, id);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }

  void _toggleTopicSelection(Topic topic) {
    setState(() {
      if (_selectedTopics.contains(topic)) {
        _selectedTopics.remove(topic);
      } else {
        _selectedTopics.add(topic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Selecione os Tópicos', style: TextStyle(color: theme.colorScheme.onSurface)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.onTopicsSelected(_selectedTopics.toList()); // Retorna a lista de tópicos selecionados
            },
            child: Text(
              'Confirmar (${_selectedTopics.length})',
              style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: ScrollbarTheme(
        data: ScrollbarThemeData(
          thumbColor: MaterialStateProperty.all(Colors.teal),
          radius: const Radius.circular(10),
          thickness: MaterialStateProperty.all(8),
        ),
        child: Scrollbar(
          thumbVisibility: true,
          controller: widget.scrollController,
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.only(right: 16.0),
            children: [
              _TopicTreeWidget(
                topics: widget.topics,
                level: 0,
                onToggleTopicSelection: _toggleTopicSelection, // Passa o callback de toggle
                selectedTopics: _selectedTopics, // Passa o Set de tópicos selecionados
              ),
            ],
          ),
        ),
      ),
    );
  }
}
