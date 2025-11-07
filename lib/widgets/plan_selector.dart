import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ouroboros_mobile/providers/plans_provider.dart';
import 'package:ouroboros_mobile/providers/active_plan_provider.dart';

class PlanSelector extends StatelessWidget {
  const PlanSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlansProvider, ActivePlanProvider>(
      builder: (context, plansProvider, activePlanProvider, child) {
        String? currentPlanId = activePlanProvider.activePlanId;
        if (currentPlanId != null && !plansProvider.plans.any((p) => p.id == currentPlanId)) {
          currentPlanId = null;
        }

        return DropdownButton<String>(
          value: currentPlanId,
          hint: const Text('Selecione um Plano'),
          isExpanded: true,
          onChanged: (String? newPlanId) {
            if (newPlanId != null) {
              activePlanProvider.setActivePlan(newPlanId);
            }
          },
          items: plansProvider.plans.map<DropdownMenuItem<String>>((plan) {
            return DropdownMenuItem<String>(
              value: plan.id,
              child: Text(plan.name, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
        );
      },
    );
  }
}
