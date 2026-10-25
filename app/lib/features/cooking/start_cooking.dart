import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../data/session_repository.dart';
import '../../l10n/app_localizations.dart';
import '../assistant/conversation_store.dart';
import '../timers/timer_coordinator.dart';
import '../timers/timer_notifier.dart';

enum _ActiveChoice { goToActive, abandonAndStart }

/// Starts cooking a saved recipe from its latest approved plan. Only one
/// session can be active; the user chooses what to do with an existing one.
Future<void> startCooking(BuildContext context, WidgetRef ref, String recipeId) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final recipes = ref.read(recipeRepositoryProvider);
  final sessions = ref.read(sessionRepositoryProvider);

  if ((await recipes.getRecipe(recipeId))?.planStale ?? false) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.recipeOutdatedBanner)));
    return;
  }
  final plan = await recipes.latestApprovedPlan(recipeId);
  if (plan == null) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.noPlan)));
    return;
  }
  // Timers need notification permission (Android 13+ asks at runtime) and,
  // to ring on time, exact alarms (denied by default on Android 14+).
  final notifier = ref.read(localTimerNotifierProvider);
  if (notifier != null) {
    await notifier.requestNotifications();
    final perms = await notifier.permissions();
    if (!perms.exactAlarmsAllowed && context.mounted) {
      final allow = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.exactAlarmPromptTitle),
          content: Text(l10n.exactAlarmPromptBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.continueWithout)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.allowInSettings)),
          ],
        ),
      );
      if (allow == true) await notifier.requestExactAlarms();
    }
  }
  try {
    final session = await sessions.startSession(recipeId: recipeId, planId: plan.id);
    router.go('/cook/${session.id}');
  } on ActiveSessionExistsException catch (e) {
    final activeRecipe = await recipes.getRecipe(e.active.recipeId);
    if (!context.mounted) return;
    final choice = await showDialog<_ActiveChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.activeSessionTitle),
        content: Text(l10n.activeSessionBody(activeRecipe?.displayTitle ?? '')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, _ActiveChoice.abandonAndStart),
            child: Text(l10n.abandonAndStart),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _ActiveChoice.goToActive),
            child: Text(l10n.goToActive),
          ),
        ],
      ),
    );
    switch (choice) {
      case _ActiveChoice.goToActive:
        router.go('/cook/${e.active.id}');
      case _ActiveChoice.abandonAndStart:
        await sessions.abandon(e.active.id);
        await ref.read(timerCoordinatorProvider).clearSession(e.active.id);
        await forgetConversation(ref.read(settingsRepositoryProvider), e.active.recipeId);
        final session = await sessions.startSession(recipeId: recipeId, planId: plan.id);
        router.go('/cook/${session.id}');
      case null:
        break;
    }
  }
}
