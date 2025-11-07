import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ouroboros_mobile/models/data_models.dart';
import 'package:ouroboros_mobile/providers/all_subjects_provider.dart';
import 'package:ouroboros_mobile/providers/planning_provider.dart';
import 'package:ouroboros_mobile/widgets/topic_weights_modal.dart';

class CycleCreationModal extends StatefulWidget {
  const CycleCreationModal({Key? key}) : super(key: key);

  @override
  _CycleCreationModalState createState() => _CycleCreationModalState();
}

class _CycleCreationModalState extends State<CycleCreationModal> {
  final _stepperKey = GlobalKey();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  int _currentStep = 0;
  bool? _isManualMode;

  Set<String> _selectedSubjects = {};
  Map<String, Map<String, double>> _subjectSettings = {};

  // New state variables for guided mode
  String? _selectedWorkloadLevel;
  String? _selectedQuestionsLevel;
  String? _selectedSessionLevel;

  final _manualWorkloadController = TextEditingController();
  final _manualGuidedQuestionsGoalController = TextEditingController();
  final _manualSessionDurationController = TextEditingController();

  final List<String> _daysOfWeek = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
  Set<String> _selectedDays = {'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta'};

  List<StudySession> _manualStudySessions = [];
  Subject? _manualSelectedSubject;
  final _manualDurationController = TextEditingController();
  final _manualQuestionsGoalController = TextEditingController(text: '250');
  final _subjectSearchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _subjectSearchController.addListener(() {
      setState(() {
        _subjectSearchQuery = _subjectSearchController.text;
      });
    });
  }

  @override
  void dispose() {
    _manualDurationController.dispose();
    _manualQuestionsGoalController.dispose();
    _subjectSearchController.dispose();
    _manualWorkloadController.dispose();
    _manualGuidedQuestionsGoalController.dispose();
    _manualSessionDurationController.dispose();
    super.dispose();
  }

  String _subjectSearchQuery = '';

  // Data for the new interactive steps
  final List<Map<String, dynamic>> workloadLevels = [
    {'level': 'Iniciante', 'hours': '20-28 horas', 'value': 24, 'icon': Icons.child_care},
    {'level': 'Intermediário', 'hours': '28-36 horas', 'value': 32, 'icon': Icons.trending_up},
    {'level': 'Avançado', 'hours': '36-44 horas', 'value': 40, 'icon': Icons.workspace_premium},
  ];

  final List<Map<String, dynamic>> questionsLevels = [
    {
      'level': 'Iniciante',
      'range': '150 a 300 questões',
      'description': 'Entender a teoria, fazer poucas questões para fixar o que foi aprendido no dia.',
      'value': 225,
      'icon': Icons.looks_one,
    },
    {
      'level': 'Intermediário',
      'range': '300 a 500 questões',
      'description': 'Equilíbrio entre a leitura da teoria e a prática; questões por assunto para diagnóstico.',
      'value': 400,
      'icon': Icons.looks_two,
    },
    {
      'level': 'Avançado/Profissional',
      'range': '500 a 1.000+ questões',
      'description': 'Alto volume de simulados e questões de bancas, focando na revisão e na estratégia de prova.',
      'value': 750,
      'icon': Icons.looks_3,
    },
  ];

  final List<Map<String, dynamic>> sessionLevels = [
    {
      'level': 'Iniciante',
      'duration': '30 a 50 minutos',
      'description': 'Construção da resistência e do hábito. Maior tempo dedicado à Teoria (≈60%).',
      'min': 30,
      'max': 50,
      'icon': Icons.hourglass_empty,
    },
    {
      'level': 'Intermediário',
      'duration': '50 a 90 minutos',
      'description': 'Consolidação. Equilíbrio entre Teoria/Revisão (≈40%) e Questões (≈40%).',
      'min': 50,
      'max': 90,
      'icon': Icons.hourglass_bottom,
    },
    {
      'level': 'Avançado/Profissional',
      'duration': '1h30 a 2 horas',
      'description': 'Otimização. Maior parte do tempo dedicada à Prática e Revisão Ativa (Questões e Simulados ≈60−70%).',
      'min': 90,
      'max': 120,
      'icon': Icons.hourglass_full,
    },
  ];

  List<Step> _getSteps(BuildContext context, AllSubjectsProvider allSubjectsProvider) {
    final filteredSubjects = allSubjectsProvider.uniqueSubjectsByName
        .where((subject) =>
            subject.subject.toLowerCase().contains(_subjectSearchQuery.toLowerCase()))
        .toList();
    if (_isManualMode == null) {
      return [
        Step(
          title: const Text('Modo de Criação'),
          content: Column(
            children: [
              const Text('Escolha como você prefere montar seu plano de estudos.'),
              const SizedBox(height: 20),
              Card(
                child: InkWell(
                  onTap: () => setState(() { _isManualMode = false; _currentStep = 0; }),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.auto_awesome, size: 40, color: Colors.amber),
                        SizedBox(height: 10),
                        Text('Modo Guiado', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Text('Nós guiaremos você passo a passo.', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: InkWell(
                  onTap: () => setState(() { _isManualMode = true; _currentStep = 0; }),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.build, size: 40, color: Colors.amber),
                        SizedBox(height: 10),
                        Text('Modo Manual', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Text('Crie seu ciclo adicionando sessões uma a uma.', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          isActive: _currentStep >= 0,
        ),
      ];
    } else if (_isManualMode!) {
      return [
        Step(
          title: const Text('Criação Manual'),
          content: Column(
            children: [
              DropdownButtonFormField<Subject>(
                isExpanded: true,
                value: _manualSelectedSubject,
                hint: const Text('Selecione uma matéria'),
                onChanged: (Subject? newValue) {
                  setState(() {
                    _manualSelectedSubject = newValue;
                  });
                },
                items: allSubjectsProvider.uniqueSubjectsByName.map<DropdownMenuItem<Subject>>((subject) {
                  return DropdownMenuItem<Subject>(
                    value: subject,
                    child: Text(subject.subject, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
              ),
              TextField(
                controller: _manualDurationController,
                decoration: const InputDecoration(labelText: 'Duração (min)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (_manualSelectedSubject != null && _manualDurationController.text.isNotEmpty) {
                    final subject = _manualSelectedSubject!;
                    setState(() {
                      _manualStudySessions.add(
                        StudySession(
                          id: DateTime.now().toString(),
                          subject: subject.subject,
                          duration: int.parse(_manualDurationController.text),
                          color: subject.color,
                          subjectId: subject.id,
                        ),
                      );
                    });
                  }
                },
                child: const Text('Adicionar Sessão'),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _manualStudySessions.length,
                  itemBuilder: (context, index) {
                    final session = _manualStudySessions[index];
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: Color(int.parse(session.color.replaceFirst('#', '0xFF')))),
                      title: Text(session.subject),
                      subtitle: Text('${session.duration} min'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          setState(() {
                            _manualStudySessions.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          isActive: _currentStep >= 0,
        ),
      ];
    } else {
      return [
        Step(
          title: const Text('Matérias'),
          content: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TextField(
                  controller: _subjectSearchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar matéria',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: _subjectSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _subjectSearchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              CheckboxListTile(
                title: const Text('Selecionar Todas'),
                value: _selectedSubjects.length == filteredSubjects.length &&
                    filteredSubjects.isNotEmpty,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedSubjects.addAll(filteredSubjects.map((s) => s.id));
                    } else {
                      _selectedSubjects.removeWhere((id) => filteredSubjects.any((s) => s.id == id));
                    }
                  });
                },
              ),
              const Divider(),
              SizedBox(
                height: 300,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3 / 1.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: filteredSubjects.length,
                  itemBuilder: (context, index) {
                    final subject = filteredSubjects[index];
                    final isSelected = _selectedSubjects.contains(subject.id);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedSubjects.remove(subject.id);
                          } else {
                            _selectedSubjects.add(subject.id);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Card(
                        elevation: isSelected ? 4 : 1,
                        color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: isSelected
                              ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                              : BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  subject.subject,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 16),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          isActive: _currentStep >= 0,
        ),
        Step(
          title: const Text('Pesos'),
          content: SizedBox(
            height: 450, // Adjust height as needed
            child: Column(
              children: [
                Builder(
                  builder: (BuildContext buttonContext) {
                    return ElevatedButton.icon(
                      onPressed: () async {
                        final provider = Provider.of<AllSubjectsProvider>(buttonContext, listen: false);
                        if (!mounted) return;

                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          const SnackBar(content: Text('Calculando pesos...')),
                        );

                        try {
                          await provider.calculateAndApplyTopicWeights(_selectedSubjects.toList());
                          if (!mounted) return;

                          _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                          _scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(
                              content: Text('Pesos calculados e aplicados com sucesso!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                          _scaffoldMessengerKey.currentState?.showSnackBar(
                            SnackBar(
                              content: Text('Erro ao calcular pesos: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Calcular Pesos por Banca'),
                    );
                  }
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1 / 1.6, // Even taller
                    ),
                    itemCount: _selectedSubjects.length,
                    itemBuilder: (context, index) {
                      final subjectId = _selectedSubjects.elementAt(index);
                      final subject = allSubjectsProvider.subjects.cast<Subject?>().firstWhere(
                            (s) => s?.id == subjectId,
                            orElse: () => null,
                          );

                      if (subject == null) {
                        // Subject not found, maybe log this or handle it gracefully
                        return const SizedBox.shrink(); // Render nothing
                      }

                      _subjectSettings.putIfAbsent(subjectId, () => {'importance': 3, 'knowledge': 3});
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(subject.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.tune),
                                    tooltip: 'Ajustar Tópicos',
                                    onPressed: () {
                                      // Adicionando log para depuração
                                      final subjectDataForDebug = {
                                        'id': subject.id,
                                        'name': subject.subject,
                                        'topics': subject.topics.map((t) => t.toMap()).toList(),
                                      };
                                      print('Abrindo modal de pesos para a matéria: ${jsonEncode(subjectDataForDebug)}');

                                      showDialog(
                                        context: context,
                                        builder: (context) => TopicWeightsModal(subject: subject),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text('Importância'),
                              Slider(
                                value: _subjectSettings[subjectId]!['importance']!,
                                min: 1,
                                max: 5,
                                divisions: 4,
                                label: _subjectSettings[subjectId]!['importance']!.round().toString(),
                                onChanged: (double value) {
                                  setState(() {
                                    _subjectSettings[subjectId]!['importance'] = value;
                                  });
                                },
                              ),
                              const Text('Conhecimento'),
                              Slider(
                                value: _subjectSettings[subjectId]!['knowledge']!,
                                min: 1,
                                max: 5,
                                divisions: 4,
                                label: _subjectSettings[subjectId]!['knowledge']!.round().toString(),
                                onChanged: (double value) {
                                  setState(() {
                                    _subjectSettings[subjectId]!['knowledge'] = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          isActive: _currentStep >= 1,
        ),
        Step(
          title: const Text('Carga Horária'),
          content: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start, // Align cards to the top
                children: workloadLevels.map((level) {
                  final isSelected = _selectedWorkloadLevel == level['level'];
                  return Expanded(
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      elevation: isSelected ? 8 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isSelected
                            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                            : BorderSide.none,
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedWorkloadLevel = level['level'];
                            _manualWorkloadController.clear();
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(level['icon'], size: 32, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade700),
                              const SizedBox(height: 8),
                              Text(
                                level['level'],
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                level['hours'],
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: _selectedWorkloadLevel == 'Manual' ? 8 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: _selectedWorkloadLevel == 'Manual'
                      ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                      : BorderSide.none,
                ),
                child: ListTile(
                  leading: Icon(Icons.edit, color: _selectedWorkloadLevel == 'Manual' ? Theme.of(context).colorScheme.primary : Colors.grey.shade700),
                  title: Text('Manual', style: TextStyle(fontWeight: FontWeight.bold, color: _selectedWorkloadLevel == 'Manual' ? Theme.of(context).colorScheme.primary : null)),
                  subtitle: Text('Digite as horas manualmente'),
                  onTap: () {
                    setState(() {
                      _selectedWorkloadLevel = 'Manual';
                    });
                  },
                ),
              ),
              if (_selectedWorkloadLevel == 'Manual')
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextField(
                    controller: _manualWorkloadController,
                    decoration: const InputDecoration(
                      labelText: 'Horas semanais',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
            ],
          ),
          isActive: _currentStep >= 2,
        ),
        Step(
          title: const Text('Meta de Questões'),
          content: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: questionsLevels.map((level) {
                  final isSelected = _selectedQuestionsLevel == level['level'];
                  return Expanded(
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      elevation: isSelected ? 8 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isSelected
                            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                            : BorderSide.none,
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedQuestionsLevel = level['level'];
                            _manualGuidedQuestionsGoalController.clear();
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(level['icon'], size: 32, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade700),
                              const SizedBox(height: 8),
                              Text(
                                level['level'],
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                level['range'],
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: _selectedQuestionsLevel == 'Manual' ? 8 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: _selectedQuestionsLevel == 'Manual'
                      ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                      : BorderSide.none,
                ),
                child: ListTile(
                  leading: Icon(Icons.edit, color: _selectedQuestionsLevel == 'Manual' ? Theme.of(context).colorScheme.primary : Colors.grey.shade700),
                  title: Text('Manual', style: TextStyle(fontWeight: FontWeight.bold, color: _selectedQuestionsLevel == 'Manual' ? Theme.of(context).colorScheme.primary : null)),
                  subtitle: Text('Digite a meta manualmente'),
                  onTap: () {
                    setState(() {
                      _selectedQuestionsLevel = 'Manual';
                    });
                  },
                ),
              ),
              if (_selectedQuestionsLevel == 'Manual')
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextField(
                    controller: _manualGuidedQuestionsGoalController,
                    decoration: const InputDecoration(
                      labelText: 'Meta de questões semanais',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
            ],
          ),
          isActive: _currentStep >= 3,
        ),
        Step(
          title: const Text('Duração das Sessões'),
          content: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sessionLevels.map((level) {
                  final isSelected = _selectedSessionLevel == level['level'];
                  return Expanded(
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      elevation: isSelected ? 8 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isSelected
                            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                            : BorderSide.none,
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedSessionLevel = level['level'];
                            _manualSessionDurationController.clear();
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(level['icon'], size: 32, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade700),
                              const SizedBox(height: 8),
                              Text(
                                level['level'],
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                level['duration'],
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: _selectedSessionLevel == 'Manual' ? 8 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: _selectedSessionLevel == 'Manual'
                      ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                      : BorderSide.none,
                ),
                child: ListTile(
                  leading: Icon(Icons.edit, color: _selectedSessionLevel == 'Manual' ? Theme.of(context).colorScheme.primary : Colors.grey.shade700),
                  title: Text('Manual', style: TextStyle(fontWeight: FontWeight.bold, color: _selectedSessionLevel == 'Manual' ? Theme.of(context).colorScheme.primary : null)),
                  subtitle: Text('Digite a duração em minutos'),
                  onTap: () {
                    setState(() {
                      _selectedSessionLevel = 'Manual';
                    });
                  },
                ),
              ),
              if (_selectedSessionLevel == 'Manual')
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextField(
                    controller: _manualSessionDurationController,
                    decoration: const InputDecoration(
                      labelText: 'Duração da sessão (minutos)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
            ],
          ),
          isActive: _currentStep >= 4,
        ),
        Step(
          title: const Text('Dias de Estudo'),
          content: Wrap(
            spacing: 8.0,
            children: _daysOfWeek.map((day) {
              return FilterChip(
                label: Text(day.substring(0, 3)),
                selected: _selectedDays.contains(day),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedDays.add(day);
                    } else {
                      _selectedDays.remove(day);
                    }
                  });
                },
              );
            }).toList(),
          ),
          isActive: _currentStep >= 5,
        ),
        Step(
          title: const Text('Gerar Ciclo'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Resumo do seu Planejamento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Text('Matérias: ${_selectedSubjects.length}'),
              Text('Carga Horária: ${_selectedWorkloadLevel ?? ''}'),
              Text('Meta de Questões: ${_selectedQuestionsLevel ?? ''}'),
              Text('Duração da Sessão: ${_selectedSessionLevel ?? ''}'),
              Text('Dias de Estudo: ${_selectedDays.length}'),
            ],
          ),
          isActive: _currentStep >= 6,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AlertDialog(
      title: Text(_isManualMode == null ? 'Criar Novo Ciclo' : _isManualMode! ? 'Criação Manual do Ciclo' : 'Modo Guiado'),
      contentPadding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 0.0),
      content: SizedBox(
        width: screenWidth * 0.95,
        height: screenHeight * 0.75,
        child: ScaffoldMessenger(
          key: _scaffoldMessengerKey,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Consumer<AllSubjectsProvider>(
              builder: (context, allSubjectsProvider, child) {
              if (_isManualMode == null) {
                return _buildModeSelection();
              }
              if (_isManualMode!) {
                return _buildManualMode(allSubjectsProvider);
              }
              // Guided Mode Stepper
              return Stepper(
                key: _stepperKey,
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < _getSteps(context, allSubjectsProvider).length - 1) {
                    setState(() { _currentStep += 1; });
                  } else {
                    _saveGuidedCycle(allSubjectsProvider);
                  }
                },
                onStepCancel: () {
                  setState(() {
                    if (_currentStep > 0) {
                      _currentStep -= 1;
                    } else {
                      _isManualMode = null;
                    }
                  });
                },
                steps: _getSteps(context, allSubjectsProvider),
              );
            },
          ),
        ),
       ), // Closes ScaffoldMessenger
      ),
      actions: _isManualMode == true ? [
        TextButton(
          onPressed: () => setState(() { _isManualMode = null; }),
          child: const Text('Voltar'),
        ),
        ElevatedButton(
          onPressed: _saveManualCycle,
          child: const Text('Salvar Ciclo'),
        ),
      ] : null,
    );
  }

  // Métodos de construção da UI e lógica de salvamento adicionados

  Widget _buildModeSelection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Como você prefere criar seu ciclo?',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildModeCard(
                context: context,
                title: 'Modo Guiado',
                description: 'Responda algumas perguntas e nós montamos o ciclo para você.',
                icon: Icons.auto_awesome,
                onTap: () => setState(() { _isManualMode = false; _currentStep = 0; }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModeCard(
                context: context,
                title: 'Modo Manual',
                description: 'Adicione sessões de estudo uma a uma, com total controle.',
                icon: Icons.build,
                onTap: () => setState(() { _isManualMode = true; _currentStep = 0; _manualDurationController.text = '60'; }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualMode(AllSubjectsProvider allSubjectsProvider) {
    final totalHours = _manualStudySessions.fold<int>(0, (sum, session) => sum + session.duration) / 60;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Adicione sessões de estudo uma a uma para montar seu ciclo.'),
            const SizedBox(height: 16),
            const Text('Matéria', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<Subject>(
              isExpanded: true,
              value: _manualSelectedSubject,
              hint: const Text('Selecione uma matéria'),
              onChanged: (Subject? newValue) => setState(() => _manualSelectedSubject = newValue),
              items: allSubjectsProvider.uniqueSubjectsByName.map<DropdownMenuItem<Subject>>((subject) {
                return DropdownMenuItem<Subject>(
                  value: subject,
                  child: Text(subject.subject, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Duração (min)', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _manualDurationController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_manualSelectedSubject != null && _manualDurationController.text.isNotEmpty) {
                    final subject = _manualSelectedSubject!;
                    setState(() {
                      _manualStudySessions.add(
                        StudySession(
                          id: DateTime.now().toIso8601String() + _manualStudySessions.length.toString(),
                          subject: subject.subject,
                          duration: int.parse(_manualDurationController.text),
                          color: subject.color,
                          subjectId: subject.id,
                        ),
                      );
                    });
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Sessão'),
              ),
            ),
            const Divider(height: 32),
            Text('Sessões Adicionadas (${_manualStudySessions.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
            _manualStudySessions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: Text('Nenhuma sessão adicionada ainda.')),
                  )
                : SizedBox(
                    height: 150,
                    child: ListView.builder(
                      itemCount: _manualStudySessions.length,
                      itemBuilder: (context, index) {
                        final session = _manualStudySessions[index];
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: Color(int.parse(session.color.replaceFirst('#', '0xFF')))),
                          title: Text(session.subject),
                          subtitle: Text('${session.duration} min'),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => setState(() => _manualStudySessions.removeAt(index)),
                          ),
                        );
                      },
                    ),
                  ),
            const Divider(height: 32),
            Row(
              children: [
                const Text('Horas Semanais', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${totalHours.toStringAsFixed(1)}h', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Meta de Questões', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _manualQuestionsGoalController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text('Dias de Estudo', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 4.0,
              runSpacing: 0.0,
              children: _daysOfWeek.map((day) {
                return FilterChip(
                  label: Text(day.substring(0, 1)),
                  selected: _selectedDays.contains(day),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(day);
                      } else {
                        _selectedDays.remove(day);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _saveGuidedCycle(AllSubjectsProvider allSubjectsProvider) {
    if ((_selectedWorkloadLevel == null || (_selectedWorkloadLevel == 'Manual' && _manualWorkloadController.text.isEmpty)) ||
        _selectedQuestionsLevel == null ||
        _selectedSessionLevel == null ||
        _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return;
    }

    final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
    final selectedSubjectsData = allSubjectsProvider.subjects
        .where((s) => _selectedSubjects.contains(s.id))
        .toList();

    final int workloadValue;
    if (_selectedWorkloadLevel == 'Manual') {
      workloadValue = int.tryParse(_manualWorkloadController.text) ?? 0;
    } else {
      final workload = workloadLevels.firstWhere((l) => l['level'] == _selectedWorkloadLevel);
      workloadValue = workload['value'];
    }

    final int questionsValue;
    if (_selectedQuestionsLevel == 'Manual') {
      questionsValue = int.tryParse(_manualGuidedQuestionsGoalController.text) ?? 0;
    } else {
      final questions = questionsLevels.firstWhere((l) => l['level'] == _selectedQuestionsLevel);
      questionsValue = questions['value'];
    }

    final int minSession;
    final int maxSession;
    if (_selectedSessionLevel == 'Manual') {
      final manualDuration = int.tryParse(_manualSessionDurationController.text) ?? 60;
      minSession = manualDuration;
      maxSession = manualDuration;
    } else {
      final session = sessionLevels.firstWhere((l) => l['level'] == _selectedSessionLevel);
      minSession = session['min'];
      maxSession = session['max'];
    }

    planningProvider.setStudyHours(workloadValue.toString());
    planningProvider.setWeeklyQuestionsGoal(questionsValue.toString());
    planningProvider.setStudyDays(_selectedDays.toList());

    planningProvider.generateStudyCycle(
      studyHours: workloadValue,
      minSession: minSession,
      maxSession: maxSession,
      subjectSettings: _subjectSettings,
      subjects: selectedSubjectsData,
      weeklyQuestionsGoal: questionsValue.toString(),
    );
    Navigator.of(context).pop();
  }

  void _saveManualCycle() {
    if (_manualStudySessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos uma sessão de estudo.')),
      );
      return;
    }

    final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
    planningProvider.setManualStudyCycle(_manualStudySessions);
    planningProvider.setWeeklyQuestionsGoal(_manualQuestionsGoalController.text);
    planningProvider.setStudyDays(_selectedDays.toList());
    final totalMinutes = _manualStudySessions.fold<int>(0, (sum, session) => sum + session.duration);
    planningProvider.setStudyHours((totalMinutes / 60).toStringAsFixed(1));

    Navigator.of(context).pop();
  }
}
