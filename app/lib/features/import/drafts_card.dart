import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../data/providers.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/components.dart';
import '../../l10n/app_localizations.dart';
import 'import_service.dart';

final draftsProvider = StreamProvider<List<RecipeRow>>(
  (ref) => ref.watch(recipeRepositoryProvider).watchDrafts(),
);

/// Continues an unfinished import: the overview if a plan exists, otherwise clarify.
Future<void> openDraft(BuildContext context, WidgetRef ref, String draftId, {bool replace = false}) async {
  final router = GoRouter.of(context);
  final hasPlan = await ref.read(recipeRepositoryProvider).draftPlan(draftId) != null;
  final path = hasPlan ? '/recipes/$draftId' : '/drafts/$draftId/clarify';
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
              onPressed: () => ref.read(importServiceProvider).discard(d.id),
            ),
          ),
      ],
    );
  }
}
