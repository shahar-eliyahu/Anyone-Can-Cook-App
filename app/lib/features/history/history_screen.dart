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

/// "25 דק'", or "פחות מדקה" for very short sessions.
String cookingDurationLabel(AppLocalizations l10n, DateTime start, DateTime end) {
  final minutes = end.difference(start).inMinutes;
  return minutes < 1 ? l10n.durationUnderMinute : l10n.minutesShort(minutes);
}

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
                      '${e.session.endedAt == null ? '' : ' · ${cookingDurationLabel(l10n, e.session.startedAt, e.session.endedAt!)}'}',
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
