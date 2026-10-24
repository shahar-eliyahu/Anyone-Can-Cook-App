import 'dart:io';

import 'package:anyone_can_cook/core/api_client.dart';
import 'package:anyone_can_cook/data/recipe_repository.dart';
import 'package:anyone_can_cook/features/prepare/preparation.dart';
import 'package:anyone_can_cook/models/recipe_bundle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/ui_helpers.dart';

SubstitutionProposal canolaAnswer() => const SubstitutionProposal(
      verdict: 'works',
      explanationHe: 'שמן קנולה מתאים לצלייה בתנור.',
      replacementNameHe: 'שמן קנולה',
      source: SubstitutionSource.ai,
      ops: [
        {'op': 'replace_ingredient', 'ingredient_id': 'i3', 'name': 'שמן קנולה'},
        {'op': 'add_step_note', 'step_id': 's1', 'note_he': 'במקום שמן זית: שמן קנולה'},
        {'op': 'add_step_note', 'step_id': 's2', 'note_he': 'במקום שמן זית: שמן קנולה'},
      ],
    );

Future<void> openSheetFor(WidgetTester tester, String itemName) async {
  await expectSeen(tester, find.text(itemName));
  final row = find.ancestor(of: find.text(itemName), matching: find.byType(ListTile)).first;
  final button = find.descendant(of: row, matching: find.text('חסר לי'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testApp('overview: servings, time, every ingredient and tool, "have all" — offline, no API', (tester, h) async {
    final id = await h.saveFixture('sample_recipe');
    h.api.forbidCalls = true;
    await tester.pumpWidget(h.build(initialLocation: '/recipes/$id'));
    await tester.pumpAndSettle();

    expect(find.text('4 מנות'), findsOneWidget);
    expect(find.textContaining('זמן כולל:'), findsOneWidget);
    await expectSeen(tester, find.text('כרעי עוף'));
    await expectSeen(tester, find.text('סיר בינוני עם מכסה'));
    expect(find.text('מתחילים לבשל'), findsOneWidget);
    expect(find.text('בדיקת התוכנית'), findsNothing);

    await tapText(tester, 'יש לי הכול');
    final prep = (await h.recipes.getRecipe(id))!.preparation;
    expect(prep.statusOf('i1'), ItemStatus.have);
    expect(prep.statusOf('e2'), ItemStatus.have);
    expect(h.api.calls, isEmpty);
  });

  testApp('a missing ingredient: the server suggests, the cook accepts, the plan follows; undo restores', (tester, h) async {
    final id = await h.saveFixture('sample_recipe');
    h.api.substitutions.add(canolaAnswer());
    await tester.pumpWidget(h.build(initialLocation: '/recipes/$id'));
    await tester.pumpAndSettle();

    await openSheetFor(tester, 'שמן זית');
    expect(find.text('אין לכם שמן זית?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'יש לי שמן קנולה');
    await tapText(tester, 'חפשו לי פתרון');
    expect(h.api.calls, ['substitute']);
    expect(h.api.lastSubstituteNote, 'יש לי שמן קנולה');
    expect(find.text('אפשר להחליף'), findsOneWidget);
    await tapText(tester, 'להשתמש בזה');

    await expectSeen(tester, find.text('שמן קנולה'));
    await expectSeen(tester, find.text('במקום שמן זית'));
    final row = (await h.recipes.getRecipe(id))!;
    expect(row.recipe.ingredients.firstWhere((i) => i.id == 'i3').name, 'שמן קנולה');
    expect((await h.recipes.latestApprovedPlan(id))!.plan.stepById('s1')!.notesHe, ['במקום שמן זית: שמן קנולה']);

    // Undo before cooking restores the original.
    await tapText(tester, 'ביטול ההחלפה');
    await expectSeen(tester, find.text('שמן זית'));
    expect((await h.recipes.getRecipe(id))!.recipe.ingredients.firstWhere((i) => i.id == 'i3').name, 'שמן זית');
  });

  testApp('cooking shows the substitution note on the step', (tester, h) async {
    final id = await h.saveFixture('sample_recipe');
    h.api.substitutions.add(canolaAnswer());
    await tester.pumpWidget(h.build(initialLocation: '/recipes/$id'));
    await tester.pumpAndSettle();
    await openSheetFor(tester, 'שמן זית');
    await tapText(tester, 'חפשו לי פתרון');
    await tapText(tester, 'להשתמש בזה');

    await tapButton(tester, 'מתחילים לבשל');
    await expectSeen(tester, find.text('🔄 במקום שמן זית: שמן קנולה'));
    await expectSeen(tester, find.textContaining('שמן קנולה'));
  });

  testApp('a local answer appears at once, without the network', (tester, h) async {
    final bundle = RecipeBundle.decode(File('../shared/fixtures/sample_recipe.json').readAsStringSync());
    final butter = bundle.recipe.copyWith(ingredients: [
      for (final i in bundle.recipe.ingredients) i.id == 'i3' ? i.copyWith(name: 'חמאה') : i,
    ]);
    final id = await h.recipes.saveBundle(RecipeBundle(recipe: butter, plan: bundle.plan), sourceType: 'sample');
    h.api.forbidCalls = true;
    await tester.pumpWidget(h.build(initialLocation: '/recipes/$id'));
    await tester.pumpAndSettle();

    await openSheetFor(tester, 'חמאה');
    expect(find.textContaining('מרגרינה'), findsWidgets);
    await tapText(tester, 'להשתמש בזה');
    await expectSeen(tester, find.text('מרגרינה'));
    expect(h.api.calls, isEmpty);
    expect((await h.recipes.getRecipe(id))!.preparation.substitutions.single.source, SubstitutionSource.local);
  });

  testApp('no reliable substitute: explained honestly, the item stays missing', (tester, h) async {
    final id = await h.saveFixture('sample_recipe');
    h.api.substitutions.add(const SubstitutionProposal(
      verdict: 'no_substitute',
      explanationHe: 'העוף הוא עיקר המנה, ואין לו תחליף שישמור על המתכון.',
      source: SubstitutionSource.ai,
    ));
    await tester.pumpWidget(h.build(initialLocation: '/recipes/$id'));
    await tester.pumpAndSettle();
    await openSheetFor(tester, 'כרעי עוף');
    await tapText(tester, 'חפשו לי פתרון');
    expect(find.text('אין לזה תחליף טוב'), findsOneWidget);
    expect(find.text('להשתמש בזה'), findsNothing);
    await tapText(tester, 'הבנתי');
    expect(find.text('עוד חסר: כרעי עוף'), findsOneWidget);
    expect((await h.recipes.getRecipe(id))!.preparation.substitutions, isEmpty);
    // Cooking is still allowed (the cook may buy it).
    expect(onPressedOf(tester, 'מתחילים לבשל'), isNotNull);
  });

  testApp('offline: the sheet says so in plain Hebrew and nothing changes', (tester, h) async {
    final id = await h.saveFixture('sample_recipe');
    h.api.substitutions.add(const ApiFailure('offline'));
    await tester.pumpWidget(h.build(initialLocation: '/recipes/$id'));
    await tester.pumpAndSettle();
    await openSheetFor(tester, 'שמן זית');
    await tapText(tester, 'חפשו לי פתרון');
    expect(find.textContaining('אין חיבור לאינטרנט'), findsOneWidget);
    expect((await h.recipes.getRecipe(id))!.preparation.substitutions, isEmpty);
  });

  testApp('while the recipe is being cooked, preparation is read-only and cooking can continue', (tester, h) async {
    final id = await h.saveFixture('sample_recipe');
    final plan = (await h.recipes.latestApprovedPlan(id))!;
    final session = await h.sessions.startSession(recipeId: id, planId: plan.id);
    await tester.pumpWidget(h.build(initialLocation: '/recipes/$id'));
    await tester.pumpAndSettle();
    expect(find.textContaining('המתכון בבישול עכשיו'), findsOneWidget);
    expect(find.text('חסר לי'), findsNothing);
    await tapButton(tester, 'המשך בישול');
    expect(find.text('0 מתוך 5 שלבים הושלמו'), findsOneWidget);
    expect(session.recipeId, id);
  });
}
