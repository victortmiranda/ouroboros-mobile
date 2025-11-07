
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ouroboros_mobile/providers/plans_provider.dart';
import 'package:ouroboros_mobile/providers/planning_provider.dart'; // Import PlanningProvider

class CreatePlanModal extends StatefulWidget {
  const CreatePlanModal({super.key});

  @override
  State<CreatePlanModal> createState() => _CreatePlanModalState();
}

class _CreatePlanModalState extends State<CreatePlanModal> {
  final _formKey = GlobalKey<FormState>();
  String _planName = '';
  String _cargo = '';
  String _edital = '';
  String _banca = '';
  String _observations = '';
  String _studyHours = '0'; // State variable for study hours
  String _weeklyQuestionsGoal = '0'; // State variable for weekly questions goal

  Future<void> _savePlan() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final plansProvider = Provider.of<PlansProvider>(context, listen: false);
      final planningProvider = Provider.of<PlanningProvider>(context, listen: false); // Get PlanningProvider

      // Show a loading indicator while saving
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      try {
        // Save the plan details
        final newPlan = await plansProvider.addPlan(
          name: _planName,
          cargo: _cargo,
          edital: _edital,
          banca: _banca,
          observations: _observations,
        );

        // Update PlanningProvider with the new plan ID first
        planningProvider.updateForPlan(newPlan.id);

        // Now, set the study hours and weekly questions goal for the new plan
        planningProvider.setStudyHours(_studyHours);
        planningProvider.setWeeklyQuestionsGoal(_weeklyQuestionsGoal);

        // Pop the loading indicator
        Navigator.of(context, rootNavigator: true).pop();
        // Pop the create plan modal
        Navigator.of(context).pop();
      } catch (e) {
        // Pop the loading indicator
        Navigator.of(context, rootNavigator: true).pop();
        // Show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar o plano: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seu Plano'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: Image
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[300],
                      child: const Icon(Icons.camera_alt, color: Colors.grey, size: 48),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Implement image picking
                      },
                      child: const Text('Alterar Imagem'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right side: Form
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'NOME'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'O nome do plano não pode estar vazio.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _planName = value!;
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'CARGO (Opcional)'),
                      onSaved: (value) {
                        _cargo = value ?? '';
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'EDITAL (Opcional)'),
                      onSaved: (value) {
                        _edital = value ?? '';
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'BANCA (Opcional)'),
                      onSaved: (value) {
                        _banca = value ?? '';
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'OBSERVAÇÕES (Opcional)'),
                      maxLines: 3,
                      onSaved: (value) {
                        _observations = value ?? '';
                      },
                    ),
                    // New fields for weekly goals
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'HORAS DE ESTUDO POR SEMANA'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira um valor.';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Por favor, insira um número válido.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _studyHours = value ?? '0';
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'QUESTÕES POR SEMANA'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira um valor.';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Por favor, insira um número válido.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _weeklyQuestionsGoal = value ?? '0';
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _savePlan,
          child: const Text('Avançar'),
        ),
      ],
    );
  }
}
