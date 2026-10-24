import 'package:flutter/material.dart' hide ActionDispatcher;
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/ui_helpers.dart';

void main() {
  testApp('wait card explains, schedules a check and supports "check again"', (tester, h) async {
    final recipeId = await h.saveFixture('sample_bread');
    final plan = (await h.recipes.latestApprovedPlan(recipeId))!;
    final session = await h.sessions.startSession(recipeId: recipeId, planId: plan.id);
    await tester.pumpWidget(h.build(initialLocation: '/cook/${session.id}'));
    await tester.pumpAndSettle();

    // Advance notice before starting.
    await expectSeen(tester, find.textContaining('כל התהליך לוקח כ-4 שעות'));

    // Knead (a timed step: explicit start), finish early, then start the first proof (60–90 minutes).
    await tapButton(tester, 'התחלתי ללוש');
    await tapText(tester, 'כבר מוכן? לשלב הבא');
    await tapButton(tester, 'כיסיתי את הבצק');

    await expectSeen(tester, find.text('התפחה ראשונה'));
    await expectSeen(tester, find.text('1:00:00'));
    await expectSeen(tester, find.textContaining('לבדוק בערך ב-'));
    await expectSeen(tester, find.textContaining('טווח הזמן: עד'));
    await expectSeen(tester, find.textContaining('השמרים מייצרים גז'));
    await expectSeen(tester, find.text('💡 נקו את משטח העבודה'));
    await expectSeen(tester, find.text('אחרי זה: עיצוב והתפחה שנייה'));
    await expectSeen(tester, find.text('שמנו את התבנית')); // suggested during the wait
    expect(h.notifier.scheduled.keys, unorderedEquals(['${session.id}/t2', '${session.id}/t2#end']));

    // Check time: the cue, "ready — next step", and "needs more time" (the plan's 10 minutes).
    await h.advance(tester, const Duration(minutes: 60));
    await expectSeen(tester, find.text('זמן לבדוק!'));
    await expectSeen(tester, find.textContaining('👀 הבצק הכפיל את נפחו'));
    await expectSeen(tester, find.widgetWithText(FilledButton, 'מוכן, לשלב הבא'));
    final recheck = find.text("צריך עוד זמן (+10 דק')");
    await expectSeen(tester, recheck);
    await tester.ensureVisible(recheck);
    await tester.tap(recheck);
    await tester.pumpAndSettle();

    await expectSeen(tester, find.text('10:00'));
    expect(h.notifier.scheduled.keys, ['${session.id}/t2']);
    expect(h.notifier.scheduled['${session.id}/t2'], h.clock.now.add(const Duration(minutes: 10)));
    expect(find.textContaining('טווח הזמן: עד'), findsNothing);
  });
}
