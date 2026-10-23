import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../data/session_repository.dart';
import '../../l10n/app_localizations.dart';

String sessionStatusLabel(AppLocalizations l10n, String status) => switch (status) {
      SessionStatus.completed => l10n.statusCompleted,
      SessionStatus.abandoned => l10n.statusAbandoned,
      _ => l10n.statusInProgress,
    };

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final history = ref.watch(historyProvider);

    return AppScaffold(
      title: l10n.cookingHistory,
      body: switch (history) {
        AsyncData(value: final entries) when entries.isEmpty =>
          Center(child: Text(l10n.historyEmpty)),
        AsyncData(value: final entries) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final e in entries)
                Card(
                  child: ListTile(
                    title: Text(e.recipe.displayTitle),
                    subtitle: Text(
                      '${formatDateTime(e.session.startedAt)} · ${sessionStatusLabel(l10n, e.session.status)}'
                      '${e.session.endedAt == null ? '' : ' · ${l10n.minutesShort(e.session.endedAt!.difference(e.session.startedAt).inMinutes)}'}',
                    ),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => context.push('/history/${e.session.id}'),
                  ),
                ),
            ],
          ),
        AsyncError() => Center(child: Text(l10n.errorGeneric)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
