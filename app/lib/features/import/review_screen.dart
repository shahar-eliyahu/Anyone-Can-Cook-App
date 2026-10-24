import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/estimate_badge.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cooking_plan.dart';
import '../../models/provenance.dart';
import '../../models/recipe.dart';
import '../../models/recipe_analysis.dart';
import '../cooking/engine/plan_validator.dart';
import '../recipes/plan_widgets.dart';
import 'import_errors.dart';
import 'import_service.dart';
import 'plan_edits.dart';
import '../prepare/preparation_service.dart';

/// Review and correct a recipe and its plan before approving it: a new import
/// (a draft) or a saved recipe being edited ([editing]). Every edit is saved
/// at once; edits the plan can't absorb mark it out of date, and an
/// out-of-date plan can't be approved or cooked until it is regenerated or re-checked.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.recipeId, this.editing = false});

  final String recipeId;
  final bool editing;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  RecipeRow? _row;
  RecipeAnalysis? _analysis;
  CookingPlan? _plan;
  bool _loaded = false;
  bool _stale = false;
  bool _checked = false;
  bool _busy = false;
  String? _error;

  RecipeRepository get _repo => ref.read(recipeRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final row = await _repo.getRecipe(widget.recipeId);
    final planRow = row == null ? null : await _repo.reviewPlan(widget.recipeId);
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _row = row;
      _stale = row?.planStale ?? false;
      _plan = planRow?.plan;
      _analysis = row == null
          ? null
          : row.analysis ??
              RecipeAnalysis(
                isRecipe: true,
                source: const RecipeSourceInfo(type: SourceType.sample),
                sourceText: row.sourceText ?? '',
                recipe: row.recipe,
              );
    });
  }

  Recipe get _recipe => _analysis!.recipe!;

  Future<void> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = importErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _applyRecipeEdit(RecipeEdit edit) => _run(() async {
        final analysis = _analysis!.copyWith(recipe: edit.recipe);
        await _repo.updateAnalysis(widget.recipeId, analysis, planStale: edit.outdated ? true : null);
        await _repo.saveDraftPlan(widget.recipeId, edit.plan);
        await ref.read(preparationServiceProvider).lockAfterAdvancedEdit(widget.recipeId);
        setState(() {
          _analysis = analysis;
          _plan = edit.plan;
          if (edit.outdated) _stale = true;
          _checked = false;
        });
      });

  Future<void> _applyPlanEdit(CookingPlan plan) => _run(() async {
        await _repo.saveDraftPlan(widget.recipeId, plan);
        await ref.read(preparationServiceProvider).lockAfterAdvancedEdit(widget.recipeId);
        setState(() {
          _plan = plan;
          _checked = false;
        });
      });

  /// One /plan call from the stored (corrected) recipe; no new analysis.
  Future<void> _regenerate() => _run(() async {
        await ref.read(importServiceProvider).generatePlan(widget.recipeId);
        await ref.read(preparationServiceProvider).lockAfterAdvancedEdit(widget.recipeId);
        await _load();
        setState(() => _checked = false);
      });

  Future<void> _confirmStillCorrect() => _run(() async {
        await _repo.setPlanStale(widget.recipeId, false);
        setState(() => _stale = false);
      });

  Future<void> _approve() => _run(() async {
        final problems = validatePlan(_plan!, recipe: _recipe);
        if (problems.isNotEmpty) throw StateError(problems.join('; '));
        await ref.read(importServiceProvider).approve(widget.recipeId, _plan!, _analysis!);
        if (mounted) context.go('/recipes/${widget.recipeId}');
      });

  Future<void> _discard() => _run(() async {
        await ref.read(importServiceProvider).discard(widget.recipeId);
        if (mounted) context.go('/');
      });

  // ---- edit dialogs ---------------------------------------------------------

  Future<List<String>?> _ask(String title, List<(String label, String initial, TextInputType type)> fields) {
    final l10n = AppLocalizations.of(context);
    final controllers = [for (final f in fields) TextEditingController(text: f.$2)];
    return showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              for (var i = 0; i < fields.length; i++)
                TextField(
                  controller: controllers[i],
                  keyboardType: fields[i].$3,
                  maxLines: fields[i].$3 == TextInputType.multiline ? null : 1,
                  decoration: InputDecoration(labelText: fields[i].$1, border: const OutlineInputBorder()),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, [for (final c in controllers) c.text]),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _editIngredient(Ingredient i) async {
    final l10n = AppLocalizations.of(context);
    final r = await _ask(l10n.editIngredient, [
      (l10n.editName, i.name, TextInputType.text),
      (l10n.editAmount, i.quantity?.display ?? '', TextInputType.text),
    ]);
    if (r == null) return;
    await _applyRecipeEdit(editIngredient(_recipe, _plan!, i.id, name: r[0], amountDisplay: r[1]));
  }

  Future<void> _editSourceStep(SourceStep s) async {
    final l10n = AppLocalizations.of(context);
    final r = await _ask(l10n.editStep, [(l10n.editStep, s.text, TextInputType.multiline)]);
    if (r == null || r[0].trim() == s.text.trim() || r[0].trim().isEmpty) return;
    await _applyRecipeEdit(editSourceStep(_recipe, _plan!, s.id, r[0]));
  }

  Future<void> _editInstruction(PlanStep step) async {
    final l10n = AppLocalizations.of(context);
    final r = await _ask(l10n.editStep, [(l10n.editStep, step.instructionHe, TextInputType.multiline)]);
    if (r == null || r[0].trim().isEmpty) return;
    await _applyPlanEdit(editStepInstruction(_plan!, step.id, r[0]));
  }

  Future<void> _editTimer(PlanTimer t) async {
    final l10n = AppLocalizations.of(context);
    const number = TextInputType.number;
    String minutes(int s) => (s / 60).round().toString();
    final r = await _ask('${l10n.editTimer}: ${t.labelHe}', [
      (l10n.editTimerMinutes, minutes(t.seconds), number),
      (l10n.editTimerMaxMinutes, t.maxSeconds == null ? '' : minutes(t.maxSeconds!), number),
    ]);
    final from = int.tryParse(r?[0].trim() ?? '');
    if (r == null || from == null || from <= 0) return;
    final to = int.tryParse(r[1].trim());
    await _applyPlanEdit(editTimer(_plan!, t.id, seconds: from * 60, maxSeconds: to == null ? null : to * 60));
  }

  Future<void> _editTemperature(PlanStep step) async {
    final l10n = AppLocalizations.of(context);
    final r = await _ask(l10n.editTemperature, [
      (l10n.editTemperature, step.temperature?.value.toString() ?? '', TextInputType.number),
    ]);
    final value = int.tryParse(r?[0].trim() ?? '');
    if (value == null || value <= 0) return;
    await _applyPlanEdit(editTemperature(_plan!, step.id, value));
  }

  // ---- build ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = widget.editing ? l10n.editRecipe : l10n.reviewTitle;
    if (!_loaded) {
      return AppScaffold(title: title, body: const Center(child: CircularProgressIndicator()));
    }
    if (_row == null || _analysis?.recipe == null) {
      return AppScaffold(title: title, body: Center(child: Text(l10n.recipeNotFound)));
    }
    return AppScaffold(title: title, body: _body(context));
  }

  Widget _body(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final row = _row!;
    final recipe = _recipe;
    final plan = _plan;
    final review = row.planReview;
    final values = plan == null ? const <ReviewValue>[] : reviewValues(recipe, plan);
    final stepWarnings = plan?.steps.any((s) => s.warningsHe.isNotEmpty) ?? false;
    final photo = row.sourceImagePath;
    final fromPhoto = _analysis!.source.type == SourceType.image;
    final needsCheck = values.isNotEmpty ||
        review.warningsHe.isNotEmpty ||
        review.limitationsHe.isNotEmpty ||
        stepWarnings ||
        fromPhoto;
    final canApprove = plan != null && !_stale && !_busy && (!needsCheck || _checked);
    final small = theme.textTheme.bodySmall;

    Widget notice(String text, {bool error = false}) => Card(
          color: error ? theme.colorScheme.errorContainer : theme.colorScheme.secondaryContainer,
          child: Padding(padding: const EdgeInsets.all(12), child: Text(text)),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(recipe.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(l10n.reviewIntro),
        if (photo != null && File(photo).existsSync()) ...[
          const SizedBox(height: 12),
          Image.file(File(photo), height: 220, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink()),
        ],
        if (fromPhoto) notice(l10n.reviewPhotoCheck),
        if (_stale)
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(l10n.reviewOutdatedTitle, style: theme.textTheme.titleSmall),
                  Text(l10n.reviewOutdatedBody),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _busy || _analysis!.sourceText.isEmpty ? null : _regenerate,
                        child: Text(l10n.reviewRegenerate),
                      ),
                      OutlinedButton(
                        onPressed: _busy || plan == null ? null : _confirmStillCorrect,
                        child: Text(l10n.reviewStillCorrect),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (_busy) const LinearProgressIndicator(),
        if (_error case final e?) notice(e, error: true),
        if (review.warningsHe.isNotEmpty) ...[
          SectionTitle(l10n.reviewWarnings),
          for (final w in review.warningsHe) notice('⚠️ $w', error: true),
        ],
        if (review.limitationsHe.isNotEmpty) ...[
          SectionTitle(l10n.reviewLimitations),
          for (final w in review.limitationsHe) notice(w),
        ],
        SectionTitle(l10n.reviewEstimatesTitle),
        if (values.isEmpty) Text(l10n.reviewNoEstimates, style: small),
        for (final v in values) _valueTile(v, l10n),
        if (_analysis!.assumptionsHe.isNotEmpty) ...[
          Text(l10n.reviewAssumptions, style: theme.textTheme.titleSmall),
          for (final a in _analysis!.assumptionsHe) Text('• $a'),
        ],
        SectionTitle(l10n.ingredients),
        for (final i in recipe.ingredients)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(i.name),
            subtitle: i.quantity == null
                ? null
                : ProvenancedText(i.quantity!.display, i.quantity!.provenance, note: i.quantity!.noteHe),
            trailing: IconButton(
              tooltip: l10n.editIngredient,
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: _busy ? null : () => _editIngredient(i),
            ),
          ),
        if (plan != null) ...[
          if (plan.advanceNoticeHe case final n?) ...[const SizedBox(height: 8), notice('⏰ $n')],
          if (plan.prepTasks.isNotEmpty) ...[
            SectionTitle(l10n.prepTasks),
            for (final p in plan.prepTasks) PrepTaskCard(prep: p, onEditTimer: _busy ? null : _editTimer),
          ],
          SectionTitle(l10n.steps),
          for (final s in plan.steps)
            PlanStepCard(
              step: s,
              plan: plan,
              recipe: recipe,
              onEditInstruction: _busy ? null : () => _editInstruction(s),
              onEditTemperature: _busy ? null : () => _editTemperature(s),
              onEditTimer: _busy ? null : _editTimer,
            ),
        ] else
          notice(l10n.noPlan),
        SectionTitle(l10n.reviewOriginalSource),
        if (_analysis!.source.url case final url?)
          SelectableText([_analysis!.source.siteName, url].nonNulls.join(' · '), style: small),
        for (final s in recipe.sourceSteps)
          EditableRow(
            onEdit: _busy ? null : () => _editSourceStep(s),
            editLabel: l10n.editStep,
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(s.text)),
          ),
        if ([..._analysis!.sources, ...review.sources] case final sources when sources.isNotEmpty) ...[
          SectionTitle(l10n.reviewSources),
          for (final s in {for (final s in sources) s.id: s}.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SelectableText([s.title, ?s.url].join('\n'), style: small),
            ),
        ],
        const SizedBox(height: 16),
        if (needsCheck)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _checked,
            onChanged: _busy ? null : (v) => setState(() => _checked = v ?? false),
            title: Text(l10n.reviewSafetyCheckbox),
          ),
        FilledButton.icon(
          onPressed: canApprove ? _approve : null,
          icon: const Icon(Icons.check),
          label: Text(l10n.reviewApprove),
        ),
        if (row.isDraft) ...[
          const SizedBox(height: 8),
          TextButton(onPressed: _busy ? null : _discard, child: Text(l10n.reviewCancelImport)),
        ],
      ],
    );
  }

  Widget _valueTile(ReviewValue v, AppLocalizations l10n) {
    final (String text, VoidCallback? edit) = switch (v) {
      IngredientValue(:final ingredient) => (
          '${ingredient.name}: ${ingredient.quantity!.display}',
          () => _editIngredient(ingredient),
        ),
      TimerValue(:final timer) => (l10n.timerLabel(timer.labelHe, timerDuration(timer)), () => _editTimer(timer)),
      TemperatureValue(:final step) => (
          '${step.title}: ${l10n.temperatureLabel(step.temperature!.value)}',
          () => _editTemperature(step),
        ),
      LeadValue(:final prep) => ('${prep.textHe}: ${l10n.leadTime(prep.leadMinutes!.value)}', null),
    };
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: v.provenance == Provenance.inferred ? const Icon(Icons.help_outline) : const Icon(Icons.info_outline),
      title: Text(text),
      subtitle: v.note == null ? null : Text(v.note!),
      trailing: ProvenanceBadge(v.provenance),
      onTap: _busy ? null : edit,
    );
  }
}
