import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/motion_widgets.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cooking_plan.dart';
import '../../models/recipe.dart';
import '../../models/recipe_analysis.dart';
import '../assistant/assistant_models.dart';
import '../assistant/conversation_store.dart';
import '../assistant/hands_free_choice.dart';
import '../assistant/remy_widgets.dart';
import '../catalog/builtin_catalog.dart';
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
    bool settled(ItemStatus st, bool omitted, bool substituted) => st == ItemStatus.have || omitted || substituted;
    final allReady = plan != null &&
        recipe.ingredients.every((i) => settled(prep.statusOf(i.id), i.omitted, prep.substitutionFor(ItemKind.ingredient, i.id) != null)) &&
        recipe.equipment.every((e) => settled(prep.statusOf(e.id), e.omitted, prep.substitutionFor(ItemKind.equipment, e.id) != null));
    // While this recipe is being cooked, Remy is the cooking session's (voice first, live state).
    final cookingId = view.cookingNow ? ref.watch(activeSessionProvider).value?.id : null;
    final remy = RemyButton(scope: cookingId != null ? RemyScope.session(cookingId) : RemyScope.recipe(row.id));

    return AppScaffold(
      title: row.displayTitle,
      actions: [
        if (!row.isDraft && !row.isBuiltin)
          IconButton(
            tooltip: row.isFavorite ? l10n.removeFavorite : l10n.addFavorite,
            icon: Icon(row.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded, color: row.isFavorite ? context.palette.woodLight : null),
            onPressed: () => ref.read(recipeRepositoryProvider).setFavorite(row.id, !row.isFavorite),
          ),
        PopupMenuButton<_Menu>(
          tooltip: l10n.overviewMore,
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (m) => _onMenu(m, view),
          itemBuilder: (context) => [
            // A built-in recipe is never changed itself: the cook saves their own copy to edit it.
            if (!row.isDraft && !row.isBuiltin) PopupMenuItem(value: _Menu.rename, child: Text(l10n.rename)),
            PopupMenuItem(value: _Menu.source, child: Text(l10n.viewSource)),
            if (!view.cookingNow && !row.isBuiltin) PopupMenuItem(value: _Menu.advanced, child: Text(l10n.advancedEdit)),
            if (!row.isDraft) PopupMenuItem(value: _Menu.fullPlan, child: Text(l10n.fullPlan)),
            if (row.isDraft)
              PopupMenuItem(value: _Menu.discard, child: Text(l10n.draftCancel))
            else if (!row.isBuiltin)
              PopupMenuItem(value: _Menu.delete, child: Text(l10n.deleteRecipe)),
          ],
        ),
      ],
      bottomBar: view.cookingNow
          ? Row(
              spacing: Space.m,
              children: [
                remy,
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                    onPressed: () async {
                      final router = GoRouter.of(context);
                      final session = await ref.read(sessionRepositoryProvider).activeSession();
                      if (session != null) router.go('/cook/${session.id}');
                    },
                    child: Text(l10n.continueCooking),
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (needsAck && !_acknowledged)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.s),
                    child: Text(l10n.attentionAckHint, style: theme.textTheme.bodySmall?.copyWith(color: context.palette.onTimerDoneContainer)),
                  ),
                if (missing.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.s),
                    child: Text(
                      l10n.stillMissing(missing.join(', ')),
                      style: theme.textTheme.bodySmall?.copyWith(color: context.palette.onTimerDoneContainer),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: Space.m,
                  children: [
                    remy,
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                        onPressed: canStart ? () => _start(view) : null,
                        icon: const Icon(Icons.local_fire_department_rounded),
                        label: Text(l10n.startCookingCta),
                      ),
                    ),
                  ],
                ),
                if (row.isDraft)
                  TextButton(onPressed: canStart ? () => _saveDraft(view) : null, child: Text(l10n.saveToMyRecipes)),
                if (row.isBuiltin) TextButton(onPressed: _busy ? null : () => _saveCopy(row), child: Text(l10n.saveToMyRecipes)),
              ],
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.xl),
        children: [
          Appear(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Space.s,
              children: [
                Text(row.displayTitle, style: theme.textTheme.headlineSmall),
                if (recipe.description case final d?)
                  Text(tidyHe(d), style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                Wrap(
                  spacing: Space.s,
                  runSpacing: Space.s,
                  children: [
                    if (row.isBuiltin) InfoPill(icon: Icons.menu_book_rounded, label: l10n.builtinLabel),
                    if (recipe.servings case final s?) InfoPill(icon: Icons.restaurant_rounded, label: '${_number(s.amount)} ${s.unit}'),
                    if (estimate != null) ...[
                      InfoPill(icon: Icons.schedule_rounded, label: l10n.overviewTotalTime(formatApproxDuration(estimate.totalMinutes, l10n))),
                      InfoPill(icon: Icons.back_hand_outlined, label: l10n.overviewActiveTime(formatApproxDuration(estimate.activeMinutes, l10n))),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.s),
          if (row.planStale) NoteBanner(l10n.planOutdated, kind: NoteKind.warning),
          if (view.cookingNow) NoteBanner(l10n.cookingNowLocked, icon: Icons.local_fire_department_outlined),
          if (plan?.advanceNoticeHe case final n?) NoteBanner(tidyHe(n), kind: NoteKind.tip, icon: Icons.schedule_rounded),
          if (attention.isNotEmpty)
            NoteBanner(
              '',
              kind: NoteKind.warning,
              title: l10n.attentionTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Space.xs,
                children: [
                  for (final a in attention) Text('• ${tidyHe(a)}'),
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
          SectionTitle(
            l10n.ingredients,
            trailing: view.cookingNow
                ? null
                : TextButton.icon(
                    onPressed: () => _service.markAllHave(row.id),
                    icon: const Icon(Icons.done_all_rounded),
                    label: Text(l10n.haveAll),
                  ),
          ),
          Text(l10n.overviewChecklistIntro, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: Space.s),
          Card(
            child: Column(
              children: [
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
              ],
            ),
          ),
          if (recipe.equipment.isNotEmpty) ...[
            SectionTitle(l10n.equipment),
            Card(
              child: Column(
                children: [
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
              ),
            ),
          ],
          AnimatedSwitcher(
            duration: Motion.of(context, Motion.medium),
            child: allReady && !view.cookingNow
                ? Padding(
                    key: const ValueKey('ready'),
                    padding: const EdgeInsets.only(top: Space.m),
                    child: NoteBanner(l10n.overviewReady, kind: NoteKind.success),
                  )
                : const SizedBox(key: ValueKey('not-ready'), width: double.infinity),
          ),
          // Optional and secondary: decided calmly here, not on every cooking step.
          if (!view.cookingNow) ...[
            const SizedBox(height: Space.l),
            const HandsFreeChoice(),
          ],
        ],
      ),
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

  /// A built-in recipe becomes the cook's own (with what they prepared); its copy opens.
  Future<void> _saveCopy(RecipeRow row) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _busy = true);
    try {
      final id = await ref.read(builtinRecipesProvider).copyToMyRecipes(row.id);
      router.pushReplacement('/recipes/$id');
      messenger.showSnackBar(SnackBar(content: Text(l10n.builtinSaved)));
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
      await forgetConversation(ref.read(settingsRepositoryProvider), row.id);
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
                    ? FilledButton.tonal(
                        style: FilledButton.styleFrom(minimumSize: const Size(48, 44)),
                        onPressed: onSolve,
                        child: Text(l10n.findSolution),
                      )
                    : TextButton(onPressed: onSolve, child: Text(l10n.missingIt));
    final canToggle = !readOnly && !resolved;

    return ListTile(
      onTap: canToggle
          ? () {
              HapticFeedback.selectionClick();
              onStatus(checked ? ItemStatus.unknown : ItemStatus.have);
            }
          : null,
      leading: _CheckCircle(
        checked: checked,
        missing: missing,
        onChanged: canToggle ? (v) => onStatus(v ? ItemStatus.have : ItemStatus.unknown) : null,
      ),
      title: Text(
        name,
        style: omitted
            ? TextStyle(decoration: TextDecoration.lineThrough, color: theme.colorScheme.onSurfaceVariant)
            : missing
                ? TextStyle(color: context.palette.onTimerDoneContainer, fontWeight: FontWeight.w700)
                : null,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail case final d?) Text(d),
          if (optional) Text(l10n.optionalItem, style: theme.textTheme.labelMedium?.copyWith(color: context.palette.wood)),
          if (substitutedFor case final o? when o != name) Text(l10n.insteadOf(o), style: theme.textTheme.bodySmall),
          if (omitted) Text(l10n.notUsed, style: theme.textTheme.bodySmall),
          if (sub?.effectsHe case final e? when !omitted) Text(tidyHe(e), style: theme.textTheme.bodySmall),
        ],
      ),
      trailing: trailing,
    );
  }
}

/// The "have it" tick: a round checkbox, amber-edged while the item is missing.
class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.checked, required this.missing, required this.onChanged});

  final bool checked;
  final bool missing;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context);
    return Checkbox(
      value: checked,
      onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
      shape: const CircleBorder(),
      activeColor: p.success,
      side: BorderSide(color: missing ? p.timerDone : theme.colorScheme.outline, width: 1.8),
    );
  }
}

String _number(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
