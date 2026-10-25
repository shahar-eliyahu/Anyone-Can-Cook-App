import 'package:anyone_can_cook/core/api_client.dart';
import 'package:anyone_can_cook/data/recipe_repository.dart';
import 'package:anyone_can_cook/data/settings_repository.dart';
import 'package:anyone_can_cook/features/assistant/assistant_models.dart';
import 'package:anyone_can_cook/features/assistant/assistant_service.dart';
import 'package:anyone_can_cook/features/assistant/conversation_store.dart';
import 'package:anyone_can_cook/features/create/recipe_creation_service.dart';
import 'package:anyone_can_cook/features/import/import_service.dart';
import 'package:anyone_can_cook/models/plan_response.dart';
import 'package:anyone_can_cook/models/provenance.dart';
import 'package:anyone_can_cook/models/recipe_analysis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../assistant/assistant_sheet_test.dart' show typeToRemy;
import '../support/app_harness.dart';
import '../support/sample.dart';
import '../support/ui_helpers.dart';

/// A recipe Remy created: the sample recipe (its canned plan fits it), source "remy".
RecipeAnalysis remyAnalysis({String? title}) {
  final recipe = loadSampleBundle().recipe;
  return RecipeAnalysis(
    isRecipe: true,
    source: const RecipeSourceInfo(type: SourceType.remy),
    recipe: title == null ? recipe : recipe.copyWith(title: title),
  );
}

const cakeOptions = RecipeCreationResult(
  kind: 'options',
  answerHe: 'יש לי כמה רעיונות. מה מתאים לכם?',
  speechHe: 'יש לי כמה רעיונות. מה מתאים לכם?',
  options: ['עוגת שוקולד', 'עוגת וניל', 'עוגת לימון'],
  preferences: {'diet_he': ['צמחוני']},
);

RecipeCreationResult recipeResult({String? title}) => RecipeCreationResult(
      kind: 'recipe',
      answerHe: 'הנה הצעה למתכון. אפשר לעבור עליו לפני ששומרים.',
      speechHe: 'הנה הצעה למתכון.',
      analysis: remyAnalysis(title: title),
      totalMinutes: 80,
      tipsHe: const ['אפשר להכין את האורז בזמן שהעוף בתנור.'],
      preferences: const {'diet_he': ['צמחוני'], 'servings': 4},
    );

const emptyHint = 'ספרו לי מה בא לכם לבשל, או מה יש לכם בבית, ואציע מתכון.';

RecipeCreationService service(AppHarness h) {
  final settings = SettingsRepository(h.db, h.clock.call);
  return RecipeCreationService(
    api: h.api,
    recipes: h.recipes,
    settings: settings,
    store: ConversationStore(settings, h.clock.call),
    imports: ImportService(api: h.api, recipes: h.recipes, images: h.images, settings: settings),
  );
}

