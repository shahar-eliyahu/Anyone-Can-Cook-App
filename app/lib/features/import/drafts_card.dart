import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/components.dart';
import '../../l10n/app_localizations.dart';
import '../../models/recipe_analysis.dart';
import '../create/recipe_creation_service.dart';

final draftsProvider = StreamProvider<List<RecipeRow>>(
  (ref) => ref.watch(recipeRepositoryProvider).watchDrafts(),
);

/// Continues an unfinished new recipe: the overview if a plan exists; otherwise the review of a
/// recipe Remy created, or clarify for an import.
Future<void> openDraft(BuildContext context, WidgetRef ref, String draftId, {bool replace = false}) async {
  final router = GoRouter.of(context);
  final repo = ref.read(recipeRepositoryProvider);
  final hasPlan = await repo.draftPlan(draftId) != null;
  final row = await repo.getRecipe(draftId);
  final fromRemy = row?.analysis?.source.type == SourceType.remy;
  final path = fromRemy && (!hasPlan || row!.planStale)
      ? '/drafts/$draftId/preview'
      : hasPlan
          ? '/recipes/$draftId'
          : '/drafts/$draftId/clarify';
  replace ? router.pushReplacement(path) : router.push(path);
}

/// Unfinished new recipes on home (hidden when there are none): continue or delete.
class DraftsCard extends ConsumerWidget {
  const DraftsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final drafts = ref.watch(draftsProvider).value ?? const [];
    if (drafts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l10n.draftsTitle),
        for (final d in drafts)
          RecipeTile(
            title: d.title.isEmpty ? l10n.importTitle : d.title,
            leadingIcon: Icons.edit_note_rounded,
            onTap: () => openDraft(context, ref, d.id),
            trailing: IconButton(
              tooltip: l10n.draftDiscard,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => ref.read(recipeCreationServiceProvider).discard(d.id),
            ),
          ),
      ],
    );
  }
}
