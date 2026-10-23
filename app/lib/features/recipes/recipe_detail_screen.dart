import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/estimate_badge.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/recipe.dart';
import '../cooking/start_cooking.dart';

enum _MenuAction { rename, source, delete }

class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final row = ref.watch(recipeProvider(recipeId));

    return switch (row) {
      AsyncData(value: final r?) => _RecipeDetail(row: r),
      AsyncData() => AppScaffold(
          title: l10n.myRecipes,
          body: Center(child: Text(l10n.recipeNotFound)),
        ),
      AsyncError() => AppScaffold(
          title: l10n.myRecipes,
          body: Center(child: Text(l10n.errorGeneric)),
        ),
      _ => AppScaffold(
          title: l10n.myRecipes,
          body: const Center(child: CircularProgressIndicator()),
        ),
    };
  }
}

class _RecipeDetail extends ConsumerWidget {
  const _RecipeDetail({required this.row});

  final RecipeRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final recipe = row.recipe;
    final repo = ref.read(recipeRepositoryProvider);

    return AppScaffold(
      title: row.displayTitle,
      actions: [
        IconButton(
          tooltip: row.isFavorite ? l10n.removeFavorite : l10n.addFavorite,
          icon: Icon(row.isFavorite ? Icons.star : Icons.star_outline),
          onPressed: () => repo.setFavorite(row.id, !row.isFavorite),
        ),
        PopupMenuButton<_MenuAction>(
          onSelected: (action) => switch (action) {
            _MenuAction.rename => _rename(context, ref),
            _MenuAction.source => _showSource(context, recipe),
            _MenuAction.delete => _delete(context, ref),
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: _MenuAction.rename, child: Text(l10n.rename)),
            PopupMenuItem(value: _MenuAction.source, child: Text(l10n.viewSource)),
            PopupMenuItem(value: _MenuAction.delete, child: Text(l10n.deleteRecipe)),
          ],
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(row.displayTitle, style: theme.textTheme.headlineSmall),
          if (recipe.description != null) ...[
            const SizedBox(height: 4),
            Text(recipe.description!),
          ],
          if (recipe.servings case final s?) ...[
            const SizedBox(height: 4),
            ProvenancedText('${_number(s.amount)} ${s.unit}', s.provenance),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => startCooking(context, ref, row.id),
            icon: const Icon(Icons.play_arrow),
            label: Text(l10n.startCooking),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push('/recipes/${row.id}/plan'),
            icon: const Icon(Icons.list_alt),
            label: Text(l10n.viewPlan),
          ),
          SectionTitle(l10n.ingredients),
          for (final i in recipe.ingredients)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.circle, size: 8),
              title: Text(i.name),
              subtitle: i.quantity == null
                  ? null
                  : ProvenancedText(i.quantity!.display, i.quantity!.provenance),
            ),
          if (recipe.equipment.isNotEmpty) ...[
            SectionTitle(l10n.equipment),
            for (final e in recipe.equipment)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.kitchen_outlined, size: 18),
                title: ProvenancedText(e.name, e.provenance),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: row.displayTitle);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renameTitle),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (title != null) await ref.read(recipeRepositoryProvider).rename(row.id, title);
  }

  Future<void> _showSource(BuildContext context, Recipe recipe) => showModalBottomSheet<void>(
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

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
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

String _number(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
