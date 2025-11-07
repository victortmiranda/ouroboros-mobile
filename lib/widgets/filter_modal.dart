import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ouroboros_mobile/widgets/multi_select_dropdown.dart';
import 'package:ouroboros_mobile/models/data_models.dart';
import 'package:provider/provider.dart';
import 'package:ouroboros_mobile/providers/filter_provider.dart';

class FilterModal extends StatefulWidget {
  final List<String> availableCategories;
  final List<Subject> availableSubjects;
  final FilterScreen screen;

  const FilterModal({
    super.key,
    required this.availableCategories,
    required this.availableSubjects,
    required this.screen,
  });

  @override
  _FilterModalState createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late FilterProvider _filterProvider;

  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _minDurationController = TextEditingController();
  final TextEditingController _maxDurationController = TextEditingController();
  final TextEditingController _minPerformanceController = TextEditingController();
  final TextEditingController _maxPerformanceController = TextEditingController();
  List<String> _selectedCategories = [];
  List<String> _selectedSubjects = [];
  List<String> _selectedTopics = [];

  @override
  void initState() {
    super.initState();
    _filterProvider = Provider.of<FilterProvider>(context, listen: false);
    final filters = widget.screen == FilterScreen.history
        ? _filterProvider.historyFilters
        : _filterProvider.statsFilters;

    _startDate = filters['startDate'];
    _endDate = filters['endDate'];
    _minDurationController.text = filters['minDuration']?.toString() ?? '';
    _maxDurationController.text = filters['maxDuration']?.toString() ?? '';
    _minPerformanceController.text = filters['minPerformance']?.toString() ?? '';
    _maxPerformanceController.text = filters['maxPerformance']?.toString() ?? '';
    _selectedCategories = List.from(filters['categories'] ?? []);
    _selectedSubjects = List.from(filters['subjects'] ?? []);
    _selectedTopics = List.from(filters['topics'] ?? []);
  }

  List<String> get _topicsForSelectedSubjects {
    if (_selectedSubjects.isEmpty) {
      return [];
    }
    final topics = widget.availableSubjects
        .where((subject) => _selectedSubjects.contains(subject.subject))
        .expand((subject) => subject.topics.map((topic) => topic.topic_text))
        .toSet()
        .toList();
    topics.sort();
    return topics;
  }

  void _clearFilters() {
    _filterProvider.clearFilters(widget.screen);
    Navigator.of(context).pop();
  }

  void _applyFilters() {
    final filters = {
      'startDate': _startDate,
      'endDate': _endDate,
      'minDuration': int.tryParse(_minDurationController.text),
      'maxDuration': int.tryParse(_maxDurationController.text),
      'minPerformance': double.tryParse(_minPerformanceController.text),
      'maxPerformance': double.tryParse(_maxPerformanceController.text),
      'categories': _selectedCategories,
      'subjects': _selectedSubjects,
      'topics': _selectedTopics,
    };
    _filterProvider.setFilters(widget.screen, filters);
    Navigator.of(context).pop();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) {
        return Material(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Filtros Avançados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Content
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildSectionTitle('Período'),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Data de Início'),
                              child: Text(_startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : 'Selecione'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Data de Fim'),
                              child: Text(_endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : 'Selecione'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Duração (minutos)'),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_minDurationController, 'Mínimo')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(_maxDurationController, 'Máximo')),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Desempenho (%)'),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_minPerformanceController, 'Mínimo')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(_maxPerformanceController, 'Máximo')),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Categoria'),
                    Wrap(
                      spacing: 8.0,
                      children: widget.availableCategories.map((category) {
                        return FilterChip(
                          label: Text(category),
                          selected: _selectedCategories.contains(category),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(category);
                              } else {
                                _selectedCategories.remove(category);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Disciplina e Tópico'),
                    MultiSelectDropdown(
                      options: widget.availableSubjects.map((s) => s.subject).toList(),
                      selectedOptions: _selectedSubjects,
                      onSelectionChanged: (selected) {
                        setState(() {
                          _selectedSubjects = selected;
                          _selectedTopics.clear(); // Limpa os tópicos ao mudar a disciplina
                        });
                      },
                      placeholder: 'Selecione as Disciplinas',
                    ),
                    const SizedBox(height: 16),
                    MultiSelectDropdown(
                      options: _topicsForSelectedSubjects,
                      selectedOptions: _selectedTopics,
                      onSelectionChanged: (selected) {
                        setState(() {
                          _selectedTopics = selected;
                        });
                      },
                      placeholder: 'Selecione os Tópicos',
                    ),
                  ],
                ),
              ),
              // Footer
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Limpar'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _applyFilters,
                      child: const Text('Aplicar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}