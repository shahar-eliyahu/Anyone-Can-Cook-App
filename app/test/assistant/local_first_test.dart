import 'package:anyone_can_cook/core/api_client.dart';
import 'package:anyone_can_cook/features/assistant/assistant_models.dart';
import 'package:anyone_can_cook/features/assistant/assistant_service.dart';
import 'package:anyone_can_cook/features/cooking/engine/cooking_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/sample.dart';
import 'assistant_service_test.dart' show DispatcherActions;

/// Local-first understanding with Gemini as a fallback interpreter (Phase 3D refinement).
void main() {
  late EngineHarness h;
  late FakeApi api;
  late AssistantService remy;
  late DispatcherActions actions;
  final recipe = loadSampleBundle().recipe;

  setUp(() {
    h = EngineHarness();
    api = FakeApi();
    remy = AssistantService(api);
    actions = DispatcherActions(h.dispatcher);
  });

  Future<AssistantReply> ask(String text, {InputModality modality = InputModality.text}) =>
      remy.interpret(AssistantInput(text, modality: modality), state: h.state, recipe: recipe, now: h.now);

  Future<void> ovenRunning() async {
    await h.dispatcher.completeStep('s1');
    await h.dispatcher.completeStep('s2');
    await h.confirm('s3', 'a1');
  }

  group('many natural phrasings, one meaning, zero API calls', () {
    setUp(() => api.forbidCalls = true);

    for (final s in ['הבא', 'סיימתי עם זה', 'יאללה ממשיכים', 'אפשר לעבור לשלב הבא', 'גמרנו', 'רמי, סיימנו', 'מוכן לשלב הבא']) {
      test('next: "$s"', () async {
        final r = await ask(s);
        expect(r.action, isA<CompleteStepAction>(), reason: s);
        expect(r.requiresConfirmation, isFalse);
      });
    }
    for (final s in ['תוסיף 5 דקות', 'תן לזה עוד חמש דקות', 'עוד 5 דק', 'צריך עוד חמש דקות', 'תאריך את הטיימר בחמש דקות', 'תוסיפי עוד חמש דקות לעוף']) {
      test('extend: "$s"', () async {
        await ovenRunning();
        final r = await ask(s);
        expect((r.action as ExtendTimerAction).seconds, 300, reason: s);
        expect(r.requiresConfirmation, isFalse);
      });
    }
    for (final s in ['כמה זמן נשאר?', 'עוד כמה זמן?', 'מה עם הטיימר', 'כמה דקות נשארו לעוף?', 'מתי לבדוק?']) {
      test('time left: "$s"', () async {
        await ovenRunning();
        expect((await ask(s)).answerHe, 'עוף בתנור: נשארו 45 דקות.', reason: s);
      });
    }
    for (final s in ['תבטל', 'חזרה', 'טעיתי', 'לא התכוונתי', 'אחורה בבקשה']) {
      test('undo: "$s"', () async {
        await h.dispatcher.completeStep('s1');
        expect((await ask(s)).action, isA<UndoLastAction>(), reason: s);
      });
    }
  });

  group('simple questions answered from the saved recipe and plan', () {
    setUp(() => api.forbidCalls = true);

    test('amount, temperature, next step, this step, steps left', () async {
      expect((await ask('כמה מלח צריך?')).answerHe, 'מלח: 1½ כפיות.');
      expect((await ask('מה השלב הבא?')).answerHe, 'אחרי זה: תיבול העוף.');
      expect((await ask('מה צריך לשלב הזה?')).answerHe, startsWith('בשלב הזה: תפוחי אדמה בינוניים'));
      expect((await ask('כמה שלבים נשארו?')).answerHe, 'נשארו 5 שלבים מתוך 5.');
      expect((await ask('כמה מעלות?')).answerHe, 'אפיית העוף ותפוחי האדמה: 200°.');
    });

    test('"מוכן?" asks whether it is ready: the step\'s cue, no action', () async {
      final r = await ask('מוכן?');
      expect(r.action, isNull);
    });
  });

  group('ambiguity is resolved by asking, locally', () {
    setUp(() => api.forbidCalls = true);

    test('unsure words ask before acting', () async {
      await ovenRunning();
      final r = await ask('אולי צריך עוד 5 דקות?');
      expect((r.action as ExtendTimerAction).seconds, 300);
      expect(r.requiresConfirmation, isTrue);
      final n = await ask('נראה לי שסיימתי');
      expect(n.requiresConfirmation, isTrue);
    });

    test('a transcription slip is understood, then confirmed', () async {
      await ovenRunning();
      final r = await ask('תוסיפ 5 דקות');
      expect(r.action, isA<ExtendTimerAction>());
      expect(r.requiresConfirmation, isTrue);
    });

    test('"עוד קצת" suggests the plan\'s re-check time and asks', () async {
      await ovenRunning();
      final r = await ask('תן לזה עוד קצת');
      expect((r.action as ExtendTimerAction).seconds, 300); // t1.recheck_seconds
      expect(r.requiresConfirmation, isTrue);
    });

    test('noise from speech recognition never reaches the server', () async {
      for (final s in ['…', 'א', '  ']) {
        expect((await ask(s, modality: InputModality.voice)).answerHe, 'לא הבנתי, אפשר לנסח שוב?');
      }
      expect(api.calls, isEmpty);
    });
  });

  group('Gemini as a fallback interpreter', () {
    test('an unfamiliar phrase becomes a validated command: one call, executed by the engine', () async {
      await ovenRunning();
      api.turns.add(const AssistantTurnResult(
        answerHe: 'מוסיף שלוש דקות לעוף.',
        speechHe: 'מוסיף שלוש דקות לעוף.',
        command: AssistantCommandData(action: 'extend_timer', timerId: 't1', seconds: 180),
      ));
      final end = h.state.timers['t1']!.endsAt!;
      final r = await ask('תמשך את זמן האפייה של העוף בשלוש דקות');
      expect(api.calls, ['assistantTurn']);
      expect(r.action, isA<ExtendTimerAction>());
      expect(r.requiresConfirmation, isFalse);
      final done = await remy.execute(r.action!, actions);
      expect(h.state.timers['t1']!.endsAt, end.add(const Duration(minutes: 3)));
      expect(done.answerHe, startsWith('⏱ הוספתי 3 דקות'));
    });

    test('an unsure interpretation asks first', () async {
      await ovenRunning();
      api.turns.add(const AssistantTurnResult(
        answerHe: 'אולי עוד שלוש דקות?',
        speechHe: 'אולי עוד שלוש דקות?',
        command: AssistantCommandData(action: 'extend_timer', timerId: 't1', seconds: 180, userUncertain: true),
      ));
      final r = await ask('לא יודע, העוף נראה לי קצת חיוור בצבע');
      expect(r.requiresConfirmation, isTrue);
    });

    test('finishing a step or starting a timer from an interpretation always asks', () async {
      await h.dispatcher.completeStep('s1');
      await h.dispatcher.completeStep('s2');
      api.turns.add(const AssistantTurnResult(
        answerHe: 'נשמע שהתבנית בפנים.',
        speechHe: 'נשמע שהתבנית בפנים.',
        command: AssistantCommandData(action: 'start_timer_action', stepId: 's3', actionId: 'a1'),
      ));
      final r = await ask('הפשטידה של העוף נמצאת כבר בחום');
      expect(r.action, isA<ConfirmStepAction>());
      expect(r.requiresConfirmation, isTrue);
      expect(h.state.timers, isEmpty);
    });

    for (final (name, command) in [
      ('a timer that is not running', const AssistantCommandData(action: 'extend_timer', timerId: 't2', seconds: 60)),
      ('a step that is not current', const AssistantCommandData(action: 'complete_step', stepId: 's5')),
      ('an action that is not available', const AssistantCommandData(action: 'start_timer_action', stepId: 's5', actionId: 'a1')),
      ('an unsupported action', const AssistantCommandData(action: 'delete_everything')),
      ('an extension that is too long', const AssistantCommandData(action: 'extend_timer', timerId: 't1', seconds: 99999)),
    ]) {
      test('an invalid interpretation is never executed: $name', () async {
        await ovenRunning();
        api.turns.add(AssistantTurnResult(answerHe: 'בסדר.', speechHe: 'בסדר.', command: command));
        final r = await ask('משפט לא מוכר שצריך פירוש');
        expect(r.action, isNull, reason: name);
      });
    }

    test('info commands are answered from local data', () async {
      await ovenRunning();
      api.turns.add(const AssistantTurnResult(answerHe: 'נשארו בערך 10 דקות', speechHe: 'x',
          command: AssistantCommandData(action: 'get_timer_status')));
      expect((await ask('איפה עומד העניין עם העוף')).answerHe, 'עוף בתנור: נשארו 45 דקות.');
    });
  });

  group('offline, quota and rate limits', () {
    for (final code in ['offline', 'timeout', 'ai_quota_exhausted', 'ai_rate_limited', 'ai_unavailable']) {
      test('$code: a friendly answer after one attempt; local commands keep working', () async {
        api.turns.add(ApiFailure(code));
        final r = await ask('משפט לא מוכר שצריך פירוש');
        expect(r.action, isNull);
        expect(r.answerHe, code == 'offline' || code == 'timeout' ? contains('אין חיבור לאינטרנט') : contains('לא זמין'));
        expect(api.calls, ['assistantTurn']); // no retry
        final next = await ask('הבא');
        await remy.execute(next.action!, actions);
        expect(h.state.isStepDone(h.state.plan.stepById('s1')!), isTrue);
      });
    }
  });

  test('spoken and typed versions of a command produce the same result', () async {
    await ovenRunning();
    for (final s in ['תוסיף 5 דקות', 'כמה זמן נשאר?', 'הכנסתי לתנור', 'מה השלב הבא?']) {
      final typed = await ask(s);
      final spoken = await ask(s, modality: InputModality.voice);
      expect(spoken.answerHe, typed.answerHe, reason: s);
      expect(spoken.speechHe, typed.speechHe, reason: s);
      expect(spoken.action.runtimeType, typed.action.runtimeType, reason: s);
      expect(spoken.requiresConfirmation, typed.requiresConfirmation, reason: s);
    }
    expect(api.calls, isEmpty);
  });

  test('the engine state stays untouched until an action is executed', () async {
    await ovenRunning();
    final before = h.store.events.length;
    await ask('תוסיף חצי שעה');
    await ask('אולי סיימתי');
    expect(h.store.events.length, before);
    expect(h.state.timers['t1']!.status, TimerStatus.running);
  });
}
