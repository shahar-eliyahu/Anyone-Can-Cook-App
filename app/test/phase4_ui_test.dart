import 'package:anyone_can_cook/core/api_client.dart';
import 'package:anyone_can_cook/data/recipe_repository.dart';
import 'package:anyone_can_cook/features/kitchen/kitchen_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/app_harness.dart';
import 'support/ui_helpers.dart';

/// Phase 4 (docs/DESIGN.md): navigation that never strands the cook, RTL direction, layout
/// that survives small screens, big text and the keyboard, reduced motion, and Remy
/// before cooking.
void main() {
  Future<String> startSession(AppHarness h) async {
    final recipeId = await h.seedSample();
    final plan = (await h.recipes.latestApprovedPlan(recipeId))!;
    return (await h.sessions.startSession(recipeId: recipeId, planId: plan.id)).id;
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.text('תפריט'));
    await tester.pumpAndSettle();
  }

  void phone(WidgetTester tester, {double textScale = 1}) {
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  testApp('a deep link (a notification) still has a way back home, and back keeps cooking', (tester, h) async {
    final sessionId = await startSession(h);
    await tester.pumpWidget(h.build(initialLocation: '/cook/$sessionId'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);

    // Android back from inside the flow goes home, not out of the app.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(KitchenScreen), findsOneWidget);
    expect(find.text('מבשלים עכשיו'), findsOneWidget);
    expect((await h.sessions.activeSession())?.id, sessionId);
  });

  testApp('the end of a flow (go) keeps a real back stack: history detail → history → home', (tester, h) async {
    final sessionId = await startSession(h);
    await h.sessions.abandon(sessionId);
    await tester.pumpWidget(h.build(initialLocation: '/history/$sessionId'));
    await tester.pumpAndSettle();
    await expectSeen(tester, find.text('לבשל שוב'));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('היסטוריית בישול'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(KitchenScreen), findsOneWidget);
  });

  testApp('the menu lives on home: one labelled tap, cooking in progress listed first', (tester, h) async {
    final sessionId = await startSession(h);
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();
    await openMenu(tester);
    for (final item in ['המשך בישול', 'המטבח שלי', 'מתכון חדש', 'המתכונים שלי', 'מועדפים', 'היסטוריית בישול', 'הגדרות']) {
      expect(find.text(item), findsWidgets, reason: item);
    }
    await tester.tap(find.text('המשך בישול'));
    await tester.pumpAndSettle();
    expect(find.text('0 מתוך 5 שלבים הושלמו'), findsOneWidget);
    expect((await h.sessions.activeSession())?.id, sessionId);
  });

  testApp('leaving the cooking screen with back never stops cooking: timers and undo stay', (tester, h) async {
    final sessionId = await startSession(h);
    await tester.pumpWidget(h.build(initialLocation: '/cook/$sessionId'));
    await tester.pumpAndSettle();
    await tapText(tester, 'הדליקו את התנור על 200 מעלות');
    await tapButton(tester, 'סיימתי, לשלב הבא');
    expect(h.notifier.scheduled.keys, ['$sessionId/tp1']);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(KitchenScreen), findsOneWidget);
    expect(find.text('מבשלים עכשיו'), findsOneWidget);
    expect(find.text('שלב 2 מתוך 5'), findsOneWidget);
    expect(h.notifier.scheduled.keys, ['$sessionId/tp1']); // the timer still rings

    await tester.tap(find.text('המשך לבשל'));
    await tester.pumpAndSettle();
    expect(find.text('1 מתוך 5 שלבים הושלמו'), findsOneWidget);
    await tapText(tester, 'חזרה'); // undo survived the trip
    expect(find.text('0 מתוך 5 שלבים הושלמו'), findsOneWidget);
  });

  testApp('navigation rule: home has the menu on the right; inner screens have only back on the right and their title',
      (tester, h) async {
    phone(tester);
    final recipeId = await h.seedSample();
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('תפריט')).center.dx, greaterThan(300)); // the right corner
    expect(find.byType(BackButton), findsNothing);
    await tester.tap(find.text('תפריט'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(Drawer)).right, 360); // slides in from the right
    await tester.tap(find.text('הגדרות'));
    await tester.pump(const Duration(seconds: 1));

    for (final location in ['/settings', '/recipes', '/recipes/$recipeId', '/import', '/history']) {
      GoRouter.of(tester.element(find.byType(Scaffold).last)).go(location);
      await tester.pump(const Duration(seconds: 1));
      final bar = find.byType(AppBar).last;
      expect(find.descendant(of: bar, matching: find.byType(BackButton)), findsOneWidget, reason: location);
      expect(tester.getRect(find.descendant(of: bar, matching: find.byType(BackButton))).center.dx, greaterThan(300), reason: location);
      expect(find.descendant(of: bar, matching: find.text('תפריט')), findsNothing, reason: location);
      expect(find.descendant(of: bar, matching: find.text('לבשל כל אחד יכול')), findsNothing, reason: location);
    }
    if (find.text('הבנתי, להמשיך').evaluate().isNotEmpty) await tapText(tester, 'הבנתי, להמשיך');
  });

  testApp('the cooking header is one compact row: back and the recipe name, truncated, nothing else', (tester, h) async {
    phone(tester, textScale: 1.3);
    final sessionId = await startSession(h);
    await tester.pumpWidget(h.build(initialLocation: '/cook/$sessionId'));
    await tester.pumpAndSettle();
    final bar = find.byType(AppBar).last;
    expect(tester.getSize(bar).height, lessThanOrEqualTo(64));
    final title = tester.widget<Text>(find.descendant(of: bar, matching: find.text('עוף בתנור עם תפוחי אדמה ואורז')));
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
    // The instruction is the focus: the step title sits right under the light progress line.
    final step = tester.getRect(find.text('הכנת תפוחי האדמה'));
    expect(step.top, lessThan(260));
  });

  testApp('back from a screen opened with nothing under it still goes home', (tester, h) async {
    final sessionId = await startSession(h);
    await tester.pumpWidget(h.build(initialLocation: '/cook/$sessionId'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(KitchenScreen), findsOneWidget);
    expect((await h.sessions.activeSession())?.id, sessionId);
  });

  testApp('RTL: forward arrows point left (chevron_right mirrors), back points right', (tester, h) async {
    await h.seedSample();
    await tester.pumpWidget(h.build(initialLocation: '/recipes'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.chevron_left), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);
    final arrow = tester.widget<Icon>(find.byIcon(Icons.chevron_right_rounded).first);
    expect(arrow.icon!.matchTextDirection, isTrue);
    expect(Directionality.of(tester.element(find.byType(BackButton))), TextDirection.rtl);
  });

  testApp('the main action stays above the keyboard', (tester, h) async {
    phone(tester);
    await tester.pumpWidget(h.build(initialLocation: '/import'));
    await tester.pumpAndSettle();
    await tapText(tester, 'הבנתי, להמשיך');
    await tester.enterText(find.byType(TextField), 'מתכון');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final button = tester.getRect(find.text('קריאת המתכון'));
    expect(button.bottom, lessThanOrEqualTo(640 - 300));
    expect(button.top, greaterThan(0));
  });

  for (final location in ['/', '/import', '/recipes', '/history', '/settings']) {
    testApp('small phone + 200% text: $location lays out without overflow', (tester, h) async {
      phone(tester, textScale: 2);
      await h.seedSample();
      await tester.pumpWidget(h.build(initialLocation: location));
      // Settings shows a progress bar while it asks the system; the platform never answers here.
      location == '/settings' ? await tester.pump(const Duration(seconds: 2)) : await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Home: the menu; every other screen: one back button.
      expect(location == '/' ? find.text('תפריט') : find.byType(BackButton), findsOneWidget);
    });
  }

  testApp('small phone + 200% text: overview and cooking keep the main action and Remy visible', (tester, h) async {
    phone(tester, textScale: 2);
    final recipeId = await h.seedSample();
    await tester.pumpWidget(h.build(initialLocation: '/recipes/$recipeId'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('מתחילים לבשל').hitTestable(), findsOneWidget);
    expect(find.text('רמי').hitTestable(), findsOneWidget);

    await tapButton(tester, 'מתחילים לבשל');
    expect(tester.takeException(), isNull);
    expect(find.text('סיימתי, לשלב הבא').hitTestable(), findsOneWidget);
    expect(find.text('רמי').hitTestable(), findsOneWidget);
    // The two never overlap.
    final main = tester.getRect(find.text('סיימתי, לשלב הבא'));
    final remy = tester.getRect(find.text('רמי'));
    expect(main.overlaps(remy), isFalse);
  });

  testApp('small phone + 200% text: Remy keeps typing and the microphone in reach', (tester, h) async {
    phone(tester, textScale: 2);
    final sessionId = await startSession(h);
    await tester.pumpWidget(h.build(initialLocation: '/cook/$sessionId'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('רמי, העוזר שלך לבישול'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('מקשיב…'), findsOneWidget); // a tap is "talking to Remy"
    expect(find.byTooltip('דיבור עם רמי').hitTestable(), findsOneWidget);
    await tester.tap(find.text('הקלדה'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField).last.hitTestable(), findsOneWidget);
    expect(find.byTooltip('שליחה').hitTestable(), findsOneWidget);
  });

  testApp('small phone + 200% text: the finish screen keeps its save button', (tester, h) async {
    phone(tester, textScale: 2);
    final sessionId = await startSession(h);
    await tester.pumpWidget(h.build(initialLocation: '/cook/$sessionId/finish'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('בתאבון!'), findsOneWidget);
    expect(find.text('שמירה וסיום').hitTestable(), findsOneWidget);
  });

  testApp('reduced motion: a finished timer changes colour without pulsing, pages fade', (tester, h) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final sessionId = await startSession(h);
    await tester.pumpWidget(h.build(initialLocation: '/cook/$sessionId'));
    await tester.pumpAndSettle();
    await tapText(tester, 'הדליקו את התנור על 200 מעלות');
    await h.advance(tester, const Duration(minutes: 15));
    await expectSeen(tester, find.text('זמן לבדוק!'));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testApp('home shows cooking in progress with its step and one way back in', (tester, h) async {
    await startSession(h);
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();
    expect(find.text('מבשלים עכשיו'), findsOneWidget);
    expect(find.text('שלב 1 מתוך 5'), findsOneWidget);
    await tester.tap(find.text('המשך לבשל'));
    await tester.pumpAndSettle();
    expect(find.text('0 מתוך 5 שלבים הושלמו'), findsOneWidget);
  });

  group('Remy before cooking', () {
    Future<String> openOverviewRemy(WidgetTester tester, AppHarness h) async {
      final recipeId = await h.seedSample();
      await tester.pumpWidget(h.build(initialLocation: '/recipes/$recipeId'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('רמי, העוזר שלך לבישול'));
      await tester.pumpAndSettle();
      return recipeId;
    }

    testApp('answers recipe questions locally, offline, with no API call', (tester, h) async {
      h.api.forbidCalls = true;
      await openOverviewRemy(tester, h);
      expect(find.textContaining('אפשר לשאול אותי על המתכון'), findsOneWidget);
      await tester.ensureVisible(find.text('כמה זמן זה לוקח?'));
      await tester.tap(find.text('כמה זמן זה לוקח?'));
      await tester.pumpAndSettle();
      expect(find.textContaining('המתכון לוקח בערך'), findsOneWidget);
      await tester.ensureVisible(find.text('במה מתחילים?'));
      await tester.tap(find.text('במה מתחילים?'));
      await tester.pumpAndSettle();
      expect(find.textContaining('מתחילים ב: הכנת תפוחי האדמה'), findsOneWidget);
      await tester.ensureVisible(find.text('חסר לי מצרך'));
      await tester.tap(find.text('חסר לי מצרך'));
      await tester.pumpAndSettle();
      expect(find.textContaining('סמנו "חסר לי" ליד המצרך'), findsWidgets);
      expect(h.api.calls, isEmpty);
    });

    testApp('cooking commands wait for cooking: nothing starts, nothing changes', (tester, h) async {
      h.api.forbidCalls = true;
      await openOverviewRemy(tester, h);
      await tester.tap(find.text('הקלדה'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'סיימתי');
      await tester.tap(find.byTooltip('שליחה'));
      await tester.pumpAndSettle();
      expect(find.text('את זה עושים כשמתחילים לבשל. בינתיים אפשר לשאול אותי על המתכון.'), findsOneWidget);
      expect(find.text('הצעה של רמי'), findsNothing);
      expect(await h.sessions.activeSession(), isNull);
    });

    testApp('a change Remy proposes is never applied from the chat; the checklist is suggested', (tester, h) async {
      final recipeId = await openOverviewRemy(tester, h);
      final before = (await h.recipes.getRecipe(recipeId))!.recipe;
      h.api.turns.add(const AssistantTurnResult(
        answerHe: 'אפשר להשתמש בשמן קנולה.',
        speechHe: 'אפשר להשתמש בשמן קנולה.',
        proposal: AssistantProposalData(kind: 'patch', summaryHe: 'שמן קנולה במקום שמן זית', ops: [
          {'op': 'replace_ingredient', 'ingredient_id': 'i3', 'name': 'שמן קנולה'},
        ]),
      ));
      await tester.tap(find.text('הקלדה'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'אפשר להחליף את שמן הזית במשהו אחר?');
      await tester.tap(find.byTooltip('שליחה'));
      await tester.pumpAndSettle();
      expect(find.textContaining('אפשר להשתמש בשמן קנולה.'), findsOneWidget);
      expect(find.textContaining('סמנו "חסר לי" ליד המצרך'), findsOneWidget);
      expect(find.text('הצעה של רמי'), findsNothing);
      expect(h.api.calls, ['assistantTurn']);
      expect((await h.recipes.getRecipe(recipeId))!.recipe.ingredients.map((i) => i.name), before.ingredients.map((i) => i.name));
    });
  });
}
