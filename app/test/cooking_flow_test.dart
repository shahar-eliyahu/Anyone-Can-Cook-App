import 'package:anyone_can_cook/data/recipe_repository.dart';
import 'package:anyone_can_cook/data/session_repository.dart';
import 'package:anyone_can_cook/features/cooking/engine/action_dispatcher.dart';
import 'package:anyone_can_cook/features/cooking/engine/cooking_engine.dart';
import 'package:flutter/material.dart' hide ActionDispatcher;
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/ui_helpers.dart';

void main() {
  testApp('complete cooking flow: one tap per ordinary step, explicit timer starts, fully offline', (tester, h) async {
    final recipeId = await h.seedSample();
    await tester.pumpWidget(h.build(initialLocation: '/recipes/$recipeId'));
    await tester.pumpAndSettle();
    expect(find.text('עוף בתנור עם תפוחי אדמה ואורז'), findsWidgets);

    await tapButton(tester, 'התחל בישול');
    final session = (await h.sessions.activeSession())!;
    await expectSeen(tester, find.text('0 מתוך 5 שלבים הושלמו'));
    await expectSeen(tester, find.text('הכנת תפוחי האדמה'));
    expect(find.text('הערכה'), findsNothing); // no technical badges while cooking

    // Preheat (prep task) starts its plan timer.
    await tester.tap(find.text('הדליקו את התנור על 200 מעלות'));
    await tester.pumpAndSettle();
    expect(h.notifier.scheduled.keys, ['${session.id}/tp1']);
    await expectSeen(tester, find.text('חימום תנור'));

    // One tap finishes a step (even one planned with "התחלתי" + "סיימתי").
    await tapButton(tester, 'סיימתי — לשלב הבא');
    await expectSeen(tester, find.text('1 מתוך 5 שלבים הושלמו'));
    expect(find.byType(SnackBar), findsNothing);
    // "חזרה" undoes the last tap; then continue.
    await tapText(tester, 'חזרה');
    await expectSeen(tester, find.text('0 מתוך 5 שלבים הושלמו'));
    await tapButton(tester, 'סיימתי — לשלב הבא');
    await tapButton(tester, 'סיימתי — לשלב הבא');
    await expectSeen(tester, find.text('2 מתוך 5 שלבים הושלמו'));

    // A timed step: the start is an explicit tap, and only then the 45-minute timer runs.
    await expectSeen(tester, find.text('כשתלחצו, יתחיל טיימר של 45:00'));
    expect(h.notifier.scheduled.containsKey('${session.id}/t1'), isFalse);
    await tapButton(tester, 'הכנסתי לתנור');
    expect(h.notifier.scheduled['${session.id}/t1'], h.clock.now.add(const Duration(seconds: 2700)));
    await expectSeen(tester, find.text('45:00'));

    // Meanwhile: rice, a second timer at the same time.
    await expectSeen(tester, find.text('בינתיים אפשר'));
    await tapButton(tester, 'הוספתי את האורז');
    expect(h.notifier.scheduled.containsKey('${session.id}/t2'), isTrue);
    await expectSeen(tester, find.text('18:00'));

    // Rice reaches its check time first ("time to check", never "ready").
    await h.advance(tester, const Duration(minutes: 18));
    await expectSeen(tester, find.text('זמן לבדוק!'));
    await expectSeen(tester, find.text('👀 המים נספגו והאורז רך.'));
    await expectSeen(tester, find.text("צריך עוד זמן (+3 דק')")); // the plan's suggestion for rice
    await tapButton(tester, 'מוכן');
    expect(h.notifier.scheduled.containsKey('${session.id}/t2'), isFalse);

    // Poultry: at check time the cook ticks the short doneness check — inline, no popup.
    await h.advance(tester, const Duration(minutes: 27));
    await expectSeen(tester, find.text('מוכן — לשלב הבא'));
    expect(onPressedOf(tester, 'מוכן — לשלב הבא'), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    await tapText(tester, 'בדקתי: העוף שחום, ובחיתוך ליד העצם הנוזלים שקופים ולא ורודים.');
    await tapButton(tester, 'מוכן — לשלב הבא');
    await expectSeen(tester, find.text('4 מתוך 5 שלבים הושלמו'));
    expect(h.notifier.scheduled.containsKey('${session.id}/t1'), isFalse);

    // Rest: "needs more time" once, then ready.
    await tapButton(tester, 'התחלתי מנוחה');
    expect(h.notifier.scheduled.containsKey('${session.id}/t3'), isTrue);
    await h.advance(tester, const Duration(minutes: 5));
    await tapText(tester, "צריך עוד זמן (+5 דק')");
    expect(h.notifier.scheduled['${session.id}/t3'], h.clock.now.add(const Duration(minutes: 5)));
    await h.advance(tester, const Duration(minutes: 5));
    await tapButton(tester, 'מוכן');
    await expectSeen(tester, find.text('כל השלבים הושלמו! 🎉'));

    await tapButton(tester, 'לסיום הבישול');
    await tester.enterText(find.byType(TextField), 'בפעם הבאה פחות מלח');
    await tapButton(tester, 'שמירה וסיום');

    // Saved to history as a friendly summary; no notifications left behind.
    final done = (await h.sessions.getSession(session.id))!;
    expect(done.status, SessionStatus.completed);
    expect(done.notes, 'בפעם הבאה פחות מלח');
    expect(await h.sessions.activeSession(), isNull);
    expect(h.notifier.scheduled, isEmpty);
    await expectSeen(tester, find.textContaining('הושלם'));
    await expectSeen(tester, find.text('בפעם הבאה פחות מלח'));
    await expectSeen(tester, find.text('מנוחה והגשה'));
    expect(find.text('לא הושלם'), findsNothing);
    expect(find.textContaining('הכנסתי לתנור'), findsNothing); // no raw action log
  });

  testApp('an interrupted session resumes with progress and timers restored', (tester, h) async {
    final recipeId = await h.seedSample();
    final plan = (await h.recipes.latestApprovedPlan(recipeId))!;
    final session = await h.sessions.startSession(recipeId: recipeId, planId: plan.id);

    // Cooking happened in an earlier app run.
    final dispatcher = ActionDispatcher(
      state: CookingEngine.replay(plan.plan, await h.sessions.loadEvents(session.id)),
      store: h.sessions.eventStoreFor(session.id),
      onEffects: (_) async {},
      clock: h.clock.call,
    );
    for (final (step, action) in [('s1', 'a1'), ('s1', 'a2'), ('s2', 'a1'), ('s3', 'a1')]) {
      await dispatcher.confirmAction(step, action);
    }
    h.clock.advance(const Duration(minutes: 10));

    // New app run: no notifications are scheduled yet (e.g. after force stop).
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();
    expect(find.text('עוף בתנור עם תפוחי אדמה ואורז'), findsOneWidget);

    await tester.tap(find.text('המשך בישול'));
    await tester.pumpAndSettle();
    expect(find.text('2 מתוך 5 שלבים הושלמו'), findsOneWidget);
    expect(find.text('35:00'), findsOneWidget);
    expect(
      h.notifier.scheduled['${session.id}/t1'],
      session.startedAt.toUtc().add(const Duration(seconds: 2700)),
    );
  });

  testApp('favorite, rename and delete with undo', (tester, h) async {
    final recipeId = await h.seedSample();
    await tester.pumpWidget(h.build(initialLocation: '/recipes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('⭐ מועדפים'));
    await tester.pumpAndSettle();
    expect(find.text('עוד לא סימנתם מתכונים כמועדפים'), findsOneWidget);

    await tester.tap(find.text('הכל'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('עוף בתנור עם תפוחי אדמה ואורז'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('הוספה למועדפים'));
    await tester.pumpAndSettle();
    expect((await h.recipes.getRecipe(recipeId))!.isFavorite, isTrue);

    await tester.tap(find.byWidgetPredicate((w) => w is PopupMenuButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('שינוי שם'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'העוף של שבת');
    await tester.tap(find.text('שמירה'));
    await tester.pumpAndSettle();
    expect(find.text('העוף של שבת'), findsWidgets);

    await tester.tap(find.byWidgetPredicate((w) => w is PopupMenuButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('מחיקת המתכון'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('מחיקה'));
    await tester.pumpAndSettle();
    expect(await h.recipes.getRecipe(recipeId), isNull);
    expect(find.text('המתכון נמחק'), findsOneWidget);

    await tester.tap(find.text('בטל'));
    await tester.pumpAndSettle();
    expect(await h.recipes.getRecipe(recipeId), isNotNull);
    expect(find.text('העוף של שבת'), findsOneWidget);
  });

  testApp('a recipe being cooked cannot be deleted', (tester, h) async {
    final recipeId = await h.seedSample();
    final plan = (await h.recipes.latestApprovedPlan(recipeId))!;
    await h.sessions.startSession(recipeId: recipeId, planId: plan.id);
    await tester.pumpWidget(h.build(initialLocation: '/recipes/$recipeId'));
    await tester.pumpAndSettle();

    await tester.tap(find.byWidgetPredicate((w) => w is PopupMenuButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('מחיקת המתכון'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('מחיקה'));
    await tester.pumpAndSettle();
    expect(find.textContaining('אי אפשר למחוק מתכון בזמן בישול'), findsOneWidget);
    expect(await h.recipes.getRecipe(recipeId), isNotNull);
  });
}
