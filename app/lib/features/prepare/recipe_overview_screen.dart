import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/format.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cooking_plan.dart';
import '../../models/recipe.dart';
import '../../models/recipe_analysis.dart';
import '../cooking/start_cooking.dart';
import '../import/import_service.dart';
import 'plan_estimate.dart';
import 'preparation.dart';
import 'preparation_service.dart';
import 'substitution_sheet.dart';

// Keyed by the whole row (drift rows compare every field), so any change reloads.
final _viewProvider = FutureProvider.autoDispose.family<PrepView?, (RecipeRow, String?)>(
  (ref, key) => ref.watch(preparationServiceProvider).load(key.$1.id),
);

enum _Menu { rename, source, advanced, fullPlan, delete, discard }

/// The recipe before cooking (Phase 3A, docs/PLAN.md): a short overview, everything needed
/// (ingredients and equipment) with have / missing, solutions for missing items, and one
/// main action, "מתחילים לבשל". Used for new imports (drafts) and saved recipes alike;
/// the detailed review stays available as "עריכה מתקדמת".
class RecipeOverviewScreen extends ConsumerStatefulWidget {
  const RecipeOverviewScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<RecipeOverviewScreen> createState() => _RecipeOverviewScreenState();
}

class _RecipeOverviewScreenState extends ConsumerState<RecipeOverviewScreen> {
  bool _acknowledged = false;
  bool _busy = false;

  /// The last loaded view, shown while a change reloads (no spinner flash on every tap).
  PrepView? _last;

  PreparationService get _service => ref.read(preparationServiceProvider);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final row = ref.watch(recipeProvider(widget.recipeId));
    final activeId = ref.watch(activeSessionProvider).value?.id;
    final r = row.value;
    final loaded = r == null ? null : ref.watch(_viewProvider((r, activeId))).value;
    if (loaded != null) _last = loaded;
    final view = loaded ?? _last;

