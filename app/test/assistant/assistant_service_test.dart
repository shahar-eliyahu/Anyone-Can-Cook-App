import 'package:anyone_can_cook/core/api_client.dart';
import 'package:anyone_can_cook/features/assistant/assistant_models.dart';
import 'package:anyone_can_cook/features/assistant/assistant_service.dart';
import 'package:anyone_can_cook/features/cooking/engine/action_dispatcher.dart';
import 'package:anyone_can_cook/features/cooking/engine/cooking_engine.dart';
import 'package:anyone_can_cook/features/cooking/engine/events.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/sample.dart';

/// The dispatcher itself, as Remy's actions (the app uses the cooking controller).
class DispatcherActions implements CookingActions {
  DispatcherActions(this.d);
  final ActionDispatcher d;
  @override
  CookingState get state => d.state;
  @override
  DateTime now() => d.now();
  @override
  Future<DispatchResult> completeStep(String stepId) => d.completeStep(stepId, source: ActionSource.agent);
  @override
  Future<DispatchResult> confirmAction(String stepId, String actionId) => d.confirmAction(stepId, actionId, source: ActionSource.agent);
  @override
  Future<DispatchResult> completePrepTask(String id) => d.completePrepTask(id, source: ActionSource.agent);
  @override
  Future<DispatchResult> undoLast() => d.undoLast();
  @override
  Future<DispatchResult> extendTimer(String id, {int seconds = 60}) => d.extendTimer(id, seconds: seconds);
  @override
  Future<DispatchResult> pauseTimer(String id) => d.pauseTimer(id);
  @override
  Future<DispatchResult> resumeTimer(String id) => d.resumeTimer(id);
  @override
  Future<DispatchResult> applyPlanPatch(List<Map<String, dynamic>> ops, {required String summaryHe}) =>
      d.applyPlanPatch(ops, summaryHe: summaryHe);
}

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

  /// Runs automatic actions like the controller does; returns the final reply.
  Future<AssistantReply> say(String text) async {
    final reply = await ask(text);
    if (reply.action != null && !reply.requiresConfirmation) return remy.execute(reply.action!, actions);
    return reply;
  }

  Future<void> toTheOven() async {
    await h.dispatcher.completeStep('s1');
    await h.dispatcher.completeStep('s2');
  }

  test('"הבא" finishes an ordinary step at once — offline, no AI', () async {
    api.forbidCalls = true;
    final r = await say('הבא');
    expect(r.answerHe, '✓ סיימנו: הכנת תפוחי האדמה. עכשיו: תיבול העוף.');
    expect(h.state.isStepDone(h.state.plan.stepById('s1')!), isTrue);
    expect(h.store.events.whereType<ActionConfirmed>().every((e) => e.source == ActionSource.agent), isTrue);
    expect(api.calls, isEmpty);
  });

  test('"הבא" never starts a timer by itself: it asks first', () async {
    await toTheOven();
    final r = await ask('הבא');
    expect(r.requiresConfirmation, isTrue);
    expect(r.action, isA<ConfirmStepAction>());
    expect(r.answerHe, contains('הכנסתי לתנור'));
    expect(h.state.timers, isEmpty);
  });

  test('a clear report of the real-world action starts the plan timer at once', () async {
    await toTheOven();
    final r = await say('הכנסתי את התבנית לתנור');
    expect(h.state.timers['t1']!.totalSeconds, 2700); // duration from the plan
    expect(r.answerHe, contains('הטיימר "עוף בתנור" התחיל'));
    expect(h.effects.whereType<ScheduleTimerNotification>().single.timerId, 't1');
  });

  test('an intention never confirms anything', () async {
    await toTheOven();
    final r = await ask('אני עומד להכניס לתנור');
    expect(r.action, isNull);
    expect(r.answerHe, contains('הכנסתי לתנור'));
  });

  test('a reported prep task starts its timer ("הדלקתי את התנור")', () async {
    await say('הדלקתי את התנור');
    expect(h.state.prepDone, contains('p1'));
    expect(h.state.timers.containsKey('tp1'), isTrue);
  });

  test('extending: short runs at once, long asks, ambiguous asks which timer', () async {
    await toTheOven();
    await say('הכנסתי לתנור');
    final end = h.state.timers['t1']!.endsAt!;
    await say('תוסיף 5 דקות');
    expect(h.state.timers['t1']!.endsAt, end.add(const Duration(minutes: 5)));
    final long = await ask('תוסיף חצי שעה');
    expect(long.requiresConfirmation, isTrue);
    expect(long.action, isA<ExtendTimerAction>());
    expect(long.answerHe, contains('30 דקות'));
    await say('הוספתי את האורז'); // rice timer starts too
    final which = await ask('תוסיף 2 דקות');
    expect(which.action, isNull);
    expect(which.answerHe, startsWith('לאיזה טיימר?'));
    final rice = await ask('תוסיף 2 דקות לאורז');
    expect((rice.action as ExtendTimerAction).timerId, 't2');
  });

  test('how much time is left, in words fit for speech', () async {
    await toTheOven();
    await say('הכנסתי לתנור');
    h.clock.advance(const Duration(minutes: 12, seconds: 30));
    final r = await say('כמה זמן נשאר?');
    expect(r.answerHe, 'עוף בתנור: נשארו 32 דקות.');
    expect(r.speechHe, 'עוף בתנור: נשארו 32 דקות.');
  });

  test('"חזרה" undoes the last tap; nothing to undo is said plainly', () async {
    expect((await say('חזרה')).answerHe, 'אין עדיין מה לבטל.');
    await say('הבא');
    await say('חזרה');
    expect(h.state.confirmedIn('s1'), isEmpty);
  });

  test('safety and early finishing always ask first', () async {
    await toTheOven();
    await say('הכנסתי לתנור');
    final early = await ask('סיימתי');
    expect((early.requiresConfirmation, early.answerHe.contains('עוד רץ')), (true, true));
    h.clock.advance(const Duration(minutes: 45));
    final due = await ask('מוכן');
    expect(due.requiresConfirmation, isTrue);
    expect(due.answerHe, startsWith('לפני שממשיכים:'));
    // Only after approval does the step finish.
    await remy.execute(due.action!, actions);
    expect(h.state.isStepDone(h.state.plan.stepById('s3')!), isTrue);
  });

  test('what now and help come from the plan, offline', () async {
    api.forbidCalls = true;
    expect((await say('מה עכשיו?')).answerHe, startsWith('עכשיו: הכנת תפוחי האדמה.'));
    expect((await say('עזרה')).answerHe, contains('הקוביות צריכות להיות בגודל דומה'));
  });

  test('a real question goes to Remy with the live state; voice modality is passed on', () async {
    api.turns.add(const AssistantTurnResult(answerHe: 'לקפל זה לערבב בעדינות מלמטה למעלה.', speechHe: 'לקפל זה לערבב בעדינות.'));
    final r = await ask('מה זה לקפל?', modality: InputModality.voice);
    expect((r.answerHe, r.speechHe, r.source, r.action), ('לקפל זה לערבב בעדינות מלמטה למעלה.', 'לקפל זה לערבב בעדינות.', ReplySource.ai, null));
    expect(api.lastTurn!.modality, 'voice');
    expect(api.lastTurn!.snapshot['current_step_id'], 's1');
  });

  test('Remy proposes a change to a pending step; it applies only after approval and replays', () async {
    api.turns.add(const AssistantTurnResult(
      answerHe: 'אפשר להנמיך את האש באורז.',
      speechHe: 'אפשר להנמיך את האש באורז.',
      proposal: AssistantProposalData(kind: 'patch', summaryHe: 'אש נמוכה מאוד לאורז', ops: [
        {'op': 'add_step_note', 'step_id': 's4', 'note_he': 'על אש נמוכה מאוד.'},
      ]),
    ));
    final r = await ask('האורז שורף למטה, מה עושים?');
    expect(r.requiresConfirmation, isTrue);
    expect(r.action, isA<PatchPlanAction>());
    expect(h.state.plan.stepById('s4')!.notesHe, isEmpty);
    final done = await remy.execute(r.action!, actions);
    expect(done.answerHe, '✓ עדכנתי את השלבים הבאים: אש נמוכה מאוד לאורז.');
    expect(h.state.plan.stepById('s4')!.notesHe, ['על אש נמוכה מאוד.']);
    final replayed = CookingEngine.replay(loadSampleBundle().plan, h.store.events);
    expect(replayed.plan, h.state.plan);
    expect(replayed.patches.single.summaryHe, 'אש נמוכה מאוד לאורז');
  });

  test('a proposal for a step that already started is refused', () async {
    await h.dispatcher.completeStep('s1');
    api.turns.add(const AssistantTurnResult(
      answerHe: 'אפשר.',
      speechHe: 'אפשר.',
      proposal: AssistantProposalData(kind: 'patch', summaryHe: 'x', ops: [
        {'op': 'add_step_note', 'step_id': 's1', 'note_he': 'x'},
      ]),
    ));
    final r = await ask('אפשר לשנות את תפוחי האדמה?');
    expect(r.action, isNull);
    expect(r.answerHe, contains('השלב כבר התחיל'));
  });

  test('offline: questions say so, simple commands keep working', () async {
    api.turns.add(const ApiFailure('offline'));
    expect((await ask('מה זה לקפל?')).answerHe, contains('אין חיבור לאינטרנט'));
    await say('הבא');
    expect(h.state.isStepDone(h.state.plan.stepById('s1')!), isTrue);
  });

  test('pause and resume a timer by voice-like commands', () async {
    await toTheOven();
    await say('הכנסתי לתנור');
    await say('תעצור את הטיימר');
    expect(h.state.timers['t1']!.status, TimerStatus.paused);
    await say('המשך את הטיימר');
    expect(h.state.timers['t1']!.status, TimerStatus.running);
  });
}
