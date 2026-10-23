import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'backend_status.dart';

/// Home screen: "המטבח שלי". Sections are placeholders until Phase 1.
class KitchenScreen extends StatelessWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    void showComingSoon() => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.comingSoon)));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showComingSoon,
        icon: const Icon(Icons.add),
        label: Text(l10n.newRecipe),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text(l10n.kitchenTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: ListTile(
              leading: const Icon(Icons.local_fire_department_outlined),
              title: Text(l10n.continueCooking),
              subtitle: Text(l10n.noActiveSession),
            ),
          ),
          const SizedBox(height: 8),
          for (final (icon, label) in [
            (Icons.menu_book_outlined, l10n.myRecipes),
            (Icons.star_outline, l10n.favorites),
            (Icons.history, l10n.cookingHistory),
            (Icons.settings_outlined, l10n.settings),
          ])
            Card(
              child: ListTile(
                leading: Icon(icon),
                title: Text(label),
                subtitle: Text(l10n.comingSoon),
                trailing: const Icon(Icons.chevron_left),
                onTap: showComingSoon,
              ),
            ),
          const SizedBox(height: 16),
          const BackendStatusCard(),
        ],
      ),
    );
  }
}
