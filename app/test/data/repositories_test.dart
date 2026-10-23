import 'dart:io';

import 'package:anyone_can_cook/core/db/database.dart';
import 'package:anyone_can_cook/data/recipe_repository.dart';
import 'package:anyone_can_cook/data/sample_seeder.dart';
import 'package:anyone_can_cook/data/session_repository.dart';
import 'package:anyone_can_cook/data/settings_repository.dart';
import 'package:anyone_can_cook/features/cooking/engine/action_dispatcher.dart';
import 'package:anyone_can_cook/features/cooking/engine/cooking_engine.dart';
import 'package:anyone_can_cook/features/cooking/engine/events.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sample.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late RecipeRepository recipes;
  late SessionRepository sessions;
  late SettingsRepository settings;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    clock = FakeClock();
    recipes = RecipeRepository(db, clock.call);
    sessions = SessionRepository(db, clock.call);
    settings = SettingsRepository(db, clock.call);
  });
  tearDown(() => db.close());

  Future<String> saveSample() =>
      recipes.saveBundle(loadSampleBundle(), sourceType: 'sample');

  group('recipes', () {
    test('saves the original recipe and the approved plan separately; reopens them', () async {
      final bundle = loadSampleBundle();
      final id = await saveSample();
      final row = (await recipes.getRecipe(id))!;
      expect(row.recipe, bundle.recipe);
      expect(row.displayTitle, bundle.recipe.title);
      final plan = (await recipes.latestApprovedPlan(id))!;
      expect(plan.status, 'approved');
      expect(plan.plan, bundle.plan);
    });

    test('favorites, search and rename', () async {
      final a = await saveSample();
      clock.advance(const Duration(minutes: 1));
      final b = await saveSample();
      await recipes.rename(b, 'העוף של סבתא');
      await recipes.setFavorite(a, true);

      final favorites = await recipes.watchRecipes(favoritesOnly: true).first;
      expect([for (final r in favorites) r.id], [a]);

      final found = await recipes.watchRecipes(query: 'סבתא').first;
      expect([for (final r in found) r.displayTitle], ['העוף של סבתא']);

      await recipes.rename(b, '   ');
      expect((await recipes.getRecipe(b))!.displayTitle, loadSampleBundle().recipe.title);
    });

    test('soft delete hides the recipe and its history; undo restores them', () async {
      final id = await saveSample();
      final plan = (await recipes.latestApprovedPlan(id))!;
      final s = await sessions.startSession(recipeId: id, planId: plan.id);
      await sessions.complete(s.id);

      final deletedAt = await recipes.softDelete(id);
      expect(await recipes.getRecipe(id), isNull);
      expect(await recipes.watchRecipes().first, isEmpty);
      expect(await sessions.watchHistory().first, isEmpty);

      await recipes.restore(id, deletedAt);
      expect(await recipes.getRecipe(id), isNotNull);
      expect(await recipes.latestApprovedPlan(id), isNotNull);
      expect(await sessions.watchHistory().first, hasLength(1));
    });

    test('a recipe being cooked cannot be deleted', () async {
      final id = await saveSample();
      final plan = (await recipes.latestApprovedPlan(id))!;
      await sessions.startSession(recipeId: id, planId: plan.id);
      expect(() => recipes.softDelete(id), throwsA(isA<RecipeHasActiveSessionException>()));
    });
  });

  group('sessions', () {
    test('only one session can be in progress', () async {
      final id = await saveSample();
      final plan = (await recipes.latestApprovedPlan(id))!;
      final first = await sessions.startSession(recipeId: id, planId: plan.id);
      expect(
        () => sessions.startSession(recipeId: id, planId: plan.id),
        throwsA(isA<ActiveSessionExistsException>()
            .having((e) => e.active.id, 'active id', first.id)),
      );
      await sessions.abandon(first.id);
      expect(await sessions.activeSession(), isNull);
      final second = await sessions.startSession(recipeId: id, planId: plan.id);
      expect((await sessions.activeSession())!.id, second.id);
    });

    test('events are stored in order and replay into the live state', () async {
      final id = await saveSample();
      final planRow = (await recipes.latestApprovedPlan(id))!;
      final session = await sessions.startSession(recipeId: id, planId: planRow.id);
      final events = await sessions.loadEvents(session.id);
      expect(events.single, isA<SessionStarted>());

      final dispatcher = ActionDispatcher(
        state: CookingEngine.replay(planRow.plan, events),
        store: sessions.eventStoreFor(session.id),
        onEffects: (_) async {},
        clock: clock.call,
      );
      await dispatcher.completePrepTask('p1');
      await dispatcher.confirmAction('s1', 'a1');
      await dispatcher.confirmAction('s1', 'a2');
      await dispatcher.confirmAction('s2', 'a1');
      clock.advance(const Duration(seconds: 42));
      await dispatcher.confirmAction('s3', 'a1');

      final stored = await sessions.loadEvents(session.id);
      expect(stored.map((e) => e.type), [
        'SessionStarted',
        'PrepTaskDone',
        'ActionConfirmed',
        'ActionConfirmed',
        'ActionConfirmed',
        'ActionConfirmed',
      ]);
      final restored = CookingEngine.replay(planRow.plan, stored);
      expect(restored.timers['t1']!.endsAt, dispatcher.state.timers['t1']!.endsAt);
      expect(restored.timers['tp1']!.endsAt, dispatcher.state.timers['tp1']!.endsAt);
      expect(restored.snapshot(clock.now), dispatcher.state.snapshot(clock.now));
    });

    test('history lists sessions newest first with status and notes', () async {
      final id = await saveSample();
      final plan = (await recipes.latestApprovedPlan(id))!;
      final first = await sessions.startSession(recipeId: id, planId: plan.id);
      await sessions.complete(first.id, notes: 'יצא מעולה');
      clock.advance(const Duration(days: 1));
      final second = await sessions.startSession(recipeId: id, planId: plan.id);

      final history = await sessions.watchHistory().first;
      expect([for (final h in history) h.session.id], [second.id, first.id]);
      expect(history.last.session.status, SessionStatus.completed);
      expect(history.last.session.notes, 'יצא מעולה');
      expect(history.last.session.endedAt, isNotNull);
      expect(history.first.session.status, SessionStatus.inProgress);
      expect(history.first.recipe.id, id);
    });
  });

  group('sample seeding', () {
    Future<String> loadAsset(String path) async => File(path).readAsString();

    test('seeds once and never re-seeds after the sample is deleted', () async {
      final id = await seedSampleRecipe(recipes: recipes, settings: settings, loadAsset: loadAsset);
      expect(id, isNotNull);
      expect(await recipes.watchRecipes().first, hasLength(1));

      await recipes.softDelete(id!);
      final again = await seedSampleRecipe(recipes: recipes, settings: settings, loadAsset: loadAsset);
      expect(again, isNull);
      expect(await recipes.watchRecipes().first, isEmpty);
    });
  });
}
