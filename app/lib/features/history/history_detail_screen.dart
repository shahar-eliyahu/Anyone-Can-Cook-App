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
import '../cooking/engine/cooking_engine.dart';
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
    final theme = Theme.of(context);
    final session = detail.entry.session;
    final recipe = detail.entry.recipe;
    // A friendly summary rebuilt from the session's events: which steps were done.
    final state = CookingEngine.replay(detail.plan, detail.events);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(recipe.displayTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('${formatDateTime(session.startedAt)} · ${sessionStatusLabel(l10n, session.status)}'),
        if (session.endedAt != null)
          Text(l10n.cookingTime(cookingDurationLabel(l10n, session.startedAt, session.endedAt!))),
        if (session.notes != null) ...[
          SectionTitle(l10n.notes),
          Text(session.notes!),
        ],
        SectionTitle(l10n.stepsCompletedTitle),
        for (final step in detail.plan.steps)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              state.isStepDone(step) ? Icons.check_circle : Icons.radio_button_unchecked,
              color: state.isStepDone(step) ? theme.colorScheme.primary : theme.disabledColor,
            ),
            title: Text(step.title),
            subtitle: state.isStepDone(step) ? null : Text(l10n.stepNotDone),
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
