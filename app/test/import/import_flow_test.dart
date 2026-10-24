import 'package:anyone_can_cook/core/api_client.dart';
import 'package:anyone_can_cook/core/db/database.dart';
import 'package:anyone_can_cook/data/recipe_repository.dart';
import 'package:anyone_can_cook/data/settings_repository.dart';
import 'package:anyone_can_cook/features/import/import_service.dart' show findLink;
import 'package:anyone_can_cook/models/plan_response.dart';
import 'package:anyone_can_cook/models/recipe_analysis.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/app_harness.dart';
import '../support/sample.dart';
import '../support/ui_helpers.dart';

RecipeAnalysis analysis({SourceType type = SourceType.text, List<Question> questions = const []}) => RecipeAnalysis(
      isRecipe: true,
      source: RecipeSourceInfo(type: type),
      sourceText: 'מתכון',
      recipe: loadSampleBundle().recipe,
      questions: questions,
    );

final planResponse = PlanResponse(plan: loadSampleBundle().plan, limitationsHe: const ['לא ידוע גודל התבנית']);

// Plain queries: drift watch streams never emit inside testWidgets' fake async zone.
Future<List<RecipeRow>> allRecipes(AppHarness h) => h.db.select(h.db.recipes).get();

Future<void> acceptPrivacy(AppHarness h) =>
    SettingsRepository(h.db, h.clock.call).set(SettingKeys.importPrivacyAccepted, 'true');

