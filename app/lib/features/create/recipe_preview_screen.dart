import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/components.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/provenance.dart';
import '../../models/recipe.dart';
import '../import/import_errors.dart';
import 'recipe_creation_service.dart';

/// The review of a recipe Remy created (docs/DECISIONS.md #85): everything in it, editable,
/// before it becomes the cook's recipe. "שמירה" plans it (one /plan call, like an import) and
/// opens its overview; "ביטול" deletes the draft and its conversation.
class RecipePreviewScreen extends ConsumerStatefulWidget {
  const RecipePreviewScreen({super.key, required this.draftId, this.fromChat = false});

  final String draftId;

  /// Opened from the creation chat: "שינוי עם רמי" goes back to it.
  final bool fromChat;

  @override
  ConsumerState<RecipePreviewScreen> createState() => _RecipePreviewScreenState();
}

class _RecipePreviewScreenState extends ConsumerState<RecipePreviewScreen> {
  _Editor? _editor;
  bool _busy = false;
  String? _error;

  RecipeCreationService get _service => ref.read(recipeCreationServiceProvider);

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.save(widget.draftId);
      router.go('/recipes/${widget.draftId}');
    } catch (e) {
      if (mounted) setState(() => _error = importErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishEditing() async {
    final l10n = AppLocalizations.of(context);
    final recipe = _editor!.build();
    if (recipe == null) {
      setState(() => _error = l10n.previewNeedsItems);
      return;
    }
    await _service.updateRecipe(widget.draftId, recipe);
    if (mounted) {
      setState(() {
        _editor = null;
        _error = null;
      });
    }
  }

  Future<void> _discard() async {
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.previewDiscardConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.previewDiscard)),
        ],
      ),
    );
    if (ok != true) return;
    await _service.discard(widget.draftId);
    router.go('/');
  }

  void _changeWithRemy() => widget.fromChat ? context.pop() : context.push('/create?id=${widget.draftId}');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rowValue = ref.watch(recipeProvider(widget.draftId));
    final row = rowValue.value;
    final recipe = row?.analysis?.recipe;
    if (rowValue is AsyncData && (row == null || !row.isDraft || recipe == null)) {
      return AppScaffold(title: l10n.previewTitle, body: Center(child: Text(l10n.recipeNotFound)));
    }
    if (row == null || recipe == null) {
      return AppScaffold(title: l10n.previewTitle, body: const Center(child: CircularProgressIndicator()));
    }
    final editor = _editor;
    return AppScaffold(
      title: l10n.previewTitle,
      bottomBar: _busy
          ? StageLoader(stages: [l10n.importStagePlanning], current: 0)
          : editor != null
              ? Row(
                  spacing: Space.s,
                  children: [
                    Expanded(child: FilledButton(onPressed: _finishEditing, child: Text(l10n.previewDoneEditing))),
                    TextButton(onPressed: () => setState(() => _editor = null), child: Text(l10n.cancel)),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: Space.xs,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                      onPressed: _save,
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: Text(l10n.saveToMyRecipes),
                    ),
                    Row(
                      spacing: Space.s,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => _editor = _Editor(recipe)),
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(l10n.previewEdit),
                          ),
                        ),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _changeWithRemy,
                            icon: const Icon(Icons.auto_awesome_rounded),
                            label: Text(l10n.previewChangeWithRemy),
                          ),
                        ),
                      ],
                    ),
                    TextButton(onPressed: _discard, child: Text(l10n.previewDiscard)),
                  ],
                ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.xl),
        children: [
          if (_error case final e?) NoteBanner(e, kind: NoteKind.warning),
          if (editor != null) _EditView(editor: editor, onChanged: () => setState(() {})) else _ReadView(row: row, recipe: recipe),
        ],
      ),
    );
  }
}

/// Everything Remy suggested, read-only: what to buy, what to use, what to do.
class _ReadView extends StatelessWidget {
  const _ReadView({required this.row, required this.recipe});