    if (row is AsyncData && r == null) {
      return AppScaffold(title: l10n.myRecipes, body: Center(child: Text(l10n.recipeNotFound)));
    }
    if (r == null || view == null) {
      return AppScaffold(title: l10n.myRecipes, body: const Center(child: CircularProgressIndicator()));
    }
    return _content(context, view);
  }

  Widget _content(BuildContext context, PrepView view) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final row = view.row;
    final recipe = view.recipe;
    final plan = view.plan;
    final prep = view.prep;
    final review = row.planReview;
    final estimate = plan == null ? null : estimatePlan(plan);
    final safetyEstimates = [
      for (final s in plan?.steps ?? const <PlanStep>[])
        if (s.actions.any((a) => a.completesStep && a.confirmPolicy == ConfirmPolicy.alwaysAsk) &&
            (s.timers.any((t) => t.provenance.isEstimate) || (s.temperature?.provenance.isEstimate ?? false)))
          s.title,
    ];
    final attention = [
      ...review.warningsHe,
      ...review.limitationsHe,
      for (final t in safetyEstimates) l10n.attentionSafetyEstimate(t),
      if (row.isDraft && view.analysis.source.type == SourceType.image) l10n.attentionPhoto,
    ];
    final needsAck = row.isDraft && (review.limitationsHe.isNotEmpty || safetyEstimates.isNotEmpty);
    final missing = [
      for (final i in recipe.ingredients)
        if (prep.statusOf(i.id) == ItemStatus.missing && prep.substitutionFor(ItemKind.ingredient, i.id) == null && !i.omitted)
          i.name,
      for (final e in recipe.equipment)
        if (prep.statusOf(e.id) == ItemStatus.missing && prep.substitutionFor(ItemKind.equipment, e.id) == null && !e.omitted)
          e.name,
    ];
    final canStart = plan != null && !row.planStale && (!needsAck || _acknowledged) && !_busy;

    return AppScaffold(
      title: row.displayTitle,
      actions: [
        if (!row.isDraft)
          IconButton(
            tooltip: row.isFavorite ? l10n.removeFavorite : l10n.addFavorite,
            icon: Icon(row.isFavorite ? Icons.star : Icons.star_outline),
            onPressed: () => ref.read(recipeRepositoryProvider).setFavorite(row.id, !row.isFavorite),
          ),
        PopupMenuButton<_Menu>(
          onSelected: (m) => _onMenu(m, view),
          itemBuilder: (context) => [
            if (!row.isDraft) PopupMenuItem(value: _Menu.rename, child: Text(l10n.rename)),
            PopupMenuItem(value: _Menu.source, child: Text(l10n.viewSource)),
            if (!view.cookingNow) PopupMenuItem(value: _Menu.advanced, child: Text(l10n.advancedEdit)),
            if (!row.isDraft) PopupMenuItem(value: _Menu.fullPlan, child: Text(l10n.fullPlan)),
            if (row.isDraft)
              PopupMenuItem(value: _Menu.discard, child: Text(l10n.draftCancel))
            else
              PopupMenuItem(value: _Menu.delete, child: Text(l10n.deleteRecipe)),
          ],
        ),
      ],
      bottomBar: view.cookingNow
          ? FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: () async {
                final router = GoRouter.of(context);
                final session = await ref.read(sessionRepositoryProvider).activeSession();
                if (session != null) router.go('/cook/${session.id}');
              },
              child: Text(l10n.continueCooking),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (missing.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(l10n.stillMissing(missing.join(', ')), style: theme.textTheme.bodySmall),
                  ),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: canStart ? () => _start(view) : null,
                  child: Text(l10n.startCookingCta),
                ),
                if (row.isDraft)
                  TextButton(onPressed: canStart ? () => _saveDraft(view) : null, child: Text(l10n.saveToMyRecipes)),
              ],
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(row.displayTitle, style: theme.textTheme.headlineSmall),
          if (recipe.description case final d?) Padding(padding: const EdgeInsets.only(top: 4), child: Text(d)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (recipe.servings case final s?)
                Chip(avatar: const Icon(Icons.restaurant, size: 18), label: Text('${_number(s.amount)} ${s.unit}')),
              if (estimate != null) ...[
                Chip(
                  avatar: const Icon(Icons.schedule, size: 18),
                  label: Text(l10n.overviewTotalTime(formatApproxDuration(estimate.totalMinutes, l10n))),
                ),
                Chip(
                  avatar: const Icon(Icons.back_hand_outlined, size: 18),
                  label: Text(l10n.overviewActiveTime(formatApproxDuration(estimate.activeMinutes, l10n))),
                ),
              ],
            ],
          ),
          if (row.planStale) _notice(context, l10n.planOutdated, error: true),
          if (view.cookingNow) _notice(context, l10n.cookingNowLocked),
          if (plan?.advanceNoticeHe case final n?) _notice(context, '🕒 $n'),
          if (attention.isNotEmpty)
            Card(
              color: theme.colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(l10n.attentionTitle, style: theme.textTheme.titleSmall),
                    for (final a in attention) Text('• $a'),
                    if (needsAck)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _acknowledged,
                        onChanged: (v) => setState(() => _acknowledged = v ?? false),
                        title: Text(l10n.attentionAck),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(l10n.overviewChecklistIntro),
          Row(
            children: [
              Expanded(child: SectionTitle(l10n.ingredients)),
              if (!view.cookingNow)
                TextButton(onPressed: () => _service.markAllHave(row.id), child: Text(l10n.haveAll)),
            ],
          ),
          for (final i in recipe.ingredients)
            _ItemRow(
              name: i.name,
              detail: i.omitted ? null : i.quantity?.display,
              optional: i.optional,
              substitutedFor: i.substitutedFor,
              omitted: i.omitted,
              status: prep.statusOf(i.id),
              substitution: prep.substitutionFor(ItemKind.ingredient, i.id),
              readOnly: view.cookingNow || plan == null,
              onStatus: (s) => _service.setStatus(row.id, i.id, s),
              onSolve: () => _solve(view, ItemKind.ingredient, i.id, i.name),
              onUndo: (sub) => _undo(row.id, sub),
            ),
          if (recipe.equipment.isNotEmpty) ...[
            SectionTitle(l10n.equipment),
            for (final e in recipe.equipment)
              _ItemRow(
                name: e.name,
                substitutedFor: e.substitutedFor,
                omitted: e.omitted,
                status: prep.statusOf(e.id),
                substitution: prep.substitutionFor(ItemKind.equipment, e.id),
                readOnly: view.cookingNow || plan == null,
                onStatus: (s) => _service.setStatus(row.id, e.id, s),
                onSolve: () => _solve(view, ItemKind.equipment, e.id, e.name),
                onUndo: (sub) => _undo(row.id, sub),
              ),
          ],
        ],
      ),
    );
  }

  Widget _notice(BuildContext context, String text, {bool error = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: error ? scheme.errorContainer : scheme.surfaceContainerHigh,
      child: Padding(padding: const EdgeInsets.all(12), child: Text(text)),
    );
  }

  Future<void> _solve(PrepView view, ItemKind kind, String id, String name) async {
    await _service.setStatus(view.row.id, id, ItemStatus.missing);
    if (!mounted) return;
    final fresh = await _service.load(view.row.id) ?? view;
    if (!mounted) return;
    await showSubstitutionSheet(context, view: fresh, kind: kind, targetId: id, name: name);
  }

  Future<void> _undo(String recipeId, Substitution sub) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _service.undo(recipeId, sub.id);
    } on SubstitutionFailed {
      messenger.showSnackBar(SnackBar(content: Text(l10n.substitutionFailed)));
    }
  }

  /// Drafts are approved when cooking starts (or when saved); then cooking starts as usual.
  Future<void> _start(PrepView view) async {
    setState(() => _busy = true);
    try {
      if (view.row.isDraft) await ref.read(importServiceProvider).approve(view.row.id, view.plan!, view.analysis);
      if (mounted) await startCooking(context, ref, view.row.id);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveDraft(PrepView view) async {
    setState(() => _busy = true);
    try {
      await ref.read(importServiceProvider).approve(view.row.id, view.plan!, view.analysis);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onMenu(_Menu m, PrepView view) async {
    final row = view.row;
    switch (m) {
      case _Menu.rename:
        await _rename(row);
      case _Menu.source:
        await _showSource(view.recipe);
      case _Menu.advanced:
        context.push(row.isDraft ? '/drafts/${row.id}/review' : '/recipes/${row.id}/edit');
      case _Menu.fullPlan:
        context.push('/recipes/${row.id}/plan');
      case _Menu.delete:
        await _delete(row);
      case _Menu.discard:
        final router = GoRouter.of(context);
        await ref.read(importServiceProvider).discard(row.id);
        router.go('/');
    }
  }

  Future<void> _rename(RecipeRow row) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: row.displayTitle);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renameTitle),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l10n.save)),
        ],
      ),
    );
    if (title != null) await ref.read(recipeRepositoryProvider).rename(row.id, title);
  }

  Future<void> _showSource(Recipe recipe) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            SectionTitle(AppLocalizations.of(context).viewSource),
            for (final s in recipe.sourceSteps)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(s.text)),
          ],
        ),
      );

  Future<void> _delete(RecipeRow row) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final repo = ref.read(recipeRepositoryProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.deleteRecipeConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final deletedAt = await repo.softDelete(row.id);
      if (router.canPop()) router.pop();
      messenger.showSnackBar(SnackBar(
        duration: const Duration(seconds: 5),
        content: Text(l10n.recipeDeleted),
        action: SnackBarAction(label: l10n.undo, onPressed: () => repo.restore(row.id, deletedAt)),
      ));
    } on RecipeHasActiveSessionException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.cannotDeleteActive)));
    }
  }
}

