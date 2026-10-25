import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/motion_widgets.dart';
import '../../l10n/app_localizations.dart';

/// "מה בא לכם לבשל?" (docs/DESIGN.md §16): three ways to a recipe. A ready one from the
/// built-in catalog, one Remy creates with the cook, or the cook's own (the existing import).
class CreateHubScreen extends StatelessWidget {
  const CreateHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final choices = [
      (Icons.menu_book_rounded, l10n.hubCatalogTitle, l10n.hubCatalogSubtitle, '/catalog'),
      (Icons.auto_awesome_rounded, l10n.hubRemyTitle, l10n.hubRemySubtitle, '/create'),
      (Icons.edit_note_rounded, l10n.hubOwnTitle, l10n.hubOwnSubtitle, '/import'),
    ];
    return AppScaffold(
      title: l10n.newRecipe,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.xl),
        children: [
          Text(l10n.hubIntro, style: theme.textTheme.titleLarge),
          const SizedBox(height: Space.m),
          for (final (i, (icon, title, subtitle, path)) in choices.indexed)
            Appear(
              index: i,
              child: RecipeTile(title: title, subtitle: subtitle, leadingIcon: icon, onTap: () => context.push(path)),
            ),
        ],
      ),
    );
  }
}
