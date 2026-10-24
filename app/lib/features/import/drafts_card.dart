import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import 'import_service.dart';

final draftsProvider = StreamProvider<List<RecipeRow>>(
  (ref) => ref.watch(recipeRepositoryProvider).watchDrafts(),
);

/// Continues an unfinished import: review if a plan exists, otherwise clarify.
Future<void> openDraft(BuildContext context, WidgetRef ref, String draftId, {bool replace = false}) async {
  final router = GoRouter.of(context);
  final hasPlan = await ref.read(recipeRepositoryProvider).draftPlan(draftId) != null;
  final path = hasPlan ? '/drafts/$draftId/review' : '/drafts/$draftId/clarify';
  replace ? router.pushReplacement(path) : router.push(path);
}

/// "ייבואים שלא הושלמו" on the home screen (hidden when there are none).
class DraftsCard extends ConsumerWidget {
  const DraftsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final drafts = ref.watch(draftsProvider).value ?? const [];
    if (drafts.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l10n.draftsTitle, style: Theme.of(context).textTheme.titleSmall),
            ),
            for (final d in drafts)
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: Text(d.title.isEmpty ? l10n.importTitle : d.title),
                onTap: () => openDraft(context, ref, d.id),
                trailing: IconButton(
                  tooltip: l10n.draftDiscard,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ref.read(importServiceProvider).discard(d.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