/// One ingredient or piece of equipment: have it (check), missing → a solution, or the
/// accepted substitution with its undo.
class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.name,
    required this.status,
    required this.readOnly,
    required this.onStatus,
    required this.onSolve,
    required this.onUndo,
    this.detail,
    this.optional = false,
    this.substitutedFor,
    this.omitted = false,
    this.substitution,
  });

  final String name;
  final String? detail;
  final bool optional;
  final String? substitutedFor;
  final bool omitted;
  final ItemStatus status;
  final Substitution? substitution;
  final bool readOnly;
  final void Function(ItemStatus) onStatus;
  final VoidCallback onSolve;
  final void Function(Substitution) onUndo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sub = substitution;
    final resolved = sub != null || omitted;
    final checked = status == ItemStatus.have || resolved;
    final missing = status == ItemStatus.missing && !resolved;

    final Widget? trailing = readOnly
        ? null
        : sub != null && !sub.locked
            ? TextButton(onPressed: () => onUndo(sub), child: Text(l10n.undoSubstitution))
            : resolved || status == ItemStatus.have
                ? null
                : missing
                    ? FilledButton.tonal(onPressed: onSolve, child: Text(l10n.findSolution))
                    : TextButton(onPressed: onSolve, child: Text(l10n.missingIt));

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: checked,
        onChanged: readOnly || resolved ? null : (v) => onStatus(v == true ? ItemStatus.have : ItemStatus.unknown),
      ),
      title: Text(
        optional ? '$name · ${l10n.optionalItem}' : name,
        style: omitted
            ? TextStyle(decoration: TextDecoration.lineThrough, color: theme.disabledColor)
            : missing
                ? TextStyle(color: theme.colorScheme.error)
                : null,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail case final d?) Text(d),
          if (substitutedFor case final o? when o != name) Text(l10n.insteadOf(o), style: theme.textTheme.bodySmall),
          if (omitted) Text(l10n.notUsed, style: theme.textTheme.bodySmall),
          if (sub?.effectsHe case final e? when !omitted) Text(e, style: theme.textTheme.bodySmall),
        ],
      ),
      trailing: trailing,
    );
  }
}

String _number(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