/// Creating a recipe with Remy (docs/DECISIONS.md #85–#87): options for a broad request, a draft
/// for a specific one, a review before saving, and the same pipeline as any recipe afterwards.
void main() {
  final sampleTitle = loadSampleBundle().recipe.title;

  testApp('a broad request gets options; a choice gets a draft to review, edit and save', (tester, h) async {
    h.api.creations.addAll([cakeOptions, recipeResult()]);
    h.api.plans.add(PlanResponse(plan: loadSampleBundle().plan));
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();
    await tapText(tester, 'מתכון חדש');
    await tapText(tester, 'רמי יציע מתכון');

    // Text first: the input is ready, the microphone is there but not listening.
    expect(find.text(emptyHint), findsOneWidget);
    expect(find.byTooltip('דיבור עם רמי'), findsOneWidget);
    expect(h.mic.listens, 0);

    await typeToRemy(tester, 'בא לי עוגה');
    expect(find.text('יש לי כמה רעיונות. מה מתאים לכם?'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'עוגת וניל'), findsOneWidget);
    expect(h.api.lastCreation!.preferences, isEmpty);
    expect(await h.db.select(h.db.recipes).get(), isEmpty); // options save nothing

    await tester.tap(find.widgetWithText(OutlinedButton, 'עוגת שוקולד'));
    await tester.pumpAndSettle();
    final second = h.api.lastCreation!;
    expect(second.message, 'עוגת שוקולד');
    expect(second.preferences, {'diet_he': ['צמחוני']}); // remembered from the previous turn
    expect(second.history.map((t) => t['text']), ['בא לי עוגה', 'יש לי כמה רעיונות. מה מתאים לכם?']);

    // The review opened by itself: a draft, not one of the cook's recipes yet.
    expect(find.text('המתכון של רמי'), findsOneWidget);
    expect(find.text(sampleTitle), findsOneWidget);
    expect(find.textContaining('הערכת זמן'), findsOneWidget); // Remy's time is labelled an estimate
    await expectSeen(tester, find.text('אופן ההכנה'));
    final draft = (await h.db.select(h.db.recipes).get()).single;
    expect(draft.status, RecipeStatus.draft);
    expect(draft.analysis!.source.type, SourceType.remy);
    expect(draft.creation.totalMinutes, 80);

    // Edit: a changed amount is the cook's own value.
    await tapText(tester, 'עריכה');
    await tester.enterText(find.widgetWithText(TextField, 'כמות').first, '1.2 ק"ג');
    await tapButton(tester, 'סיום עריכה');
    final edited = (await h.recipes.getRecipe(draft.id))!.analysis!.recipe!.ingredients.first.quantity!;
    expect((edited.display, edited.amount, edited.provenance), ('1.2 ק"ג', 1.2, Provenance.user));

    // Save: planned once like any import, then it is an ordinary recipe.
    await tapButton(tester, 'שמירה במתכונים שלי');
    expect(h.api.calls, ['createRecipeTurn', 'createRecipeTurn', 'plan']);
    expect(h.api.lastPlanRequest!.source.type, SourceType.remy);
    final saved = (await h.recipes.getRecipe(draft.id))!;
    expect(saved.status, RecipeStatus.ready);
    expect(find.text('מתחילים לבשל'), findsOneWidget); // its overview
    expect(await SettingsRepository(h.db, h.clock.call).get(ConversationStore.keyFor(draft.id)), isNull);

    // Its own Remy starts a fresh conversation about the saved recipe.
    await tester.tap(find.byTooltip('רמי, העוזר שלך לבישול'));
    await tester.pumpAndSettle();
    expect(find.text('בא לי עוגה'), findsNothing);
    expect(find.text('אפשר לשאול אותי כל דבר על המתכון.'), findsOneWidget);
  });

  testApp('a saved recipe from Remy prepares and cooks like any recipe', (tester, h) async {
    h.api.creations.add(recipeResult());
    h.api.plans.add(PlanResponse(plan: loadSampleBundle().plan));
    final id = await service(h).currentConversation();
    await service(h).turn(id, const AssistantInput('עוף עם תפוחי אדמה'));
    await service(h).save(id);
    await tester.pumpWidget(h.build(initialLocation: '/recipes/$id'));
    await tester.pumpAndSettle();
    await tapText(tester, 'יש לי הכול');
    await tapButton(tester, 'מתחילים לבשל');
    final session = (await h.sessions.activeSession())!;
    expect(session.recipeId, id);
    expect(find.text('הכנת תפוחי האדמה'), findsWidgets);
  });

  testApp('discarding a draft from Remy removes it with its conversation', (tester, h) async {
    h.api.creations.add(recipeResult());
    await tester.pumpWidget(h.build(initialLocation: '/create'));
    await tester.pumpAndSettle();
    await typeToRemy(tester, 'עוף עם תפוחי אדמה');
    final id = (await h.db.select(h.db.recipes).get()).single.id;
    await tapText(tester, 'ביטול המתכון');
    await tester.tap(find.widgetWithText(FilledButton, 'ביטול המתכון'));
    await tester.pumpAndSettle();
    expect(await h.db.select(h.db.recipes).get(), isEmpty);
    expect(await SettingsRepository(h.db, h.clock.call).get(ConversationStore.keyFor(id)), isNull);
    expect(find.text('מתכונים שהתחלתם להוסיף'), findsNothing); // gone from home too
  });

  testApp('the creation conversation is kept when leaving and after a restart; "שיחה חדשה" starts over', (tester, h) async {
    h.api.creations.add(cakeOptions);
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();
    await tapText(tester, 'מתכון חדש');
    await tapText(tester, 'רמי יציע מתכון');
    await typeToRemy(tester, 'משהו לערב');
    GoRouter.of(tester.element(find.byType(Scaffold).last)).pop();
    await tester.pumpAndSettle();
    await tapText(tester, 'רמי יציע מתכון');
    expect(find.text('משהו לערב'), findsOneWidget);

    await tester.pumpWidget(const SizedBox()); // a new app run over the same database
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(h.build(initialLocation: '/create'));
    await tester.pumpAndSettle();
    expect(find.text('משהו לערב'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'עוגת לימון'), findsOneWidget);

    await tester.tap(find.byTooltip('שיחה חדשה'));
    await tester.pumpAndSettle();
    expect(find.text('משהו לערב'), findsNothing);
    expect(find.text(emptyHint), findsOneWidget);
  });

  group('the service', () {
    test('a broad request: options, no draft; a specific one: a draft with the conversation id', () async {
      final h = AppHarness();
      addTearDown(h.db.close);
      final s = service(h);
      final id = await s.currentConversation();
      h.api.creations.addAll([cakeOptions, recipeResult()]);
      final (options, prefs) = await s.turn(id, const AssistantInput('בא לי עוגה'));
      expect(options.options, hasLength(3));
      expect(options.recipeId, isNull);
      expect(prefs, {'diet_he': ['צמחוני']});
      expect(await h.recipes.getRecipe(id), isNull);

      final (made, _) = await s.turn(id, const AssistantInput('עוגת שוקולד'), preferences: prefs);
      expect(made.recipeId, id);
      final row = (await h.recipes.getRecipe(id))!;
      expect(row.isDraft, isTrue);
      expect(await h.recipes.watchRecipes().first, isEmpty); // not the cook's recipe until saved
      expect(await SettingsRepository(h.db, h.clock.call).get(SettingKeys.remyCreation), isNull);
      expect(await s.currentConversation(), isNot(id)); // the next idea is a new conversation
    });

    test('refining sends the current draft, and updates that same draft', () async {
      final h = AppHarness();
      addTearDown(h.db.close);
      final s = service(h);
      final id = await s.currentConversation();
      h.api.creations.addAll([recipeResult(), recipeResult(title: 'עוף בתנור בלי אורז')]);
      await s.turn(id, const AssistantInput('עוף עם תפוחי אדמה'));
      expect(h.api.lastCreation!.currentRecipe, isNull);
      await s.turn(id, const AssistantInput('בלי אורז'));
      final sent = h.api.lastCreation!.currentRecipe!;
      expect(sent['title'], sampleTitle);
      expect((sent['ingredients_he'] as List).first, 'כרעי עוף: 1 ק"ג');
      expect(sent.keys, unorderedEquals(['title', 'ingredients_he', 'steps_he'])); // short, not the record
      final rows = await h.db.select(h.db.recipes).get();
      expect(rows.single.title, 'עוף בתנור בלי אורז');
      expect(rows.single.planStale, isTrue);
    });

    test('incomplete or malformed recipes never become drafts; failures are friendly; one call each', () async {
      final h = AppHarness();
      addTearDown(h.db.close);
      final s = service(h);
      final id = await s.currentConversation();
      final incomplete = RecipeAnalysis(
        isRecipe: true,
        source: const RecipeSourceInfo(type: SourceType.remy),
        recipe: loadSampleBundle().recipe.copyWith(ingredients: const []),
      );
      h.api.creations.addAll([
        RecipeCreationResult(kind: 'recipe', answerHe: 'הנה', speechHe: 'הנה', analysis: incomplete),
        RecipeCreationResult.fromJson({'kind': 'recipe', 'answer_he': 'הנה', 'analysis': {'is_recipe': 'כן'}}),
        const ApiFailure('invalid_ai_output'),
        const ApiFailure('offline'),
        const ApiFailure('ai_quota_exhausted'),
      ]);
      final replies = [for (var i = 0; i < 5; i++) (await s.turn(id, const AssistantInput('עוגת שוקולד'))).$1.answerHe];
      expect(replies, [
        'לא הצלחתי להרכיב מתכון שלם הפעם. אפשר לנסות שוב, או לתאר במילים אחרות מה בא לכם.',
        'לא הצלחתי להרכיב מתכון שלם הפעם. אפשר לנסות שוב, או לתאר במילים אחרות מה בא לכם.',
        'לא הצלחתי להרכיב מתכון שלם הפעם. אפשר לנסות שוב, או לתאר במילים אחרות מה בא לכם.',
        startsWith('אין חיבור לאינטרנט'),
        startsWith('אני לא זמין כרגע'),
      ]);
      expect(h.api.calls, hasLength(5)); // no retries
      expect(await h.db.select(h.db.recipes).get(), isEmpty);
    });

    test('what Gemini receives: the stage, this conversation\'s preferences and at most 6 short turns', () async {
      final h = AppHarness();
      addTearDown(h.db.close);
      h.api.creations.add(cakeOptions);
      final history = [for (var i = 0; i < 10; i++) ChatTurn(fromUser: i.isEven, textHe: 'א' * 700)];
      await service(h).turn('c1', const AssistantInput('בא לי עוגה'), history: history, preferences: const {'servings': 2});
      final sent = h.api.lastCreation!;
      expect(sent.history, hasLength(AssistantService.maxHistoryTurns));
      expect(sent.history.every((t) => t['text']!.length <= AssistantService.maxTurnChars), isTrue);
      expect(sent.preferences, {'servings': 2});
      expect(sent.currentRecipe, isNull); // no draft yet: nothing else about recipes is sent
    });

    test('creation conversations are isolated from each other and from recipes, and expire', () async {
      final h = AppHarness();
      addTearDown(h.db.close);
      final s = service(h);
      final store = ConversationStore(SettingsRepository(h.db, h.clock.call), h.clock.call);
      final first = await s.currentConversation();
      await store.save(first, const [ChatMessage(fromUser: true, textHe: 'בא לי עוגה')], context: const {'servings': 2});
      expect(await s.currentConversation(), first); // continued while it has messages and no draft
      final second = await s.startOver(first);
      expect(second, isNot(first));
      expect(await store.load(second), isEmpty);
      expect(await store.load(first), isEmpty); // it had no draft: forgotten
      final recipeId = await h.seedSample();
      expect(await store.load(recipeId), isEmpty);

      await store.save(second, const [ChatMessage(fromUser: true, textHe: 'משהו מהיר')], context: const {'max_minutes': 20});
      expect(await store.loadContext(second), {'max_minutes': 20});
      h.clock.advance(const Duration(hours: 13));
      expect(await s.currentConversation(), isNot(second)); // expired
      expect(await store.loadContext(second), isEmpty);
    });

    test('a malformed recipe in the response is dropped while reading it', () {
      final r = RecipeCreationResult.fromJson({
        'kind': 'recipe',
        'answer_he': 'הנה',
        'speech_he': 'הנה',
        'options_he': ['', 'א'],
        'analysis': {'is_recipe': true},
      });
      expect(r.analysis, isNull);
      expect(r.options, ['א']);
    });
  });

  test('stored conversations keep options and the draft link', () {
    const m = ChatMessage(fromUser: false, textHe: 'הנה', options: ['א', 'ב'], recipeId: 'd1');
    final back = ChatMessage.fromJson(m.toJson());
    expect(back.options, ['א', 'ב']);
    expect(back.recipeId, 'd1');
  });
}
