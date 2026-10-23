import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/estimate_badge.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cooking_plan.dart';
import '../cooking/start_cooking.dart';

final _planProvider = FutureProvider.autoDispose.family<CookingPlan?, String>((ref, recipeId) async {
  final row = await ref.watch(recipeRepositoryProvider).latestApprovedPlan(recipeId);
  return row?.plan;
});

/// Read-only review of the approved plan (editing comes with AI plans in Phase 2).
class PlanReviewScreen extends ConsumerWidget {
  const PlanReviewScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final plan = ref.watch(_planProvider(recipeId));

    return AppScaffold(
      title: l10n.viewPlan,
      body: switch (plan) {
        AsyncData(value: final p?) => _PlanView(plan: p, recipeId: recipeId),
        AsyncData() => Center(child: Text(l10n.noPlan)),
        AsyncError() => Center(child: Text(l10n.errorGeneric)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _PlanView extends ConsumerWidget {
  const _PlanView({required this.plan, required this.recipeId});

  final CookingPlan plan;
  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stepNumber = {for (var i = 0; i < plan.steps.length; i++) plan.steps[i].id: i + 1};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (plan.prepTasks.isNotEmpty) ...[
          SectionTitle(l10n.prepTasks),
          for (final p in plan.prepTasks)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.textHe, style: theme.textTheme.titleSmall),
                    if (p.leadMinutes case final m?)
                      ProvenancedText(l10n.leadTime(m.value), m.provenance, note: m.noteHe),
                    if (p.timer case final t?)
                      ProvenancedText(l10n.timerLabel(t.labelHe, formatSeconds(t.seconds)), t.provenance, note: t.noteHe),
                  ],
                ),
              ),
            ),
        ],
        SectionTitle(l10n.steps),
        for (final step in plan.steps)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text('${l10n.stepNumber(stepNumber[step.id]!)} · ${step.title}', style: theme.textTheme.titleSmall),
                  Text(step.instructionHe),
                  if (step.temperature case final t?)
                    ProvenancedText(l10n.temperatureLabel(t.value), t.provenance),
                  for (final t in step.timers)
                    ProvenancedText(l10n.timerLabel(t.labelHe, formatSeconds(t.seconds)), t.provenance, note: t.noteHe),
                  if (step.dependsOn.isNotEmpty)
                    Text(
                      l10n.afterSteps([for (final d in step.dependsOn) l10n.stepNumber(stepNumber[d] ?? 0)].join(', ')),
                      style: theme.textTheme.bodySmall,
                    ),
                  if (step.parallelOk) Text(l10n.canRunInParallel, style: theme.textTheme.bodySmall),
                  Text(l10n.planActions, style: theme.textTheme.bodySmall),
                  Wrap(
                    spacing: 6,
                    children: [for (final a in step.actions) Chip(label: Text(a.labelHe), visualDensity: VisualDensity.compact)],
                  ),
                  for (final w in step.warningsHe)
                    Text('⚠️ $w', style: TextStyle(color: theme.colorScheme.error)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => startCooking(context, ref, recipeId),
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.startCooking),
        ),
      ],
    );
  }
}
