import 'package:anyone_can_cook/features/cooking/engine/action_dispatcher.dart';
import 'package:anyone_can_cook/features/cooking/engine/cooking_engine.dart';
import 'package:anyone_can_cook/features/cooking/engine/events.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sample.dart';

/// Phase 3C: one primary action per step ("סיימתי — לשלב הבא"), explicit timer
/// starts, and "חזרה" that undoes the last tap — all as existing events.
void main() {
  late EngineHarness h;
  setUp(() => h = EngineHarness());

  List<ActionConfirmed> confirmations() => h.store.events.whereType<ActionConfirmed>().toList();

  test('"done — next" confirms every remaining action of an ordinary step in one tap', () async {
    final step = h.state.plan.stepById('s1')!;
    expect(h.state.primaryFor(step, h.now)!.kind, PrimaryKind.next);
    final result = await h.dispatcher.completeStep('s1');
    expect(result.isApplied, isTrue);
    expect([for (final e in confirmations()) e.actionId], ['a1', 'a2']);
    expect(confirmations().map((e) => e.at).toSet(), hasLength(1)); // one tap
    expect(h.state.isStepDone(step), isTrue);
    expect(await h.dispatcher.completeStep('s1'), isA<DispatchResult>().having((r) => r.status, 's', DispatchStatus.alreadyDone));
    expect(confirmations(), hasLength(2));
  });

  test('a locked step cannot be completed', () async {
    final r = await h.dispatcher.completeStep('s3');
    expect(r.reason, 'step_locked');
    expect(confirmations(), isEmpty);
  });

  test('a timer never starts implicitly: the start action becomes the primary button', () async {
    await h.dispatcher.completeStep('s1');
    await h.dispatcher.completeStep('s2');
    final bake = h.state.plan.stepById('s3')!;
    final primary = h.state.primaryFor(bake, h.now)!;
    expect(primary.kind, PrimaryKind.startTimer);
    expect(primary.action!.action.labelHe, 'הכנסתי לתנור');
    final r = await h.dispatcher.completeStep('s3');
    expect(r.reason, 'needs_timer_start');
    expect(h.state.timers, isEmpty);
    expect(h.effects, isEmpty);
  });

  test('timed step: start, wait, check due with safety check, ready — next ends the timer', () async {
    await h.dispatcher.completeStep('s1');
    await h.dispatcher.completeStep('s2');
    final bake = h.state.plan.stepById('s3')!;
    final started = await h.confirm('s3', 'a1');
    expect(started.startedTimer!.timerId, 't1');
    expect(h.state.primaryFor(bake, h.now)!.kind, PrimaryKind.waiting);

    h.clock.advance(const Duration(seconds: 2700));
    final due = h.state.primaryFor(bake, h.now)!;
    expect(due.kind, PrimaryKind.checkDue);
    expect(due.timer!.timerId, 't1');
    expect(due.needsSafetyCheck, isTrue); // taking poultry out: always_ask

    await h.dispatcher.completeStep('s3');
    expect(h.state.isStepDone(bake), isTrue);
    expect(h.state.timers['t1']!.isActive, isFalse);
    expect(h.effects.whereType<CancelTimerNotification>().map((e) => e.timerId), contains('t1'));
  });

  test('"needs more time" uses the suggested re-check and keeps the step waiting', () async {
    await h.dispatcher.completeStep('s1');
    await h.dispatcher.completeStep('s2');
    await h.confirm('s3', 'a1');
    h.clock.advance(const Duration(seconds: 2700));
    await h.dispatcher.recheckTimer('t1');
    final bake = h.state.plan.stepById('s3')!;
    expect(h.state.primaryFor(bake, h.now)!.kind, PrimaryKind.waiting);
    expect(h.state.timers['t1']!.endsAt, h.now.add(const Duration(seconds: CookingEngine.defaultRecheckSeconds)));
  });

  test('ready early: completing while the timer runs ends it', () async {
    await h.dispatcher.completeStep('s1');
    await h.dispatcher.completeStep('s2');
    await h.confirm('s3', 'a1');
    h.clock.advance(const Duration(minutes: 10));
    await h.dispatcher.completeStep('s3');
    expect(h.state.timers['t1']!.isActive, isFalse);
  });

  test('"back" undoes the whole last tap, including several actions', () async {
    await h.dispatcher.completeStep('s1');
    await h.dispatcher.undoLast();
    final s1 = h.state.plan.stepById('s1')!;
    expect(h.state.confirmedIn('s1'), isEmpty);
    expect(h.state.statusOf(s1, h.now), StepStatus.ready);
    expect(h.state.log, isEmpty);
    expect(h.store.events.whereType<StepUndone>(), hasLength(2));
  });

  test('"back" after starting a timer cancels it and its notification', () async {
    await h.dispatcher.completeStep('s1');
    await h.dispatcher.completeStep('s2');
    await h.confirm('s3', 'a1');
    await h.dispatcher.undoLast();
    expect(h.state.timers.containsKey('t1'), isFalse);
    expect(h.effects.last, isA<CancelTimerNotification>().having((e) => e.timerId, 'id', 't1'));
  });

  test('"back" also undoes a finished prep task', () async {
    await h.dispatcher.completePrepTask('p1');
    expect(h.state.timers.containsKey('tp1'), isTrue);
    await h.dispatcher.undoLast();
    expect(h.state.prepDone, isEmpty);
    expect(h.state.timers.containsKey('tp1'), isFalse);
  });

  test('"back" walks back tap by tap; a step whose dependent has progress cannot be reopened', () async {
    await h.dispatcher.completeStep('s1');
    h.clock.advance(const Duration(seconds: 1));
    await h.dispatcher.completeStep('s2');
    await h.confirm('s3', 'a1'); // s3 depends on s2
    expect((await h.dispatcher.undoLast()).isApplied, isTrue); // the oven start
    expect((await h.dispatcher.undoLast()).isApplied, isTrue); // s2, now without dependent progress
    expect(h.state.confirmedIn('s2'), isEmpty);
    await h.dispatcher.completeStep('s2');
    await h.confirm('s4', 'a1'); // rice depends on s2 and has started
    expect((await h.dispatcher.undoStep('s2')).reason, 'dependent_started');
  });

  test('replaying the stored events rebuilds the same state, including the tap log', () async {
    await h.dispatcher.completePrepTask('p1');
    await h.dispatcher.completeStep('s1');
    await h.dispatcher.completeStep('s2');
    await h.confirm('s3', 'a1');
    await h.dispatcher.undoLast();
    final replayed = CookingEngine.replay(h.state.plan, h.store.events);
    expect(replayed.confirmed, h.state.confirmed);
    expect(replayed.prepDone, h.state.prepDone);
    expect(replayed.timers.keys, h.state.timers.keys);
    expect([for (final e in replayed.log) (e.stepId, e.actionId, e.prepTaskId)],
        [for (final e in h.state.log) (e.stepId, e.actionId, e.prepTaskId)]);
  });

  test('an old session (one tap per action) replays unchanged; "back" then undoes one action', () async {
    // Phase 1/2 style: separate taps a few seconds apart.
    await h.confirm('s1', 'a1');
    h.clock.advance(const Duration(seconds: 5));
    await h.confirm('s1', 'a2');
    final replayed = CookingEngine.replay(h.state.plan, h.store.events);
    expect(replayed.isStepDone(replayed.plan.stepById('s1')!), isTrue);
    expect(replayed.lastTap(), hasLength(1));
    await h.dispatcher.undoLast();
    expect(h.state.confirmedIn('s1'), ['a1']);
  });

  test('the safety check is required only when finishing confirms an always-ask action', () async {
    final s1 = h.state.plan.stepById('s1')!;
    expect(h.state.primaryFor(s1, h.now)!.needsSafetyCheck, isFalse);
  });
}
