import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_scaffold.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cooking_plan.dart';
import '../../models/recipe.dart';
import '../cooking/start_cooking.dart';
import 'plan_widgets.dart';

final _planProvider =
    FutureProvider.autoDispose.family<(CookingPlan, Recipe, bool)?, String>((ref, recipeId) async {
  final repo = ref.watch(recipeRepositoryProvider);
  final plan = await repo.latestApprovedPlan(recipeId);
  final row = await repo.getRecipe(recipeId);
  if (plan == null || row == null) return null;
  return (plan.plan, row.recipe, row.planStale);
});

/// Read-only view of the approved plan (corrections happen on the edit screen).
class PlanReviewScreen extends ConsumerWidget {
  const PlanReviewScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(_planProvider(recipeId));

    return AppScaffold(
      title: l10n.viewPlan,
      body: switch (data) {
        AsyncData(value: (final plan, final recipe, final stale)?) =>
          _PlanView(plan: plan, recipe: recipe, stale: stale, recipeId: recipeId),
        AsyncData() => Center(child: Text(l10n.noPlan)),
        AsyncError() => Center(child: Text(l10n.errorGeneric)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _PlanView extends ConsumerWidget {
  const _PlanView({required this.plan, required this.recipe, required this.stale, required this.recipeId});

  final CookingPlan plan;
  final Recipe recipe;
  final bool stale;
  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (plan.advanceNoticeHe case final notice?)
          Card(child: ListTile(leading: const Icon(Icons.schedule), title: Text(notice))),
        if (plan.prepTasks.isNotEmpty) ...[
          SectionTitle(l10n.prepTasks),
          for (final p in plan.prepTasks) PrepTaskCard(prep: p),
        ],
        SectionTitle(l10n.steps),
        for (final step in plan.steps) PlanStepCard(step: step, plan: plan, recipe: recipe),
        const SizedBox(height: 16),
        if (!stale)
          FilledButton.icon(
            onPressed: () => startCooking(context, ref, recipeId),
            icon: const Icon(Icons.play_arrow),
            label: Text(l10n.startCooking),
          ),
      ],
    );
  }
}
