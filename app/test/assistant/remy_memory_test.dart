import 'package:anyone_can_cook/core/api_client.dart';
import 'package:anyone_can_cook/data/settings_repository.dart';
import 'package:anyone_can_cook/features/assistant/conversation_store.dart';
import 'package:anyone_can_cook/features/prepare/preparation.dart';
import 'package:anyone_can_cook/features/prepare/preparation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/ui_helpers.dart';
import 'assistant_sheet_test.dart' show typeToRemy;

/// Remy's memory of the current recipe (docs/DECISIONS.md #81): one conversation per recipe,
/// shared by preparation and cooking, kept across the sheet closing and app restarts, bounded,
/// and cleared when the recipe is finished, abandoned, deleted or discarded.
void main() {
  const remy = 'רמי, העוזר שלך לבישול';
  const emptyHint = 'אפשר לשאול אותי כל דבר על המתכון.';

  SettingsRepository settings(AppHarness h) => SettingsRepository(h.db, h.clock.call);
  ConversationStore store(AppHarness h) => ConversationStore(settings(h), h.clock.call);

  Future<void> openRemy(WidgetTester tester) async {
    await tester.tap(find.byTooltip(remy));
    await tester.pumpAndSettle();
  }

  Future<void> closeRemy(WidgetTester tester) async {
    await tester.tap(find.byTooltip('סגירה'));
    await tester.pumpAndSettle();
  }

  Future<String> startCookingSession(AppHarness h, String recipeId) async {
    final plan = (await h.recipes.latestApprovedPlan(recipeId))!;
    return (await h.sessions.startSession(recipeId: recipeId, planId: plan.id)).id;
  }

  group('the store', () {
    test('keeps the last 20 messages and forgets after 12 hours without activity', () async {
      final h = AppHarness();
      addTearDown(h.db.close);
      final s = store(h);
      await s.save('r1', [for (var i = 0; i < 30; i++) ChatMessage(fromUser: i.isEven, textHe: 'הודעה $i')]);
      final kept = await s.load('r1');
      expect(kept, hasLength(ConversationStore.maxMessages));
      expect(kept.first.textHe, 'הודעה 10');
      expect(kept.last.textHe, 'הודעה 29');

      h.clock.advance(const Duration(hours: 13));
      expect(await s.load('r1'), isEmpty);
      expect(await settings(h).get(ConversationStore.keyFor('r1')), isNull); // removed, not just hidden
    });

    test('each recipe has its own conversation', () async {
      final h = AppHarness();
      addTearDown(h.db.close);
      await store(h).save('a', const [ChatMessage(fromUser: true, textHe: 'שאלה על עוף')]);
      expect(await store(h).load('b'), isEmpty);
      expect((await store(h).load('a')).single.textHe, 'שאלה על עוף');
    });
  });

  testApp('closing and reopening Remy keeps the conversation, without an introduction', (tester, h) async {
    h.api.forbidCalls = true;
    final recipeId = await h.seedSample();
    final sessionId = await startCookingSession(h, recipeId);
    await tester.pumpWidget(h.build(initialLocation: '/cook/$sessionId'));
    await tester.pumpAndSettle();
    await openRemy(tester);
    expect(find.text(emptyHint), findsOneWidget);
    await typeToRemy(tester, 'כמה זמן נשאר?');
    await closeRemy(tester);

    await openRemy(tester);
    expect(find.text('כמה זמן נשאר?'), findsOneWidget);
    expect(find.text('אין טיימר פעיל כרגע.'), findsOneWidget);
    expect(find.text(emptyHint), findsNothing);
  });

  testApp('the conversation continues from preparation into cooking (text there, voice here)', (tester, h) async {
    h.api.forbidCalls = true;
    final recipeId = await h.seedSample();
    await tester.pumpWidget(h.build(initialLocation: '/recipes/$recipeId'));
    await tester.pumpAndSettle();
    await openRemy(tester);
    expect(h.mic.listens, 0); // before cooking: a chat, the microphone stays off
    await typeToRemy(tester, 'במה מתחילים?');
    expect(find.textContaining('מתחילים ב: הכנת תפוחי האדמה'), findsOneWidget);
    await closeRemy(tester);

    await tapButton(tester, 'מתחילים לבשל');
    await openRemy(tester);
    expect(h.mic.listens, 1); // during cooking: listening at once
    expect(find.text('במה מתחילים?'), findsOneWidget); // the same conversation
    expect(find.textContaining('מתחילים ב: הכנת תפוחי האדמה'), findsOneWidget);
  });

  testApp('a different recipe starts its own conversation', (tester, h) async {
    h.api.forbidCalls = true;
    final chicken = await h.seedSample();
    final bread = await h.saveFixture('sample_bread');
    await store(h).save(chicken, const [
      ChatMessage(fromUser: true, textHe: 'כמה מלח לעוף?'),
      ChatMessage(fromUser: false, textHe: 'מלח: 1½ כפיות.'),
    ]);
    await tester.pumpWidget(h.build(initialLocation: '/recipes/$bread'));
    await tester.pumpAndSettle();
    await openRemy(tester);
    expect(find.text('כמה מלח לעוף?'), findsNothing);
    expect(find.text(emptyHint), findsOneWidget);
  });

  testApp('after an app restart the current recipe\'s conversation is still there', (tester, h) async {
    h.api.forbidCalls = true;
    final recipeId = await h.seedSample();
    final sessionId = await startCookingSession(h, recipeId);
    await tester.pumpWidget(h.build(initialLocation: '/cook/$sessionId'));
    await tester.pumpAndSettle();
    await openRemy(tester);
    await typeToRemy(tester, 'כמה זמן נשאר?');

    // A new app run: a fresh provider tree over the same database.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(h.build(initialLocation: '/cook/$sessionId'));
    await tester.pumpAndSettle();
    await openRemy(tester);
    expect(find.text('כמה זמן נשאר?'), findsOneWidget);
  });

  testApp('abandoning the cooking ends the conversation; the recipe and its history stay', (tester, h) async {
    final recipeId = await h.seedSample();
    final sessionId = await startCookingSession(h, recipeId);
    await store(h).save(recipeId, const [ChatMessage(fromUser: true, textHe: 'שאלה')]);
    await tester.pumpWidget(h.build(initialLocation: '/cook/$sessionId'));
    await tester.pumpAndSettle();
    await tapText(tester, 'הפסקת הבישול');
    await tester.tap(find.text('הפסקה'));
    await tester.pumpAndSettle();
    expect(await settings(h).get(ConversationStore.keyFor(recipeId)), isNull);
    expect(await h.recipes.getRecipe(recipeId), isNotNull);
    expect((await h.sessions.getSession(sessionId))!.status, 'abandoned');
  });

  testApp('finishing the cooking ends the conversation', (tester, h) async {
    final recipeId = await h.seedSample();
    final sessionId = await startCookingSession(h, recipeId);
    await store(h).save(recipeId, const [ChatMessage(fromUser: true, textHe: 'שאלה')]);
    await tester.pumpWidget(h.build(initialLocation: '/cook/$sessionId/finish'));
    await tester.pumpAndSettle();
    await tapButton(tester, 'שמירה וסיום');
    expect(await settings(h).get(ConversationStore.keyFor(recipeId)), isNull);
    expect((await h.sessions.getSession(sessionId))!.status, 'completed');
  });

  testApp('deleting a recipe removes only its conversation from the conversation store', (tester, h) async {
    final recipeId = await h.seedSample();
    await store(h).save(recipeId, const [ChatMessage(fromUser: true, textHe: 'שאלה')]);
    await tester.pumpWidget(h.build(initialLocation: '/recipes/$recipeId'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('פעולות למתכון'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('מחיקת המתכון'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('מחיקה'));
    await tester.pumpAndSettle();
    expect(await settings(h).get(ConversationStore.keyFor(recipeId)), isNull);
  });

  testApp('Gemini gets the stage, the saved preparation decisions and at most 6 recent turns', (tester, h) async {
    final recipeId = await h.seedSample();
    await PreparationService(recipes: h.recipes, sessions: h.sessions, api: h.api).setStatus(recipeId, 'i3', ItemStatus.missing);
    await store(h).save(recipeId, [for (var i = 0; i < 12; i++) ChatMessage(fromUser: i.isEven, textHe: 'הודעה $i')]);
    h.api.turns.add(const AssistantTurnResult(answerHe: 'אפשר להשתמש בשמן קנולה.', speechHe: 'אפשר להשתמש בשמן קנולה.'));
    await tester.pumpWidget(h.build(initialLocation: '/recipes/$recipeId'));
    await tester.pumpAndSettle();
    await openRemy(tester);
    await typeToRemy(tester, 'איזה שמן הכי טוב לטיגון עמוק?');

    final turn = h.api.lastTurn!;
    expect(h.api.calls, ['assistantTurn']); // one call, no retries
    expect(turn.history, hasLength(6));
    expect(turn.history.last['text'], 'הודעה 11');
    expect(turn.snapshot['stage'], 'preparation');
    expect((turn.snapshot['preparation'] as Map)['missing'], ['שמן זית']);
    expect(find.text('אפשר להשתמש בשמן קנולה.'), findsOneWidget);
  });

  testApp('during cooking Gemini gets the live cooking state too', (tester, h) async {
    final recipeId = await h.seedSample();
    final sessionId = await startCookingSession(h, recipeId);
    h.api.turns.add(const AssistantTurnResult(answerHe: 'אפשר.', speechHe: 'אפשר.'));
    await tester.pumpWidget(h.build(initialLocation: '/cook/$sessionId'));
    await tester.pumpAndSettle();
    await openRemy(tester);
    await typeToRemy(tester, 'אפשר להוסיף שום לתיבול?');
    final turn = h.api.lastTurn!;
    expect(turn.snapshot['stage'], 'cooking');
    expect(turn.snapshot.containsKey('active_timers'), isTrue);
    expect(h.api.calls, ['assistantTurn']);
  });
}
