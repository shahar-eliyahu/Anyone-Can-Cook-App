import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../data/session_repository.dart';
import '../cooking/engine/cooking_engine.dart';
import 'timer_coordinator.dart';

/// Makes the active session's notifications match its saved state. Used at
/// startup and on every resume: covers force stops, dropped alarms, and
/// upgrading timers to exact delivery once that permission is granted.
Future<void> restoreActiveSessionTimers({
  required SessionRepository sessions,
  required RecipeRepository recipes,
  required TimerCoordinator coordinator,
}) async {
  try {
    final active = await sessions.activeSession();
    if (active == null) return;
    final plan = await recipes.getPlan(active.planId);
    if (plan == null) return;
    final state = CookingEngine.replay(plan.plan, await sessions.loadEvents(active.id));
    await coordinator.reconcile(active.id, state);
  } catch (e, st) {
    debugPrint('timer restore failed: $e\n$st');
  }
}

/// Re-runs [restoreActiveSessionTimers] whenever the app returns to the foreground.
class TimerRestoreOnResume extends ConsumerStatefulWidget {
  const TimerRestoreOnResume({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<TimerRestoreOnResume> createState() => _TimerRestoreOnResumeState();
}

class _TimerRestoreOnResumeState extends ConsumerState<TimerRestoreOnResume> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onResume: () => restoreActiveSessionTimers(
        sessions: ref.read(sessionRepositoryProvider),
        recipes: ref.read(recipeRepositoryProvider),
        coordinator: ref.read(timerCoordinatorProvider),
      ),
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
