import 'package:anyone_can_cook/data/settings_repository.dart';
import 'package:anyone_can_cook/features/assistant/voice.dart';
import 'package:anyone_can_cook/features/assistant/wake_phrase.dart';
import 'package:anyone_can_cook/features/cooking/engine/events.dart';
import 'package:anyone_can_cook/features/kitchen/kitchen_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

const doneFirst = '✓ סיימנו: הכנת תפוחי האדמה. עכשיו: תיבול העוף.';
const doneFirstSpoken = 'סיימנו: הכנת תפוחי האדמה. עכשיו: תיבול העוף.';

void main() {
  group('the wake phrase', () {
    test('Remy\'s name at the start, with or without a greeting, is a call', () {
      expect(detectWake('היי רמי')?.command, '');
      expect(detectWake('הי רמי, סיימתי')?.command, 'סיימתי');
      expect(detectWake('היי, רמי! כמה זמן נשאר?')?.command, 'כמה זמן נשאר');
      expect(detectWake('רמי תוסיף 5 דקות')?.command, 'תוסיף 5 דקות');
      expect(detectWake('הירמי מה עכשיו')?.command, 'מה עכשיו');
      expect(detectWake('Hey Remy')?.command, '');
    });

    test('anything else is not a call', () {
      expect(detectWake(''), isNull);
      expect(detectWake('מה שלומך'), isNull);
      expect(detectWake('אני חושב שרמי צודק'), isNull);
      expect(detectWake('תגיד לרמי שסיימתי'), isNull);
      expect(detectWake('היי מה נשמע'), isNull);
    });
  });

  Future<String> openCooking(WidgetTester tester, AppHarness h, {bool handsFreeOn = false}) async {
    final recipeId = await h.seedSample();
    final plan = (await h.recipes.latestApprovedPlan(recipeId))!;
    final session = await h.sessions.startSession(recipeId: recipeId, planId: plan.id);
    if (handsFreeOn) await SettingsRepository(h.db, h.clock.call).set(SettingKeys.handsFree, 'on');
    await tester.pumpWidget(h.build(initialLocation: '/cook/${session.id}'));
    await tester.pumpAndSettle();
    return session.id;
  }

  Future<Set<String>> confirmed(AppHarness h, String sessionId) async =>
      {for (final e in (await h.sessions.loadEvents(sessionId)).whereType<ActionConfirmed>()) e.stepId};

  /// A hands-free sheet closes by itself a few seconds after Remy answered.
  Future<void> waitForAutoClose(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  bool sheetOpen() => find.byTooltip('דיבור עם רמי').evaluate().isNotEmpty;

  testApp('hands-free is off until the cook turns it on, and the choice is remembered', (tester, h) async {
    await openCooking(tester, h);
    expect(find.text('דיבור בלי ידיים'), findsOneWidget);
    expect(find.text('אמרו "היי רמי" ורמי יקשיב, בלי לגעת במסך'), findsOneWidget);
    expect(h.mic.wakeListens, 0);

    await tester.tap(find.text('דיבור בלי ידיים'));
    await tester.pumpAndSettle();
    expect(h.mic.wakeListens, 1);
    expect(h.mic.listening, isTrue);
    expect(find.text('מקשיב ל"היי רמי". המסך יישאר דלוק.'), findsOneWidget);
    expect(await SettingsRepository(h.db, h.clock.call).get(SettingKeys.handsFree), 'on');

    await tester.tap(find.text('דיבור בלי ידיים'));
    await tester.pumpAndSettle();
    expect(h.mic.listening, isFalse);
    expect(await SettingsRepository(h.db, h.clock.call).get(SettingKeys.handsFree), 'off');
  });

  testApp('"היי רמי, סיימתי" finishes the step with no touch; Remy answers aloud, steps away, listens again',
      (tester, h) async {
    h.api.forbidCalls = true;
    h.mic.utterances.addAll(['מה נשמע', 'היי רמי, סיימתי']);
    final sessionId = await openCooking(tester, h, handsFreeOn: true);

    expect(find.text(doneFirst), findsOneWidget); // shown in Remy's sheet, opened by voice
    expect(h.speech.spoken, [doneFirstSpoken]);
    expect(await confirmed(h, sessionId), hasLength(1));
    final wakeSessions = h.mic.wakeListens;

    await waitForAutoClose(tester);
    expect(sheetOpen(), isFalse);
    expect(find.text('1 מתוך 5 שלבים הושלמו'), findsOneWidget);
    expect(h.mic.wakeListens, wakeSessions + 1); // listening for the next "היי רמי"
    expect(h.mic.listening, isTrue);
  });

  testApp('"היי רמי" alone opens Remy listening; the request that follows is answered', (tester, h) async {
    h.api.forbidCalls = true;
    h.mic.utterances.addAll(['היי רמי', 'כמה זמן נשאר?']);
    await openCooking(tester, h, handsFreeOn: true);
    expect(find.text('אין טיימר פעיל כרגע.'), findsOneWidget);
    expect(h.speech.spoken, ['אין טיימר פעיל כרגע.']);
    await waitForAutoClose(tester);
    expect(sheetOpen(), isFalse);
  });

  testApp('kitchen talk that is not a call is ignored', (tester, h) async {
    h.api.forbidCalls = true;
    h.mic.utterances.addAll(['אני חושב שרמי צודק', 'מה שלומך']);
    final sessionId = await openCooking(tester, h, handsFreeOn: true);
    expect(sheetOpen(), isFalse);
    expect(h.mic.wakeListens, 3); // two ignored sessions, the third still listening
    expect(await confirmed(h, sessionId), isEmpty);
  });

  testApp('a question Remy asks hands-free is answered by voice too', (tester, h) async {
    h.api.forbidCalls = true;
    h.mic.utterances.addAll(['היי רמי אולי סיימתי', 'כן']);
    final sessionId = await openCooking(tester, h, handsFreeOn: true);
    expect(await confirmed(h, sessionId), hasLength(1));
    expect(h.speech.spoken.last, doneFirstSpoken);
    await waitForAutoClose(tester);
    expect(sheetOpen(), isFalse);
  });

  testApp('touching the sheet keeps it open (the cook is here)', (tester, h) async {
    h.api.forbidCalls = true;
    h.mic.utterances.add('היי רמי כמה זמן נשאר?');
    await openCooking(tester, h, handsFreeOn: true);
    await tester.tap(find.text('אין טיימר פעיל כרגע.'));
    await waitForAutoClose(tester);
    expect(sheetOpen(), isTrue);
  });

  testApp('a tap on Remy pauses "היי רמי"; closing him resumes it', (tester, h) async {
    await openCooking(tester, h, handsFreeOn: true);
    expect(h.mic.wakeListens, 1);
    await tester.tap(find.byTooltip('רמי, העוזר שלך לבישול'));
    await tester.pumpAndSettle();
    expect(h.mic.listens, 2); // the sheet's own listening took the microphone
    expect(h.mic.wakeListens, 1);
    await tester.tapAt(const Offset(10, 10)); // close the sheet
    await tester.pumpAndSettle();
    expect(h.mic.wakeListens, 2);
    expect(h.mic.listening, isTrue);
  });

  testApp('leaving the cooking screen stops listening; cooking itself goes on', (tester, h) async {
    final sessionId = await openCooking(tester, h, handsFreeOn: true);
    expect(h.mic.listening, isTrue);
    await tester.binding.handlePopRoute(); // back to home
    await tester.pumpAndSettle();
    expect(find.byType(KitchenScreen), findsOneWidget);
    expect(h.mic.listening, isFalse);
    expect((await h.sessions.activeSession())?.id, sessionId);
  });

  testApp('without the microphone permission hands-free says why and stops', (tester, h) async {
    h.mic.prepareIssue = VoiceIssue.permissionDenied;
    await openCooking(tester, h);
    await tester.tap(find.text('דיבור בלי ידיים'));
    await tester.pumpAndSettle();
    expect(find.textContaining('כדי לדבר עם רמי צריך לאשר גישה למיקרופון'), findsOneWidget);
    expect(h.mic.wakeListens, 0);
  });

  testApp('offline recognition: hands-free explains it and the Remy button still works', (tester, h) async {
    h.mic.utterances.add(VoiceIssue.network);
    await openCooking(tester, h, handsFreeOn: true);
    expect(find.textContaining('"היי רמי" לא זמין כרגע'), findsOneWidget);
    expect(find.byTooltip('רמי, העוזר שלך לבישול'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });
}