  final RecipeRow row;
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final creation = row.creation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NoteBanner(l10n.previewIntro, icon: Icons.auto_awesome_rounded),
        Text(recipe.title, style: theme.textTheme.headlineSmall),
        if (recipe.description case final d?)
          Padding(
            padding: const EdgeInsets.only(top: Space.xs),
            child: Text(tidyHe(d), style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        const SizedBox(height: Space.s),
        Wrap(
          spacing: Space.s,
          runSpacing: Space.s,
          children: [
            if (recipe.servings case final s?) InfoPill(icon: Icons.restaurant_rounded, label: '${_number(s.amount)} ${s.unit}'),
            if (creation.totalMinutes case final m?)
              InfoPill(icon: Icons.schedule_rounded, label: l10n.previewTimeEstimate(formatApproxDuration(m, l10n))),
          ],
        ),
        SectionTitle(l10n.ingredients),
        Card(
          child: Column(
            children: [
              for (final i in recipe.ingredients)
                ListTile(
                  title: Text(i.name),
                  subtitle: Text([?i.quantity?.display, if (i.optional) l10n.optionalItem].join(', ')),
                ),
            ],
          ),
        ),
        if (recipe.equipment.isNotEmpty) ...[
          SectionTitle(l10n.equipment),
          Card(child: Column(children: [for (final e in recipe.equipment) ListTile(title: Text(e.name))])),
        ],
        SectionTitle(l10n.previewSteps),
        for (final (n, s) in recipe.sourceSteps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Space.m,
              children: [
                CircleAvatar(radius: 14, child: Text('${n + 1}', style: theme.textTheme.labelLarge)),
                Expanded(child: Text(tidyHe(s.text), style: theme.textTheme.bodyLarge)),
              ],
            ),
          ),
        if (creation.tipsHe.isNotEmpty)
          NoteBanner(
            '',
            kind: NoteKind.tip,
            title: l10n.previewTips,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final t in creation.tipsHe) Text('• ${tidyHe(t)}')],
            ),
          ),
      ],
    );
  }
}

/// The cook's corrections before saving: names and amounts, equipment, steps; rows can be
/// removed or added. What the cook changed is marked as theirs (provenance `user`).
class _Editor {
  _Editor(this.original)
      : title = TextEditingController(text: original.title),
        ingredients = [
          for (final i in original.ingredients)
            (i, TextEditingController(text: i.name), TextEditingController(text: i.quantity?.display ?? '')),
        ],
        equipment = [for (final e in original.equipment) (e, TextEditingController(text: e.name))],
        steps = [for (final s in original.sourceSteps) (s, TextEditingController(text: s.text))];

  final Recipe original;
  final TextEditingController title;
  final List<(Ingredient?, TextEditingController, TextEditingController)> ingredients;
  final List<(Equipment?, TextEditingController)> equipment;
  final List<(SourceStep?, TextEditingController)> steps;

  static final _amount = RegExp(r'^(\d+(?:[.,]\d+)?)\s*(.*)$');

