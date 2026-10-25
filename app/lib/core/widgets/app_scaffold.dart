import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../theme.dart';
import 'brand.dart';

/// The frame of every screen (docs/DESIGN.md §3, §14). Home: the labelled "תפריט" on the
/// right (the start side in Hebrew) and the menu sliding in from there. Every inner screen:
/// one back arrow on the right, pointing right, and only that screen's title (no app name,
/// no menu), truncated on one line. Back always ends at home (routes are nested under it).
/// Bottom bars sit above the system navigation and the keyboard; content is centred and
/// never wider than a comfortable reading width.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomBar,
  });

  /// The screen's own title. Null only on home, which shows the app name large in the page
  /// and has the menu instead of a back arrow.
  final String? title;
  final Widget body;

  /// Screen actions, on the far (left) side.
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  /// Fixed at the bottom, above the system navigation bar (e.g. the cooking screen's main
  /// button, so it never scrolls away).
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    final home = title == null;
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: home ? 64 + Space.s : 48 + Space.s,
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: Space.s),
          // A screen opened with nothing under it (a notification, a restored session) still
          // gets a way home.
          child: home ? const MenuButton() : BackButton(onPressed: canPop ? null : () => GoRouter.of(context).go('/')),
        ),
        titleSpacing: home ? 0 : Space.xs,
        title: home ? null : Text(title, overflow: TextOverflow.ellipsis, maxLines: 1),
        actions: [
          ...?actions,
          const SizedBox(width: Space.xs),
        ],
      ),
      drawer: home ? const AppMenu() : null,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomBar == null ? null : BottomActionBar(child: bottomBar!),
      body: SafeArea(top: false, bottom: bottomBar == null, child: ContentWidth(child: body)),
    );
  }
}

/// "תפריט": one tap, always labelled (never a bare icon): the icon with its word under it,
/// compact enough to share the corner with the back arrow.
class MenuButton extends StatelessWidget {
  const MenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = AppLocalizations.of(context).menu;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.input),
        onTap: () => Scaffold.of(context).openDrawer(),
        child: SizedBox(
          width: 60,
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_rounded, color: theme.colorScheme.onSurface),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface), maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The fixed bottom area: lifted above the gesture bar and the keyboard, with a hairline
/// on top so it reads as part of the screen, not a floating layer.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: ContentWidth(
            fitHeight: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.m, Space.page, Space.m),
              // The main action spans the width: easy to hit with one thumb.
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centres content and caps its width (tablets, landscape). [fitHeight]: as tall as the
/// child only (bars), instead of filling the available height (page bodies).
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.fitHeight = false});

  final Widget child;
  final bool fitHeight;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        heightFactor: fitHeight ? 1 : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
          child: child,
        ),
      );
}

/// The app menu: where everything is, one tap away. Leaving a screen never stops cooking;
/// an active session is listed first.
class AppMenu extends ConsumerWidget {
  const AppMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = ref.watch(activeSessionProvider).value;
    final location = GoRouterState.of(context).uri.toString();

    void go(String path) {
      Navigator.of(context).pop(); // close the menu first
      if (path != location) GoRouter.of(context).go(path);
    }

    Widget item(IconData icon, String label, String path, {bool emphasized = false}) {
      final selected = location == path;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: 2),
        child: ListTile(
          selected: selected,
          selectedTileColor: theme.colorScheme.primaryContainer,
          selectedColor: theme.colorScheme.onPrimaryContainer,
          tileColor: emphasized ? theme.colorScheme.secondaryContainer : null,
          leading: Icon(icon, color: emphasized ? context.palette.wood : null),
          title: Text(label, style: emphasized ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700) : null),
          onTap: () => go(path),
        ),
      );
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xl),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.xl, Space.xl, Space.xl, Space.l),
              child: Row(
                spacing: Space.m,
                children: [
                  const LogoMark(size: 40),
                  Expanded(child: Text(l10n.appTitle, style: theme.textTheme.titleLarge)),
                ],
              ),
            ),
            if (session != null) ...[
              item(Icons.local_fire_department_rounded, l10n.continueCooking, '/cook/${session.id}', emphasized: true),
              const SizedBox(height: Space.s),
            ],
            item(Icons.home_outlined, l10n.kitchenTitle, '/'),
            item(Icons.add_circle_outline, l10n.newRecipe, '/import'),
            item(Icons.menu_book_outlined, l10n.myRecipes, '/recipes'),
            item(Icons.star_outline_rounded, l10n.favorites, '/recipes?favorites=1'),
            item(Icons.history_rounded, l10n.cookingHistory, '/history'),
            const Divider(indent: Space.xl, endIndent: Space.xl),
            item(Icons.settings_outlined, l10n.settings, '/settings'),
          ],
        ),
      ),
    );
  }
}

/// Section heading used inside screens, with an optional link on the end side.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: Space.xl, bottom: Space.s),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
            ?trailing,
          ],
        ),
      );
}
