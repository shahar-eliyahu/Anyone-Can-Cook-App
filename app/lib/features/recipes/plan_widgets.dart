import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/widgets/estimate_badge.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cooking_plan.dart';
import '../../models/provenance.dart';
import '../../models/recipe.dart';

/// "45:00" or "45:00–1:00:00" for a range timer.
String timerDuration(PlanTimer t) =>
    t.maxSeconds == null ? formatSeconds(t.seconds) : '${formatSeconds(t.seconds)}–${formatSeconds(t.maxSeconds!)}';

/// A value with an optional edit button (shown only when [onEdit] is set).
class EditableRow extends StatelessWidget {
  const EditableRow({super.key, required this.child, this.onEdit, this.editLabel});

  final Widget child;
  final VoidCallback? onEdit;
  final String? editLabel;

  @override
  Widget build(BuildContext context) => onEdit == null
      ? child
      : Row(
          children: [
            Expanded(child: child),
            IconButton(
              tooltip: editLabel,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
            ),
          ],
        );
}

class TimerDetails extends StatelessWidget {
  const TimerDetails({super.key, required this.timer, this.onEdit});

  final PlanTimer timer;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final small = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditableRow(
          onEdit: onEdit,
          editLabel: l10n.editTimer,
          child: ProvenancedText(l10n.timerLabel(timer.labelHe, timerDuration(timer)), timer.provenance,
              note: timer.noteHe),
        ),
        if (timer.waitInfoHe case final w?) Text(w, style: small),
        if (timer.checkCueHe case final c?) Text('🔍 $c', style: small),
      ],
    );
  }
}

/// One plan step: instruction, amounts used, temperature, timers, cues, warnings,
/// and the original recipe sentences it came from. Editable when callbacks are given.
class PlanStepCard extends StatelessWidget {
  const PlanStepCard({
    super.key,
    required this.step,
    required this.plan,
    required this.recipe,
    this.onEditInstruction,
    this.onEditTemperature,
    this.onEditTimer,
  });

  final PlanStep step;
  final CookingPlan plan;
  final Recipe recipe;
  final VoidCallback? onEditInstruction;
  final VoidCallback? onEditTemperature;
  final void Function(PlanTimer)? onEditTimer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final number = {for (var i = 0; i < plan.steps.length; i++) plan.steps[i].id: i + 1};
    final ingredients = {for (final i in recipe.ingredients) i.id: i};
    final sources = {for (final s in recipe.sourceSteps) s.id: s.text};
    final excerpt = [for (final r in step.sourceRefs) ?sources[r]].join(' ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text('${l10n.stepNumber(number[step.id]!)} · ${step.title}', style: theme.textTheme.titleSmall),
            EditableRow(onEdit: onEditInstruction, editLabel: l10n.editStep, child: Text(step.instructionHe)),
            for (final u in step.ingredientUses)
              if (ingredients[u.ingredientId] case final i?)
                ProvenancedText(
                  '• ${i.name}${u.quantity == null ? '' : ' — ${u.quantity!.display}'}',
                  u.quantity?.provenance ?? i.quantity?.provenance ?? Provenance.original,
                  note: u.noteHe,
                ),
            if (step.temperature case final t?)
              EditableRow(
                onEdit: onEditTemperature,
                editLabel: l10n.editTemperature,
                child: ProvenancedText(l10n.temperatureLabel(t.value), t.provenance),
              ),
            for (final t in step.timers)
              TimerDetails(timer: t, onEdit: onEditTimer == null ? null : () => onEditTimer!(t)),
            if (step.donenessCueHe case final c?) Text('🔍 $c', style: theme.textTheme.bodySmall),
            if (step.dependsOn.isNotEmpty)
              Text(
                l10n.afterSteps([for (final d in step.dependsOn) l10n.stepNumber(number[d] ?? 0)].join(', ')),
                style: theme.textTheme.bodySmall,
              ),
            if (step.parallelOk) Text(l10n.canRunInParallel, style: theme.textTheme.bodySmall),
            Wrap(
              spacing: 6,
              children: [
                for (final a in step.actions) Chip(label: Text(a.labelHe), visualDensity: VisualDensity.compact),
              ],
            ),
            for (final w in step.warningsHe) Text('⚠️ $w', style: TextStyle(color: theme.colorScheme.error)),
            if (excerpt.isNotEmpty)
              Text(l10n.reviewFromSource(excerpt),
                  style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}

class PrepTaskCard extends StatelessWidget {
  const PrepTaskCard({super.key, required this.prep, this.onEditTimer});

  final PrepTask prep;
  final void Function(PlanTimer)? onEditTimer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prep.textHe, style: Theme.of(context).textTheme.titleSmall),
            if (prep.leadMinutes case final m?) ProvenancedText(l10n.leadTime(m.value), m.provenance, note: m.noteHe),
            if (prep.timer case final t?)
              TimerDetails(timer: t, onEdit: onEditTimer == null ? null : () => onEditTimer!(t)),
          ],
        ),
      ),
    );
  }
}
