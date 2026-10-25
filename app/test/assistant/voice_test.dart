import 'package:anyone_can_cook/features/assistant/voice.dart';
import 'package:anyone_can_cook/features/cooking/engine/events.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import 'assistant_sheet_test.dart' show typeToRemy;

const doneFirst = '✓ סיימנו: הכנת תפוחי האדמה. עכשיו: תיבול העוף.';
const doneFirstSpoken = 'סיימנו: הכנת תפוחי האדמה. עכשיו: תיבול העוף.';

void main() {
  Future<String> openCooking(WidgetTester tester, AppHarness h) async {
    final recipeId = await h.seedSample();
    final plan = (await h.recipes.latestApprovedPlan(recipeId))!;
    final session = await h.sessions.startSession(recipeId: recipeId, planId: plan.id);
    await tester.pumpWidget(h.build(initialLocation: '/cook/${session.id}'));
    await tester.pumpAndSettle();
    return session.id;
  }

  /// A tap on Remy: "talking to Remy" (he opens already listening).
  Future<void> talkToRemy(WidgetTester tester) async {
    await tester.tap(find.byTooltip('רמי, העוזר שלך לבישול'));
    await tester.pumpAndSettle();
  }

  Future<void> tapMic(WidgetTester tester) async {
    await tester.tap(find.byTooltip('דיבור עם רמי'));
    await tester.pumpAndSettle();
  }

  /// The steps acted on (finishing a step confirms all of its actions).
  Future<Set<String>> confirmed(AppHarness h, String sessionId) async =>
      {for (final e in (await h.sessions.loadEvents(sessionId)).whereType<ActionConfirmed>()) e.stepId};

  testApp('a tap on Remy listens at once: a spoken "סיימתי" runs locally and is read aloud', (tester, h) async {
    h.api.forbidCalls = true;
    final sessionId = await openCooking(tester, h);
    h.mic.utterances.add('רמי, סיימתי');
    await talkToRemy(tester);

    expect(h.mic.listens, 2); // listened at once; then once more for a follow-up
    expect(h.mic.listening, isTrue);
    expect(find.text('רמי, סיימתי'), findsOneWidget); // the transcript, as if typed
    expect(find.text(doneFirst), findsOneWidget);
    expect(h.speech.spoken, [doneFirstSpoken]);
    final events = (await h.sessions.loadEvents(sessionId)).whereType<ActionConfirmed>();
    expect(events.map((e) => e.source).toSet(), {ActionSource.agent});
    expect(await confirmed(h, sessionId), hasLength(1));
    expect(h.api.calls, isEmpty);
    // Voice first: typing is one small button away, not a text box in the way.
    expect(find.text('הקלדה'), findsOneWidget);
    expect(find.byTooltip('שליחה'), findsNothing);
  });

  testApp('typed and spoken requests give the same result; typed replies stay silent', (tester, h) async {
    h.api.forbidCalls = true;
    await openCooking(tester, h);
    h.mic.utterances.add('כמה זמן נשאר?');
    await talkToRemy(tester);
    expect(find.text('אין טיימר פעיל כרגע.'), findsOneWidget);
    expect(h.speech.spoken, ['אין טיימר פעיל כרגע.']);
    await typeToRemy(tester, 'כמה זמן נשאר?'); // the same conversation, now typed
    expect(find.text('אין טיימר פעיל כרגע.'), findsNWidgets(2));
    expect(h.speech.spoken, hasLength(1));
    expect(h.mic.listening, isFalse); // typing ended the follow-up listening
  });

  testApp('Remy asks before an unsure request and listens for the answer: "כן" approves', (tester, h) async {
    h.api.forbidCalls = true;
    final sessionId = await openCooking(tester, h);
    h.mic.utterances.addAll(['אולי סיימתי', 'כן']);
    await talkToRemy(tester);
    expect(h.mic.listens, 3); // the question was answered by voice, no tap; then a follow-up
    expect(find.text(doneFirst), findsOneWidget);
    expect(await confirmed(h, sessionId), hasLength(1));
    expect(h.speech.spoken, hasLength(2)); // the question, then the result
    expect(h.speech.spoken.last, doneFirstSpoken);
  });

  testApp('"לא" by voice rejects a pending confirmation; the question shows "כן" / "לא"', (tester, h) async {
    h.api.forbidCalls = true;
    final sessionId = await openCooking(tester, h);
    h.mic.utterances.add('אולי סיימתי');
    await talkToRemy(tester);
    expect(find.text('הצעה של רמי'), findsOneWidget);
    expect(find.text('כן'), findsOneWidget);
    expect(find.text('לא'), findsOneWidget);
    expect(find.textContaining('אפשר גם לומר'), findsOneWidget);
    expect(h.mic.listening, isTrue); // waiting for the spoken answer
    h.mic.heldPartial = 'לא';
    await tapMic(tester); // (here the test finishes the held utterance)
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
      await talkToRemy(tester);
      expect(find.textContaining(message), findsOneWidget);
      expect(h.mic.listens, 0);

      await typeToRemy(tester, 'הבא');
      expect(find.text(doneFirst), findsOneWidget);
      expect(await confirmed(h, sessionId), hasLength(1));
    });
  }

  testApp('a busy recognizer (just released by hands-free) gets one quiet retry', (tester, h) async {
    h.api.forbidCalls = true;
    final sessionId = await openCooking(tester, h);
    h.mic.utterances.addAll([VoiceIssue.other, 'סיימתי']);
    await talkToRemy(tester);
    expect(find.text(doneFirst), findsOneWidget);
    expect(find.textContaining('משהו השתבש'), findsNothing);
    expect(await confirmed(h, sessionId), hasLength(1));
  });

  testApp('a recognition error while listening (offline) shows the offline note', (tester, h) async {
    await openCooking(tester, h);
    h.mic.utterances.add(VoiceIssue.network);
    await talkToRemy(tester);
    expect(find.textContaining('צריך חיבור לאינטרנט'), findsOneWidget);
    expect(h.api.calls, isEmpty);
  });

  testApp('silence gives "לא שמעתי" and sends nothing', (tester, h) async {
    h.api.forbidCalls = true;
    final sessionId = await openCooking(tester, h);
    h.mic.utterances.add('');
    await talkToRemy(tester);
    expect(find.text('לא שמעתי. אפשר לנסות שוב.'), findsOneWidget);
    expect(await confirmed(h, sessionId), isEmpty);
  });

  testApp('without a Hebrew voice the reply stays text, with a steady note', (tester, h) async {
    h.api.forbidCalls = true;
    h.speech.hebrew = false;
    await openCooking(tester, h);
    const note = 'אין בטלפון קול עברי להקראה, אז התשובות יופיעו כטקסט.';
    h.mic.heldPartial = 'הבא';
    await talkToRemy(tester);
    expect(find.text(note), findsOneWidget); // visible while listening
    await tapMic(tester); // finish the utterance
    expect(find.text(doneFirst), findsOneWidget);
    expect(h.speech.spoken, isEmpty);
    expect(find.text(note), findsOneWidget);
  });

  testApp('the panel shows that Remy listens and what he hears; the mic finishes the utterance', (tester, h) async {
    h.api.forbidCalls = true;
    final sessionId = await openCooking(tester, h);
    h.mic.heldPartial = 'סיימתי';
    await talkToRemy(tester);
    expect(find.text('מקשיב…'), findsOneWidget);
    expect(find.text('סיימתי'), findsOneWidget); // what is heard, as a faint bubble
    expect(find.text('עצירה'), findsOneWidget);
    await tapMic(tester);
    expect(find.text(doneFirst), findsOneWidget);
    expect(await confirmed(h, sessionId), hasLength(1));
    // Remy listens once more for a follow-up; "עצירה" ends it.
    expect(h.mic.listening, isTrue);
    await tester.tap(find.text('עצירה'));
    await tester.pumpAndSettle();
    expect(h.mic.listening, isFalse);
    expect(find.text('עצירה'), findsNothing);
  });

  testApp('"עצירה" drops the utterance; typing while listening switches to text', (tester, h) async {
    h.api.forbidCalls = true;
    final sessionId = await openCooking(tester, h);
    h.mic.heldPartial = 'סיימתי';
    await talkToRemy(tester);
    await tester.tap(find.text('עצירה'));
    await tester.pumpAndSettle();
    expect(find.text('מקשיב…'), findsNothing);
    expect(await confirmed(h, sessionId), isEmpty);

    await tapMic(tester);
    expect(h.mic.listening, isTrue);
    await typeToRemy(tester, 'כמה זמן נשאר?');
    expect(h.mic.listening, isFalse);
    expect(find.text('מקשיב…'), findsNothing);
    expect(find.text('אין טיימר פעיל כרגע.'), findsOneWidget);
    expect(await confirmed(h, sessionId), isEmpty);
  });

  testApp('a long press while cooking opens text; the mic switches to voice; the first silence ends quietly', (tester, h) async {
    h.api.forbidCalls = true;
    final sessionId = await openCooking(tester, h);
    await tester.longPress(find.byTooltip('רמי, העוזר שלך לבישול'));
    await tester.pumpAndSettle();
    expect(h.mic.listens, 0);
    expect(find.byTooltip('שליחה'), findsOneWidget);
    expect(find.text('שיחה רציפה'), findsNothing); // no continuous-mode toggle

    h.mic.utterances.addAll(['הבא', 'הבא', '']);
    await tapMic(tester); // the small microphone next to the input
    expect(await confirmed(h, sessionId), hasLength(2));
    expect(h.speech.spoken, hasLength(2));
    expect(h.mic.listens, 3);
    expect(h.mic.listening, isFalse); // nothing keeps listening
    expect(find.text('לא שמעתי. אפשר לנסות שוב.'), findsNothing); // a follow-up silence is no error
    expect(find.text('מקשיב…'), findsNothing);
  });

  testApp('follow-up listening is bounded: a long exchange still ends by itself', (tester, h) async {
    h.api.forbidCalls = true;
    await openCooking(tester, h);
    h.mic.utterances.addAll(List.filled(10, 'כמה זמן נשאר?'));
    await talkToRemy(tester);
    expect(h.mic.listens, 1 + 6); // the first request and at most six follow-ups
    expect(h.mic.listening, isFalse);
    expect(h.mic.utterances, hasLength(3)); // the rest was never listened for
  });

  testApp('closing the sheet while listening stops the microphone and changes nothing', (tester, h) async {
    final sessionId = await openCooking(tester, h);
    h.mic.heldPartial = 'סיימתי';
    await talkToRemy(tester);
    expect(h.mic.listening, isTrue);
    await tester.tapAt(const Offset(10, 10)); // outside the sheet
    await tester.pumpAndSettle();
    expect(h.mic.listening, isFalse);
    expect(await confirmed(h, sessionId), isEmpty);
  });
}
