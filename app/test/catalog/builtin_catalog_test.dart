import 'dart:convert';
import 'dart:io';

import 'package:anyone_can_cook/data/recipe_repository.dart';
import 'package:anyone_can_cook/features/catalog/builtin_catalog.dart';
import 'package:anyone_can_cook/features/cooking/engine/action_dispatcher.dart';
import 'package:anyone_can_cook/features/cooking/engine/cooking_engine.dart';
import 'package:anyone_can_cook/features/cooking/engine/events.dart';
import 'package:anyone_can_cook/features/cooking/engine/plan_validator.dart';
import 'package:anyone_can_cook/features/prepare/preparation.dart';
import 'package:anyone_can_cook/features/prepare/preparation_service.dart';
import 'package:flutter/material.dart' hide ActionDispatcher;
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/sample.dart';
import '../support/ui_helpers.dart';

BuiltinCatalog loadCatalog() => BuiltinCatalog.decode(File(catalogAsset).readAsStringSync());

/// The built-in recipes (docs/DECISIONS.md #84): bundled, valid for the engine, kept apart from
/// the cook's own recipes, and cooked through the usual overview, preparation and cooking.
void main() {
  final catalog = loadCatalog();

  group('the catalog', () {
    test('loads 20 to 30 recipes with unique ids, every category in use', () {
      expect(catalog.entries.length, inInclusiveRange(20, 30));
      expect(catalog.entries.map((e) => e.id).toSet(), hasLength(catalog.entries.length));
      for (final c in CatalogCategory.values) {
        expect(catalog.search(category: c).length, greaterThanOrEqualTo(2), reason: c.name);
      }
    });

    test('every recipe is complete and its plan is valid for the engine', () {
      for (final e in catalog.entries) {
        final r = e.recipe;
        expect(r.title, isNotEmpty);
        expect(r.servings, isNotNull, reason: e.id);
        expect(r.ingredients, isNotEmpty, reason: e.id);
        expect(r.equipment, isNotEmpty, reason: e.id);
        expect(r.sourceSteps, hasLength(e.bundle.plan.steps.length), reason: e.id);
        expect(validatePlan(e.bundle.plan, recipe: r), isEmpty, reason: e.id);
        expect(e.estimate.totalMinutes, greaterThan(0), reason: e.id);
        // Steps refer only to what the recipe lists.
        final used = {for (final s in e.bundle.plan.steps) ...s.ingredientIds};
        expect(used.difference({for (final i in r.ingredients) i.id}), isEmpty, reason: e.id);
      }
    });

    test('meat, poultry and fish are checked before they are served', () {
      for (final e in catalog.search(category: CatalogCategory.chicken) + [catalog.byId('baked-salmon')!]) {
        final asks = e.bundle.plan.steps.where((s) => s.actions.any((a) => a.completesStep && a.confirmPolicy.name == 'alwaysAsk'));
        expect(asks, isNotEmpty, reason: e.id);
        expect(asks.every((s) => s.donenessCueHe != null), isTrue, reason: e.id);
      }
    });

    test('every plan can be cooked to the end by the engine', () async {
      for (final e in catalog.entries) {
        final clock = FakeClock();
        final store = MemoryEventStore();
        final started = SessionStarted(clock.now);
        final dispatcher = ActionDispatcher(
          state: CookingEngine.reduce(CookingEngine.initial(e.bundle.plan), started).state,
          store: store,
          onEffects: (_) async {},
          clock: clock.call,
        );
        for (var i = 0; i < 200 && !dispatcher.state.isComplete; i++) {
          for (final p in dispatcher.state.pendingPrepTasks()) {
            await dispatcher.completePrepTask(p.id);
          }
          final next = dispatcher.state.availableActions(dispatcher.now()).firstOrNull;
          if (next == null) {
            clock.advance(const Duration(hours: 3)); // timers end
            continue;
          }
          await dispatcher.confirmAction(next.step.id, next.action.id);
        }
        expect(dispatcher.state.isComplete, isTrue, reason: e.id);
      }
    });

    test('Hebrew text uses no dash separators', () {
      final strings = <String>[];
      void collect(Object? v) => switch (v) {
            final String s => strings.add(s),
            final Map<String, dynamic> m => m.values.forEach(collect),
            final List<dynamic> l => l.forEach(collect),
            _ => null,
          };
      collect(jsonDecode(File(catalogAsset).readAsStringSync()));
      expect(strings.where((s) => RegExp(r'[—–]|\s-\s').hasMatch(s)), isEmpty);
    });

    test('search by title or ingredient, within a category', () {
      expect(catalog.search(query: 'שוקולד').map((e) => e.id), containsAll(['chocolate-cake', 'chocolate-chip-cookies']));
      expect(catalog.search(query: 'עוף', category: CatalogCategory.quick).map((e) => e.id), contains('chicken-breast-pan'));
      expect(catalog.search(query: 'אין מתכון כזה'), isEmpty);
    });
  });

  group('storage', () {
    test('a built-in recipe is kept apart from the cook\'s recipes and drafts, and survives draft cleanup', () async {
      final h = AppHarness();
      addTearDown(h.db.close);
      final builtin = BuiltinRecipes(recipes: h.recipes, sessions: h.sessions);
      final id = await builtin.open(catalog.byId('shakshuka')!);
      expect((await h.recipes.getRecipe(id))!.status, RecipeStatus.builtin);
      expect(await h.recipes.watchRecipes().first, isEmpty);
      expect(await h.recipes.watchDrafts().first, isEmpty);
      expect(await builtin.open(catalog.byId('shakshuka')!), id); // reused, not duplicated
      h.clock.advance(const Duration(days: 30));
      await h.recipes.purgeOldDrafts();
      expect(await h.recipes.getRecipe(id), isNotNull);
      expect(await h.recipes.latestApprovedPlan(id), isNotNull);
    });

    test('after a finished cooking the working copy starts fresh; one being prepared is kept', () async {
      final h = AppHarness();
      addTearDown(h.db.close);
      final builtin = BuiltinRecipes(recipes: h.recipes, sessions: h.sessions);
      final entry = catalog.byId('omelette')!;
      final id = await builtin.open(entry);
      await h.recipes.savePreparation(id, const Preparation(items: {'i2': ItemStatus.missing}));
      h.clock.advance(const Duration(minutes: 1));
      expect(await builtin.open(entry), id);
      expect((await h.recipes.getRecipe(id))!.preparation.statusOf('i2'), ItemStatus.missing); // still preparing

      final plan = (await h.recipes.latestApprovedPlan(id))!;
      final session = await h.sessions.startSession(recipeId: id, planId: plan.id);
      h.clock.advance(const Duration(minutes: 10));
      await h.sessions.complete(session.id);
      h.clock.advance(const Duration(days: 2));
      expect(await builtin.open(entry), id);
      final row = (await h.recipes.getRecipe(id))!;
      expect(row.preparation.statusOf('i2'), ItemStatus.unknown);
      expect(row.isBuiltin, isTrue);
      expect((await h.sessions.getSession(session.id))!.status, 'completed'); // history stays
    });

    test('saving to "המתכונים שלי" makes a separate personal copy', () async {
      final h = AppHarness();
      addTearDown(h.db.close);
      final builtin = BuiltinRecipes(recipes: h.recipes, sessions: h.sessions);
      final id = await builtin.open(catalog.byId('pancakes')!);
      final copy = await builtin.copyToMyRecipes(id);
      expect(copy, isNot(id));
      final mine = await h.recipes.watchRecipes().first;
      expect(mine.single.id, copy);
      expect(mine.single.status, RecipeStatus.ready);
      expect(PreparationService.analysisOf(mine.single).recipe!.title, 'פנקייק');
      expect((await h.recipes.getRecipe(id))!.isBuiltin, isTrue); // the built-in one is unchanged
    });
  });

  testApp('browse, open a built-in recipe, prepare it and start cooking', (tester, h) async {
    h.api.forbidCalls = true; // all local
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();
    await tapText(tester, 'מתכון חדש');
    expect(find.text('מה בא לכם לבשל?'), findsOneWidget);
    expect(find.text('רמי יציע מתכון'), findsOneWidget);
    expect(find.text('מתכון משלי'), findsOneWidget);
    await tapText(tester, 'מתכונים מוכנים');

    await tester.enterText(find.byType(TextField), 'שקשוקה');
    await tester.pumpAndSettle();
    expect(find.text('עוגת שוקולד'), findsNothing);
    await tester.tap(find.widgetWithText(ListTile, 'שקשוקה')); // the recipe, not the search text
    await tester.pumpAndSettle();

    // The usual overview, marked as a built-in recipe, with nothing that would change it.
    expect(find.text('מתכון מהאוסף'), findsOneWidget);
    expect(find.byTooltip('הוספה למועדפים'), findsNothing);
    await tester.tap(find.byTooltip('פעולות למתכון'));
    await tester.pumpAndSettle();
    expect(find.text('מחיקת המתכון'), findsNothing);
    expect(find.text('עריכה מתקדמת'), findsNothing);
    expect(find.text('כל שלבי הבישול'), findsOneWidget);
    Navigator.of(tester.element(find.text('כל שלבי הבישול'))).pop(); // close the menu
    await tester.pumpAndSettle();

    await tapText(tester, 'יש לי הכול');
    await tapButton(tester, 'מתחילים לבשל');
    expect(find.text('חיתוך הירקות'), findsWidgets); // the first step of its plan
    final session = (await h.sessions.activeSession())!;
    expect((await h.recipes.getRecipe(session.recipeId))!.isBuiltin, isTrue);
    // Plain query: drift watch streams never emit inside testWidgets.
    expect((await h.db.select(h.db.recipes).get()).where((r) => r.status == RecipeStatus.ready), isEmpty);
  });

  testApp('a built-in recipe can be saved as the cook\'s own', (tester, h) async {
    final id = await BuiltinRecipes(recipes: h.recipes, sessions: h.sessions).open(catalog.byId('white-rice')!);
    await tester.pumpWidget(h.build(initialLocation: '/recipes/$id'));
    await tester.pumpAndSettle();
    await tapText(tester, 'שמירה במתכונים שלי');
    expect(find.text('המתכון נשמר במתכונים שלכם'), findsOneWidget);
    expect(find.text('מתכון מהאוסף'), findsNothing); // now on the copy
    final mine = await h.db.select(h.db.recipes).get();
    expect(mine.where((r) => r.status == RecipeStatus.ready), hasLength(1));
  });
}