  /// The edited recipe, or null when no ingredient or no step is left.
  Recipe? build() {
    String nextId(String prefix, Iterable<String> used) {
      var n = used.length + 1;
      while (used.contains('$prefix$n')) {
        n++;
      }
      return '$prefix$n';
    }

    final ingIds = {for (final (i, _, _) in ingredients) ?i?.id};
    final newIngredients = <Ingredient>[];
    for (final (i, name, amount) in ingredients) {
      final n = name.text.trim();
      if (n.isEmpty) continue;
      final display = amount.text.trim();
      final changed = i == null || display != (i.quantity?.display ?? '');
      final m = _amount.firstMatch(display);
      final quantity = display.isEmpty
          ? null
          : changed
              ? Quantity(
                  amount: m == null ? null : double.tryParse(m.group(1)!.replaceAll(',', '.')),
                  unit: m == null || m.group(2)!.trim().isEmpty ? null : m.group(2)!.trim(),
                  display: display,
                  provenance: Provenance.user,
                )
              : i.quantity;
      final id = i?.id ?? nextId('i', {...ingIds, ...newIngredients.map((x) => x.id)});
      newIngredients.add((i ?? Ingredient(id: id, name: n)).copyWith(name: n, quantity: quantity));
    }
    final eqIds = {for (final (e, _) in equipment) ?e?.id};
    final newEquipment = <Equipment>[];
    for (final (e, name) in equipment) {
      final n = name.text.trim();
      if (n.isEmpty) continue;
      final id = e?.id ?? nextId('e', {...eqIds, ...newEquipment.map((x) => x.id)});
      newEquipment.add(e == null ? Equipment(id: id, name: n, provenance: Provenance.user) : e.copyWith(name: n));
    }
    final stepIds = {for (final (s, _) in steps) ?s?.id};
    final newSteps = <SourceStep>[];
    for (final (s, text) in steps) {
      final t = text.text.trim();
      if (t.isEmpty) continue;
      newSteps.add(SourceStep(id: s?.id ?? nextId('src', {...stepIds, ...newSteps.map((x) => x.id)}), text: t));
    }
    if (newIngredients.isEmpty || newSteps.isEmpty) return null;
    return original.copyWith(
      title: title.text.trim().isEmpty ? original.title : title.text.trim(),
      ingredients: newIngredients,
      equipment: newEquipment,
      sourceSteps: newSteps,
    );
  }
}

class _EditView extends StatelessWidget {
  const _EditView({required this.editor, required this.onChanged});

  final _Editor editor;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget remove(VoidCallback onTap) => IconButton(tooltip: l10n.previewRemove, onPressed: onTap, icon: const Icon(Icons.remove_circle_outline_rounded));
    Widget add(String label, VoidCallback onTap) => Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(onPressed: onTap, icon: const Icon(Icons.add_rounded), label: Text(label)),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Space.s,
      children: [
        TextField(controller: editor.title, decoration: InputDecoration(labelText: l10n.previewFieldTitle)),
        SectionTitle(l10n.ingredients),
        for (final row in editor.ingredients)
          Row(
            spacing: Space.s,
            children: [
              Expanded(flex: 3, child: TextField(controller: row.$2, decoration: InputDecoration(labelText: l10n.editName))),
              Expanded(flex: 2, child: TextField(controller: row.$3, decoration: InputDecoration(labelText: l10n.previewFieldAmount))),
              remove(() {
                editor.ingredients.remove(row);
                onChanged();
              }),
            ],
          ),
        add(l10n.previewAddIngredient, () {
          editor.ingredients.add((null, TextEditingController(), TextEditingController()));
          onChanged();
        }),
        SectionTitle(l10n.equipment),
        for (final row in editor.equipment)
          Row(
            spacing: Space.s,
            children: [
              Expanded(child: TextField(controller: row.$2, decoration: InputDecoration(labelText: l10n.equipment))),
              remove(() {
                editor.equipment.remove(row);
                onChanged();
              }),
            ],
          ),
        add(l10n.previewAddEquipment, () {
          editor.equipment.add((null, TextEditingController()));
          onChanged();
        }),
        SectionTitle(l10n.previewSteps),
        for (final (n, row) in editor.steps.indexed)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Space.s,
            children: [
              Expanded(
                child: TextField(
                  controller: row.$2,
                  minLines: 1,
                  maxLines: 5,
                  decoration: InputDecoration(labelText: l10n.previewFieldStep(n + 1)),
                ),
              ),
              remove(() {
                editor.steps.remove(row);
                onChanged();
              }),
            ],
          ),
        add(l10n.previewAddStep, () {
          editor.steps.add((null, TextEditingController()));
          onChanged();
        }),
      ],
    );
  }
}

String _number(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
