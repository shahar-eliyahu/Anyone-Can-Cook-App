import 'package:anyone_can_cook/core/db/database.dart';
import 'package:anyone_can_cook/data/recipe_repository.dart';
import 'package:anyone_can_cook/data/session_repository.dart';
import 'package:anyone_can_cook/features/cooking/engine/action_dispatcher.dart';
import 'package:anyone_can_cook/features/cooking/engine/cooking_engine.dart';
import 'package:anyone_can_cook/features/timers/session_restorer.dart';
import 'package:anyone_can_cook/features/timers/timer_coordinator.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/sample.dart';

void main() {
  test('restores the active session timers from the database (startup and resume)', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final clock = FakeClock();
    final recipes = RecipeRepository(db, clock.call);
    final sessions = SessionRepository(db, clock.call);
    final notifier = RecordingTimerNotifier();
    final coordinator = TimerCoordinator(notifier, clock.call);

    // Nothing to restore without an active session.
    await restoreActiveSessionTimers(sessions: sessions, recipes: recipes, coordinator: coordinator);
    expect(notifier.log, isEmpty);

    final recipeId = await recipes.saveBundle(loadSampleBundle(), sourceType: 'sample');
    final plan = (await recipes.latestApprovedPlan(recipeId))!;
    final session = await sessions.startSession(recipeId: recipeId, planId: plan.id);
    final dispatcher = ActionDispatcher(
      state: CookingEngine.replay(plan.plan, await sessions.loadEvents(session.id)),
      store: sessions.eventStoreFor(session.id),
      onEffects: (_) async {},
      clock: clock.call,
    );
    await dispatcher.completePrepTask('p1');
    clock.advance(const Duration(minutes: 5));

    await restoreActiveSessionTimers(sessions: sessions, recipes: recipes, coordinator: coordinator);
    expect(notifier.scheduled, {
      '${session.id}/tp1': dispatcher.state.timers['tp1']!.endsAt,
    });

    // Restoring again is idempotent.
    await restoreActiveSessionTimers(sessions: sessions, recipes: recipes, coordinator: coordinator);
    expect(notifier.scheduled, hasLength(1));
  });
}
