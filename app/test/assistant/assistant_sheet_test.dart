import 'package:anyone_can_cook/core/api_client.dart';
import 'package:anyone_can_cook/features/cooking/engine/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<void> typeToRemy(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).last, text);
  await tester.tap(find.byTooltip('שליחה'));
  await tester.pumpAndSettle();
}

void main() {
  Future<String> openCooking(WidgetTester tester, AppHarness h) async {
    final recipeId = await h.seedSample();
    final plan = (await h.recipes.latestApprovedPlan(recipeId))!;
    final session = await h.sessions.startSession(recipeId: recipeId, planId: plan.id);
    await tester.pumpWidget(h.build(initialLocation: '/cook/${session.id}'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('רמי — עוזר הבישול'));
    await tester.pumpAndSettle();
    return session.id;
  }

  testApp('Remy runs a simple command offline and answers from the plan', (tester, h) async {
    h.api.forbidCalls = true;
    final sessionId = await openCooking(tester, h);
    expect(find.textContaining('היי, אני רמי'), findsOneWidget);

    await typeToRemy(tester, 'הבא');
    expect(find.text('✓ סיימנו: הכנת תפוחי האדמה. עכשיו: תיבול העוף.'), findsOneWidget);
    final events = await h.sessions.loadEvents(sessionId);
    expect(events.whereType<ActionConfirmed>().map((e) => e.source).toSet(), {ActionSource.agent});

    await tester.tap(find.text('כמה זמן נשאר?'));
    await tester.pumpAndSettle();
    expect(find.text('אין טיימר פעיל כרגע.'), findsOneWidget);
    expect(h.api.calls, isEmpty);
  });

  testApp('a proposal from Remy needs approval; "no thanks" changes nothing', (tester, h) async {
    const proposal = AssistantTurnResult(
      answerHe: 'אפשר להנמיך את האש באורז.',
      speechHe: 'אפשר להנמיך את האש באורז.',
      proposal: AssistantProposalData(kind: 'patch', summaryHe: 'אש נמוכה מאוד לאורז', ops: [
        {'op': 'add_step_note', 'step_id': 's4', 'note_he': 'על אש נמוכה מאוד.'},
      ]),
    );
    h.api.turns.addAll([proposal, proposal]);
    final sessionId = await openCooking(tester, h);

    await typeToRemy(tester, 'האורז שורף למטה, מה עושים?');
    expect(find.text('אפשר להנמיך את האש באורז.'), findsOneWidget);
    expect(find.text('הצעה של רמי'), findsOneWidget);
    await tester.tap(find.text('לא, תודה'));
    await tester.pumpAndSettle();
    expect(find.text('בסדר, לא שיניתי כלום.'), findsOneWidget);
    expect((await h.sessions.loadEvents(sessionId)).whereType<PlanPatched>(), isEmpty);

    await typeToRemy(tester, 'ושוב — האורז שורף');
    await tester.tap(find.text('אישור'));
    await tester.pumpAndSettle();
    expect(find.text('✓ עדכנתי את השלבים הבאים: אש נמוכה מאוד לאורז.'), findsOneWidget);
    expect((await h.sessions.loadEvents(sessionId)).whereType<PlanPatched>().single.summaryHe, 'אש נמוכה מאוד לאורז');
    expect(h.api.calls, ['assistantTurn', 'assistantTurn']);
  });
}
