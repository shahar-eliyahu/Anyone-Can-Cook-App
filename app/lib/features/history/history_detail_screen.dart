import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../data/session_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cooking_plan.dart';
import '../cooking/engine/events.dart';
import '../cooking/start_cooking.dart';
import 'history_screen.dart';

class _HistoryDetail {
  const _HistoryDetail(this.entry, this.plan, this.events);
  final HistoryEntry entry;
  final CookingPlan plan;
  final List<CookingEvent> events;
}

final _detailProvider = FutureProvider.autoDispose.family<_HistoryDetail?, String>((ref, sessionId) async {
  final sessions = ref.watch(sessionRepositoryProvider);
  final recipes = ref.watch(recipeRepositoryProvider);
  final session = await sessions.getSession(sessionId);
  if (session == null) return null;
  final recipe = await recipes.getRecipe(session.recipeId);
  final plan = await recipes.getPlan(session.planId);
  if (recipe == null || plan == null) return null;
  return _HistoryDetail(HistoryEntry(session, recipe), plan.plan, await sessions.loadEvents(sessionId));
});

class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(_detailProvider(sessionId));

    return AppScaffold(
      title: l10n.cookingHistory,
      body: switch (detail) {
        AsyncData(value: final d?) => _DetailView(detail: d),
        AsyncData() => Center(child: Text(l10n.recipeNotFound)),
        AsyncError() => Center(child: Text(l10n.errorGeneric)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _DetailView extends ConsumerWidget {
  const _DetailView({required this.detail});

  final _HistoryDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = detail.entry.session;
    final recipe = detail.entry.recipe;
    final plan = detail.plan;

    String? describe(CookingEvent e) => switch (e) {
          ActionConfirmed(:final stepId, :final actionId) => () {
              final step = plan.stepById(stepId);
              final action = step?.actionById(actionId);
              return step == null || action == null ? null : '${step.title}: ${action.labelHe}';
            }(),
          PrepTaskDone(:final prepTaskId) => plan.prepTaskById(prepTaskId)?.textHe,
          _ => null,
        };

    final log = [
      for (final e in detail.events)
        if (describe(e) case final text?) (e.at, text),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(recipe.displayTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(sessionStatusLabel(l10n, session.status)),
        Text(l10n.startedAt(formatDateTime(session.startedAt))),
        if (session.endedAt != null) ...[
          Text(l10n.endedAt(formatDateTime(session.endedAt!))),
          Text(l10n.cookingTime(l10n.minutesShort(session.endedAt!.difference(session.startedAt).inMinutes))),
        ],
        if (session.notes != null) ...[
          SectionTitle(l10n.notes),
          Text(session.notes!),
        ],
        SectionTitle(l10n.approvedChanges),
        Text(l10n.noApprovedChanges),
        SectionTitle(l10n.actionsLog),
        for (final (at, text) in log)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Text(formatTime(at), textDirection: TextDirection.ltr),
            title: Text(text),
          ),
        const SizedBox(height: 16),
        if (session.status == SessionStatus.inProgress)
          FilledButton(
            onPressed: () => context.go('/cook/${session.id}'),
            child: Text(l10n.continueCooking),
          )
        else
          FilledButton(
            onPressed: () => startCooking(context, ref, recipe.id),
            child: Text(l10n.cookAgain),
          ),
      ],
    );
  }
}
