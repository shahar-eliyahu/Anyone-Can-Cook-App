import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/motion_widgets.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../data/session_repository.dart';
import '../../l10n/app_localizations.dart';
import '../assistant/assistant_service.dart' show durationWords;

String sessionStatusLabel(AppLocalizations l10n, String status) => switch (status) {
      SessionStatus.completed => l10n.statusCompleted,
      SessionStatus.abandoned => l10n.statusAbandoned,
      _ => l10n.statusInProgress,
    };

/// "25 דק'", "3 שעות ו-56 דקות", or "פחות מדקה" for very short sessions.
String cookingDurationLabel(AppLocalizations l10n, DateTime start, DateTime end) {
  final minutes = end.difference(start).inMinutes;
  if (minutes < 1) return l10n.durationUnderMinute;
  return minutes < 60 ? l10n.minutesShort(minutes) : durationWords(Duration(minutes: minutes));
}

IconData sessionStatusIcon(String status) => switch (status) {
      SessionStatus.completed => Icons.check_circle_outline_rounded,
      SessionStatus.abandoned => Icons.pause_circle_outline_rounded,
      _ => Icons.local_fire_department_outlined,
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
          EmptyState(icon: Icons.history_rounded, title: l10n.historyEmptyTitle, message: l10n.historyEmpty),
        AsyncData(value: final entries) => ListView(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.xxl),
            children: [
              for (final (i, e) in entries.indexed)
                Appear(
                  index: i,
                  child: RecipeTile(
                    title: e.recipe.displayTitle,
                    leadingIcon: sessionStatusIcon(e.session.status),
                    subtitle: [
                      formatDateTime(e.session.startedAt),
                      sessionStatusLabel(l10n, e.session.status),
                      if (e.session.endedAt case final end?) cookingDurationLabel(l10n, e.session.startedAt, end),
                    ].join(' · '),
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
