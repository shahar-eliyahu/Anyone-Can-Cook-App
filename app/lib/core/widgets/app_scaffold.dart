import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Scaffold whose app bar always shows the Hebrew app name above the screen title.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomBar,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  /// Fixed at the bottom, above the system navigation bar (e.g. the cooking
  /// screen's main button, so it never scrolls away).
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).appTitle, style: theme.textTheme.labelMedium),
            Text(title, overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomBar == null
          ? null
          : Material(
              elevation: 8,
              color: theme.colorScheme.surfaceContainer,
              child: SafeArea(
                top: false,
                child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: bottomBar),
              ),
            ),
      body: SafeArea(bottom: bottomBar == null, child: body),
    );
  }
}

/// Section heading used inside screens.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}