void main() {
  final title = loadSampleBundle().recipe.title;

  testApp('text import: privacy notice once, simple overview, start cooking with zero further API calls',
      (tester, h) async {
    h.api.analyses.add(analysis());
    h.api.plans.add(planResponse);
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    await tapText(tester, 'מתכון חדש');
    expect(find.text('לפני הייבוא הראשון'), findsOneWidget);
    await tapText(tester, 'הבנתי, להמשיך');
    expect(await SettingsRepository(h.db, h.clock.call).get(SettingKeys.importPrivacyAccepted), 'true');

    await tester.enterText(find.byType(TextField), 'כרעי עוף בתנור עם אורז');
    await tapText(tester, 'קריאת המתכון');

    // Overview, not a detailed review: a short "שימו לב" card; a limitation needs one acknowledgement.
    expect(find.text('בדיקת התוכנית'), findsNothing);
    expect(find.text(title), findsWidgets);
    await expectSeen(tester, find.text('שימו לב'));
    await expectSeen(tester, find.text('• לא ידוע גודל התבנית'));
    expect(onPressedOf(tester, 'מתחילים לבשל'), isNull);
    await tapText(tester, 'קראתי');
    expect(onPressedOf(tester, 'מתחילים לבשל'), isNotNull);
    expect(h.api.calls, ['analyzeText', 'plan']);

    // Starting approves the draft and cooks — no further API calls.
    h.api.forbidCalls = true;
    await tapButton(tester, 'מתחילים לבשל');
    await expectSeen(tester, find.textContaining(loadSampleBundle().plan.steps.first.title));
    expect(h.api.calls, ['analyzeText', 'plan']);
    expect((await allRecipes(h)).where((r) => r.title == title).single.status, RecipeStatus.ready);
  });

  testApp('a question answered "I don\'t know" is not asked again: the plan is generated', (tester, h) async {
    await acceptPrivacy(h);
    h.api.analyses.add(analysis(questions: const [
      Question(
        id: 'q1',
        textHe: 'מה גודל התבנית?',
        whyHe: 'משנה את זמן האפייה',
        kind: QuestionKind.number,
        unitHe: 'ס"מ',
        category: GapCategory.outcome,
      ),
    ]));
    h.api.plans.add(planResponse);
    await tester.pumpWidget(h.build(initialLocation: '/import'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'עוגה');
    await tapText(tester, 'קריאת המתכון');
    expect(find.text('מה גודל התבנית?'), findsOneWidget);
    expect(h.api.calls, ['analyzeText']);

    await tapText(tester, 'לא בטוח/ה, תחליטו בשבילי');
    expect(find.byType(TextField), findsNothing);
    await tapText(tester, 'בניית התוכנית');

    await expectSeen(tester, find.text('מתחילים לבשל'));
    expect(h.api.calls, ['analyzeText', 'plan']);
    expect(h.api.lastPlanRequest!.answers, const [Answer(questionId: 'q1', unknown: true)]);
  });

  testApp('photo import: the photo is kept until the recipe is saved, then deleted', (tester, h) async {
    await acceptPrivacy(h);
    h.pickedPhoto = '/picked/recipe.jpg';
    h.api.analyses.add(analysis(type: SourceType.image));
    h.api.plans.add(planResponse);
    await tester.pumpWidget(h.build(initialLocation: '/import'));
    await tester.pumpAndSettle();

    await tapText(tester, 'תמונה');
    await tapText(tester, 'מהגלריה');
    expect(h.images.saved, {'/images/1.jpg'});
    await tapText(tester, 'קריאת המתכון');

    expect(h.api.calls, ['analyzeImage', 'plan']);
    await expectSeen(tester, find.textContaining('המתכון נקרא מתמונה'));
    final draft = (await allRecipes(h)).single;
    expect(draft.sourceImagePath, '/images/1.jpg');

    await tapText(tester, 'קראתי');
    await tapText(tester, 'שמירה במתכונים שלי');
    expect(h.images.deleted, ['/images/1.jpg']);
    expect((await h.recipes.getRecipe(draft.id))!.sourceImagePath, isNull);
  });

  testApp('offline: a Hebrew message, the text is kept, nothing is saved', (tester, h) async {
    await acceptPrivacy(h);
    h.api.analyses.add(const ApiFailure('offline'));
    await tester.pumpWidget(h.build(initialLocation: '/import'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'מרק עדשים');
    await tapText(tester, 'קריאת המתכון');
    await expectSeen(tester, find.textContaining('אין חיבור לאינטרנט'));
    expect(find.text('מרק עדשים'), findsOneWidget);
    expect(await allRecipes(h), isEmpty);
  });

  testApp('an edit the plan cannot absorb blocks cooking until the plan is re-checked', (tester, h) async {
    final id = await h.saveFixture('sample_recipe');
    h.api.forbidCalls = true;
    final firstPlan = (await h.recipes.latestApprovedPlan(id))!;
    final lastSource = loadSampleBundle().recipe.sourceSteps.last.text;
    await tester.pumpWidget(h.build(initialLocation: '/recipes/$id/edit'));
    await tester.pumpAndSettle();

    // Correct an original instruction: the plan was built from it.
    await expectSeen(tester, find.text(lastSource));
    final edit = find.byTooltip('עריכת הוראה').last;
    await tester.ensureVisible(edit);
    await tester.pumpAndSettle();
    await tester.tap(edit);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), 'מגישים חם עם לימון.');
    await tapText(tester, 'שמירה');

    await expectSeen(tester, find.text('התוכנית לא מעודכנת לשינויים במתכון'));
    expect((await h.recipes.getRecipe(id))!.planStale, isTrue);

    // The recipe can't be cooked while its plan is out of date.
    await tester.pumpWidget(h.build(initialLocation: '/recipes/$id'));
    await tester.pumpAndSettle();
    await expectSeen(tester, find.textContaining('התוכנית לא מעודכנת לשינויים שעשיתם'));
    expect(onPressedOf(tester, 'מתחילים לבשל'), isNull);

    // Re-check it by hand in advanced editing, approve, and cooking is available again.
    await tester.tap(find.byWidgetPredicate((w) => w is PopupMenuButton).first);
    await tester.pumpAndSettle();
    await tapText(tester, 'עריכה מתקדמת');
    await tapText(tester, 'בדקתי, התוכנית נכונה');
    expect(find.text('התוכנית לא מעודכנת לשינויים במתכון'), findsNothing);
    await tapText(tester, 'בדקתי את הערכים המסומנים');
    await tapText(tester, 'אישור התוכנית');
    await expectSeen(tester, find.text('מתחילים לבשל'));
    expect(onPressedOf(tester, 'מתחילים לבשל'), isNotNull);

    final row = (await h.recipes.getRecipe(id))!;
    expect(row.planStale, isFalse);
    expect(row.recipe.sourceSteps.last.text, 'מגישים חם עם לימון.');
    final approved = (await h.recipes.latestApprovedPlan(id))!;
    expect(approved.basedOnPlanId, firstPlan.id);
    expect(h.api.calls, isEmpty);
    expect(row.status, RecipeStatus.ready);
  });

  testApp('AI quota used up: a clear message, no time promised, input kept after leaving, one-tap retry later',
      (tester, h) async {
    await acceptPrivacy(h);
    h.api.analyses.addAll([const ApiFailure('ai_quota_exhausted'), analysis()]);
    h.api.plans.add(planResponse);
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();
    await tapText(tester, 'מתכון חדש');
    await tester.enterText(find.byType(TextField), 'שקשוקה לארבעה');
    await tapText(tester, 'קריאת המתכון');

    await expectSeen(tester, find.textContaining('מכסת השימוש היומית'));
    await expectSeen(tester, find.textContaining('המתכונים השמורים והבישול ממשיכים לעבוד'));
    expect(find.textContaining('דקה'), findsNothing); // no reset time is promised
    expect(find.text('שקשוקה לארבעה'), findsOneWidget);
    expect(h.api.calls, ['analyzeText']); // not retried automatically

    // Leave and come back later: the input is restored.
    GoRouter.of(tester.element(find.byType(Scaffold).last)).pop();
    await tester.pumpAndSettle();
    await tapText(tester, 'מתכון חדש');
    expect(find.text('שקשוקה לארבעה'), findsOneWidget);
    await expectSeen(tester, find.text('שחזרנו את מה שהזנתם בניסיון הקודם.'));

    // The service is back: one retry goes through.
    await tapText(tester, 'קריאת המתכון');
    await expectSeen(tester, find.text('מתחילים לבשל'));
    expect(h.api.calls, ['analyzeText', 'analyzeText', 'plan']);
  });

  testApp('a short rate limit shows a wait time only when the server stated one', (tester, h) async {
    await acceptPrivacy(h);
    h.api.analyses.addAll([
      const ApiFailure('ai_rate_limited', retryAfterSeconds: 90),
      const ApiFailure('ai_rate_limited'),
    ]);
    await tester.pumpWidget(h.build(initialLocation: '/import'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'עוגת גבינה');
    await tapText(tester, 'קריאת המתכון');
    await expectSeen(tester, find.textContaining("בעוד כ-2 דק'"));

    await tapText(tester, 'נסו שוב');
    await expectSeen(tester, find.textContaining('נסו שוב בעוד כמה דקות'));
    expect(find.textContaining("בעוד כ-"), findsNothing);
    expect(h.api.calls, ['analyzeText', 'analyzeText']); // one call per tap, never automatic
  });

  testApp('quota used up while planning: the recipe is kept and only the plan is retried', (tester, h) async {
    await acceptPrivacy(h);
    h.api.analyses.add(analysis());
    h.api.plans.addAll([const ApiFailure('ai_quota_exhausted'), planResponse]);
    await tester.pumpWidget(h.build(initialLocation: '/import'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'עוף בתנור');
    await tapText(tester, 'קריאת המתכון');

    await expectSeen(tester, find.textContaining('מכסת השימוש היומית'));
    await expectSeen(tester, find.textContaining('המתכון נקרא ונשמר'));
    expect((await allRecipes(h)).single.status, RecipeStatus.draft);

    await tapText(tester, 'נסו שוב');
    await expectSeen(tester, find.text('מתחילים לבשל'));
    expect(h.api.calls, ['analyzeText', 'plan', 'plan']); // no second analysis
  });

  group("shared links that can't be read", () {
    const resolved = 'https://chef-lavan.co.il/%D7%A2%D7%95%D7%92%D7%94/';
    const blocked = ApiFailure('site_blocked', site: 'chef-lavan.co.il', resolvedUrl: resolved);

    Future<void> openLinkTab(WidgetTester tester, AppHarness h) async {
      await acceptPrivacy(h);
      await tester.pumpWidget(h.build(initialLocation: '/import'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('קישור'));
      await tester.pumpAndSettle();
    }

    testApp('a protected site: named, the full address can be copied, pasting the text is one tap away',
        (tester, h) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      h.api.analyses.add(blocked);
      await openLinkTab(tester, h);
      await tester.enterText(find.byType(TextField), 'עוגת ביסקוויטים קרה https://share.google/8zYO39TZnZUazYh3t');
      await tapText(tester, 'קריאת המתכון');

      expect(h.api.lastUrl, 'https://share.google/8zYO39TZnZUazYh3t'); // the link out of the shared text
      await expectSeen(tester, find.textContaining('האתר chef-lavan.co.il לא מאפשר לאפליקציות לקרוא'));
      expect(find.text('הקישור מוביל אל chef-lavan.co.il.'), findsOneWidget);
      expect(find.textContaining('share.google'), findsOneWidget); // the cook's link stays in its field
      expect(await allRecipes(h), isEmpty);

      await tapText(tester, 'העתקת הכתובת המלאה');
      expect(copied, [resolved]);
      expect(find.text('הכתובת הועתקה. אפשר לפתוח אותה בדפדפן.'), findsOneWidget);

      await tapText(tester, 'להדביק את טקסט המתכון');
      expect(find.text('הדביקו או הקלידו כאן את המתכון'), findsOneWidget); // the text tab, ready
      await tester.tap(find.text('קישור'));
      await tester.pumpAndSettle();
      expect(find.textContaining('share.google/8zYO39TZnZUazYh3t'), findsOneWidget); // nothing lost
    });

    testApp('a short link that needs a browser explains what to do, and the link is kept for later', (tester, h) async {
      h.api.analyses.add(const ApiFailure('link_unresolved', site: 'bit.ly'));
      await openLinkTab(tester, h);
      await tester.enterText(find.byType(TextField), 'https://bit.ly/abc');
      await tapText(tester, 'קריאת המתכון');
      await expectSeen(tester, find.textContaining('לא הצלחנו לפתוח את הקישור המשותף'));
      expect(find.text('להדביק את טקסט המתכון'), findsOneWidget);
      expect(find.text('העתקת הכתובת המלאה'), findsNothing); // nothing resolved to copy

      // Leaving and coming back: the link is restored.
      GoRouter.of(tester.element(find.byType(Scaffold).last)).pop();
      await tester.pumpAndSettle();
      await tapText(tester, 'מתכון חדש');
      expect(find.text('https://bit.ly/abc'), findsOneWidget);
      await expectSeen(tester, find.text('שחזרנו את מה שהזנתם בניסיון הקודם.'));
    });

    testApp('a protected site without details falls back to the general message', (tester, h) async {
      h.api.analyses.add(const ApiFailure('site_blocked'));
      await openLinkTab(tester, h);
      await tester.enterText(find.byType(TextField), 'https://example.com/r');
      await tapText(tester, 'קריאת המתכון');
      await expectSeen(tester, find.textContaining('האתר לא מאפשר לקרוא את הדף'));
      expect(find.textContaining('הקישור מוביל אל'), findsNothing);
    });
  });

  test('the first web address is taken from shared text', () {
    expect(findLink('עוגה https://share.google/abc.'), 'https://share.google/abc');
    expect(findLink('(https://chef.example/r?id=1)'), 'https://chef.example/r?id=1');
    expect(findLink('https://a.example/x‏'), 'https://a.example/x');
    expect(findLink('אין כאן קישור'), isNull);
  });
}
