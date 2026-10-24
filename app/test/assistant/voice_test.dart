import 'package:anyone_can_cook/features/assistant/voice.dart';
import 'package:anyone_can_cook/features/cooking/engine/events.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import 'assistant_sheet_test.dart' show typeToRemy;

const doneFirst = '✓ סיימנו: הכנת תפוחי האדמה. עכשיו: תיבול העוף.';
const doneFirstSpoken = 'סיימנו: הכנת תפוחי האדמה. עכשיו: תיבול העוף.';

void main() {
  Future<String> openCooking(WidgetTester tester, AppHarness h, {bool openSheet = true}) async {
    final recipeId = await h.seedSample();
    final plan = (await h.recipes.latestApprovedPlan(recipeId))!;
    final session = await h.sessions.startSession(recipeId: recipeId, planId: plan.id);
    await tester.pumpWidget(h.build(initialLocation: '/cook/${session.id}'));
    await tester.pumpAndSettle();
    if (openSheet) {
      await tester.tap(find.byTooltip('רמי, העוזר שלך לבישול'));
      await tester.pumpAndSettle();
    }
    return session.id;
  }

  // The sheet's microphone (the cooking screen's own sits underneath it).
  Future<void> tapMic(WidgetTester tester) async {
    await tester.tap(find.byTooltip('דיבור עם רמי').last);
    await tester.pumpAndSettle();
  }

  /// The steps acted on (finishing a step confirms all of its actions).
  Future<Set<String>> confirmed(AppHarness h, String sessionId) async =>
      {for (final e in (await h.sessions.loadEvents(sessionId)).whereType<ActionConfirmed>()) e.stepId};

  testApp('a spoken "סיימתי" runs locally, is answered on screen and read aloud', (tester, h) async {
    h.api.forbidCalls = true;
    final sessionId = await openCooking(tester, h);
    h.mic.utterances.add('רמי, סיימתי');
    await tapMic(tester);

    expect(find.text('רמי, סיימתי'), findsOneWidget); // the transcript, as if typed
    expect(find.text(doneFirst), findsOneWidget);
    expect(h.speech.spoken, [doneFirstSpoken]);
    final events = (await h.sessions.loadEvents(sessionId)).whereType<ActionConfirmed>();
    expect(events.map((e) => e.source).toSet(), {ActionSource.agent});
    expect(await confirmed(h, sessionId), hasLength(1));
    expect(h.api.calls, isEmpty);
  });

  testApp('typed and spoken requests give the same result; typed replies stay silent', (tester, h) async {
    h.api.forbidCalls = true;
    await openCooking(tester, h);
    await typeToRemy(tester, 'כמה זמן נשאר?');
    expect(h.speech.spoken, isEmpty);
    h.mic.utterances.add('כמה זמן נשאר?');
    await tapMic(tester);
    expect(find.text('אין טיימר פעיל כרגע.'), findsNWidgets(2));
    expect(h.speech.spoken, ['אין טיימר פעיל כרגע.']);
  });

  testApp('an unsure spoken request asks first; "כן" by voice approves it', (tester, h) async {
    h.api.forbidCalls = true;
    final sessionId = await openCooking(tester, h);
    h.mic.utterances.add('אולי סיימתי');
    await tapMic(tester);
    expect(find.text('הצעה של רמי'), findsOneWidget);
    expect(await confirmed(h, sessionId), isEmpty);
    expect(h.speech.spoken, hasLength(1)); // the question is read aloud too

    h.mic.utterances.add('כן');
    await tapMic(tester);
    expect(find.text(doneFirst), findsOneWidget);
    expect(await confirmed(h, sessionId), hasLength(1));
    expect(h.speech.spoken.last, doneFirstSpoken);
  });

  testApp('"לא" by voice rejects a pending confirmation', (tester, h) async {
    h.api.forbidCalls = true;
    final sessionId = await openCooking(tester, h);
    h.mic.utterances.addAll(['אולי סיימתי', 'לא']);
    await tapMic(tester);
    await tapMic(tester);
    expect(find.text('בסדר, לא שיניתי כלום.'), findsOneWidget);
    expect(await confirmed(h, sessionId), isEmpty);
  });

  final issues = {
    VoiceIssue.permissionDenied: 'כדי לדבר עם רמי צריך לאשר גישה למיקרופון',
    VoiceIssue.recognitionUnavailable: 'זיהוי דיבור לא זמין בטלפון הזה',
    VoiceIssue.hebrewUnsupported: 'זיהוי דיבור בעברית לא זמין',
    VoiceIssue.network: 'פקודות הבישול עובדות גם בלי אינטרנט',
  };
  for (final MapEntry(key: issue, value: message) in issues.entries) {
    testApp('when recognition can\'t start ($issue) a friendly note shows and typing still works', (tester, h) async {
      h.api.forbidCalls = true;
      final sessionId = await openCooking(tester, h);
      h.mic.prepareIssue = issue;
      await tapMic(tester);
      expect(find.textContaining(message), findsOneWidget);
      expect(h.mic.listens, 0);

      await typeToRemy(tester, 'הבא');
      expect(find.text(doneFirst), findsOneWidget);
      expect(await confirmed(h, sessionId), hasLength(1));
      expect(find.textContaining(message), findsOneWidget); // stays until the next try
    });
  }

  testApp('a recognition error while listening (offline) shows the offline note', (tester, h) async {
    await openCooking(tester, h);
    h.mic.utterances.add(VoiceIssue.network);
    await tapMic(tester);
    expect(find.textContaining('צריך חיבור לאינטרנט'), findsOneWidget);
    expect(h.api.calls, isEmpty);
  });

  testApp('silence gives "לא שמעתי" and sends nothing', (tester, h) async {
    h.api.forbidCalls = true;
    final sessionId = await openCooking(tester, h);
    h.mic.utterances.add('');
    await tapMic(tester);
    expect(find.text('לא שמעתי. אפשר לנסות שוב.'), findsOneWidget);
    expect(await confirmed(h, sessionId), isEmpty);
  });

  testApp('without a Hebrew voice the reply stays text, with a steady note', (tester, h) async {
    h.api.forbidCalls = true;
    h.speech.hebrew = false;
    await openCooking(tester, h);
    const note = 'אין בטלפון קול עברי להקראה, אז התשובות יופיעו כטקסט.';
    h.mic.heldPartial = 'הבא';
    await tapMic(tester);
    expect(find.text(note), findsOneWidget); // visible while listening
    await tapMic(tester); // finish the utterance
    expect(find.text(doneFirst), findsOneWidget);
    expect(h.speech.spoken, isEmpty);

    h.mic.utterances.add('כמה זמן נשאר?');
    await tapMic(tester);
    expect(find.text('אין טיימר פעיל כרגע.'), findsOneWidget);
    expect(h.speech.spoken, isEmpty);
    expect(find.text(note), findsOneWidget);
  });

  testApp('the state shows what is heard; tapping the mic again finishes the utterance', (tester, h) async {
    h.api.forbidCalls = true;
    final sessionId = await openCooking(tester, h);
    h.mic.heldPartial = 'סיימתי';
    await tapMic(tester);
    expect(find.text('מקשיב… סיימתי'), findsOneWidget);
    expect(find.text('עצירה'), findsOneWidget);
    await tapMic(tester);
    expect(find.text(doneFirst), findsOneWidget);
    expect(await confirmed(h, sessionId), hasLength(1));
    expect(find.text('עצירה'), findsNothing);
  });

  testApp('"עצירה" drops the utterance; typing while listening switches to text', (tester, h) async {
    h.api.forbidCalls = true;
    final sessionId = await openCooking(tester, h);
    h.mic.heldPartial = 'סיימתי';
    await tapMic(tester);
    await tester.tap(find.text('עצירה'));
    await tester.pumpAndSettle();
    expect(find.textContaining('מקשיב'), findsNothing);
    expect(await confirmed(h, sessionId), isEmpty);

    await tapMic(tester);
    expect(h.mic.listening, isTrue);
    await typeToRemy(tester, 'כמה זמן נשאר?');
    expect(h.mic.listening, isFalse);
    expect(find.textContaining('מקשיב'), findsNothing);
    expect(find.text('אין טיימר פעיל כרגע.'), findsOneWidget);
    expect(await confirmed(h, sessionId), isEmpty);
  });

  testApp('continuous conversation listens again after each answer and stops after two silences', (tester, h) async {
    h.api.forbidCalls = true;
    final sessionId = await openCooking(tester, h);
    await tester.tap(find.text('שיחה רציפה'));
    await tester.pumpAndSettle();
    h.mic.utterances.addAll(['הבא', 'הבא', '', '']);
    await tapMic(tester);
    expect(await confirmed(h, sessionId), hasLength(2));
    expect(h.speech.spoken, hasLength(2));
    expect(h.mic.listens, 4);
    expect(find.text('לא שמעתי. אפשר לנסות שוב.'), findsOneWidget);
    expect(find.textContaining('מקשיב'), findsNothing);
  });

  testApp('a long press on Remy in the cooking screen opens him already listening', (tester, h) async {
    h.api.forbidCalls = true;
    final sessionId = await openCooking(tester, h, openSheet: false);
    h.mic.utterances.add('סיימתי');
    // A long press on Remy is the quick voice shortcut.
    await tester.longPress(find.byTooltip('רמי, העוזר שלך לבישול'));
    await tester.pumpAndSettle();
    expect(find.text(doneFirst), findsOneWidget);
    expect(h.speech.spoken, [doneFirstSpoken]);
    expect(await confirmed(h, sessionId), hasLength(1));
  });

  testApp('closing the sheet while listening stops the microphone and changes nothing', (tester, h) async {
    final sessionId = await openCooking(tester, h);
    h.mic.heldPartial = 'סיימתי';
    await tapMic(tester);
    expect(h.mic.listening, isTrue);
    await tester.tapAt(const Offset(10, 10)); // outside the sheet
    await tester.pumpAndSettle();
    expect(h.mic.listening, isFalse);
    expect(await confirmed(h, sessionId), isEmpty);
  });
}
