import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_scaffold.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../l10n/app_localizations.dart';
import 'backend_status.dart';

/// Home screen: "המטבח שלי".
class KitchenScreen extends ConsumerWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return AppScaffold(
      title: l10n.kitchenTitle,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.importComingSoon))),
        icon: const Icon(Icons.add),
        label: Text(l10n.newRecipe),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          const _ContinueCookingCard(),
          const SizedBox(height: 8),
          for (final (icon, label, path) in [
            (Icons.menu_book_outlined, l10n.myRecipes, '/recipes'),
            (Icons.star_outline, l10n.favorites, '/recipes?favorites=1'),
            (Icons.history, l10n.cookingHistory, '/history'),
            (Icons.settings_outlined, l10n.settings, '/settings'),
          ])
            Card(
              child: ListTile(
                leading: Icon(icon),
                title: Text(label),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => context.push(path),
              ),
            ),
          const SizedBox(height: 16),
          const BackendStatusCard(),
        ],
      ),
    );
  }
}

class _ContinueCookingCard extends ConsumerWidget {
  const _ContinueCookingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = ref.watch(activeSessionProvider).value;
    final recipe = session == null ? null : ref.watch(recipeProvider(session.recipeId)).value;

    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: ListTile(
        leading: const Icon(Icons.local_fire_department_outlined),
        title: Text(l10n.continueCooking),
        subtitle: Text(recipe?.displayTitle ?? l10n.noActiveSession),
        trailing: session == null ? null : const Icon(Icons.chevron_left),
        onTap: session == null ? null : () => context.push('/cook/${session.id}'),
      ),
    );
  }
}
