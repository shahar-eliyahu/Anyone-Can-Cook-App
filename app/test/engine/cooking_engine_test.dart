import 'dart:convert';

import 'package:anyone_can_cook/features/cooking/engine/action_dispatcher.dart';
import 'package:anyone_can_cook/features/cooking/engine/cooking_engine.dart';
import 'package:anyone_can_cook/features/cooking/engine/events.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sample.dart';

List<String> ids(Iterable<AvailableAction> actions) =>
    [for (final a in actions) '${a.step.id}.${a.action.id}'];

void main() {
  group('initial state', () {
    test('only the first step is available; dependent steps are locked', () {
      final h = EngineHarness();
      expect(h.state.focusStep(h.now)!.id, 's1');
      expect(ids(h.state.availableActions(h.now)), ['s1.a1']);
      final status = {for (final s in h.state.plan.steps) s.id: h.state.statusOf(s, h.now)};
      expect(status, {
        's1': StepStatus.ready,
        's2': StepStatus.locked,
        's3': StepStatus.locked,
        's4': StepStatus.locked,
        's5': StepStatus.locked,
      });
    });

    test('prep tasks surface by rule: preheat at start, water with the rice step', () {
      final h = EngineHarness();
      final shown = h.state.prepTasksToShow(h.now);
      expect([for (final p in shown) p.task.id], ['p1']);
      expect(shown.single.urgent, isFalse);
    });
  });

  group('full cooking flow', () {
    test('steps, parallel work, multiple timers and completion', () async {
      final h = EngineHarness();
      await h.prepThroughSeasoning();

      // Baking and rice are now unlocked; boiling water appears; preheat is urgent.
      expect(ids(h.state.availableActions(h.now)), ['s3.a1', 's4.a1']);
      final prep = {for (final p in h.state.prepTasksToShow(h.now)) p.task.id: p.urgent};
      expect(prep, {'p1': true, 'p2': true});

      // "Put in oven" starts the plan's 45-minute timer.
      final bake = await h.confirm('s3', 'a1');
      expect(bake.isApplied, isTrue);
      expect(bake.startedTimer!.timerId, 't1');
      expect(bake.startedTimer!.totalSeconds, 2700);
      final schedule = h.effects.single as ScheduleTimerNotification;
      expect(schedule.timerId, 't1');
      expect(schedule.endsAt, h.now.add(const Duration(seconds: 2700)));

      // While baking, the rice step is suggested as parallel work.
      final s3 = h.state.plan.stepById('s3')!;
      expect(h.state.statusOf(s3, h.now), StepStatus.waitingTimer);
      expect([for (final s in h.state.meanwhile(h.now)) s.id], ['s4']);

      // Start the rice: two timers run at once.
      await h.confirm('s4', 'a1');
      expect([for (final t in h.state.activeTimers(h.now)) t.timerId], ['t2', 't1']);

      // Rice timer (18 min, from the plan) finishes first.
      h.clock.advance(const Duration(seconds: 1080));
      final rice = h.state.timers['t2']!;
      expect(rice.isFinished(h.now), isTrue);
      expect(h.state.activeTimers(h.now).first.timerId, 't2');
      expect(h.state.statusOf(h.state.plan.stepById('s4')!, h.now), StepStatus.inProgress);

      // Completing the rice step dismisses its timer.
      h.effects.clear();
      await h.confirm('s4', 'a2');
      expect(h.state.timers['t2']!.status, TimerStatus.dismissed);
      expect(h.effects.single, isA<CancelTimerNotification>());

      // Bake finishes; take out of the oven.
      h.clock.advance(const Duration(seconds: 2700 - 1080));
      expect(h.state.timers['t1']!.isFinished(h.now), isTrue);
      await h.confirm('s3', 'a2');
      expect(h.state.timers['t1']!.status, TimerStatus.dismissed);

      // Rest and serve.
      expect(ids(h.state.availableActions(h.now)), ['s5.a1']);
      final rest = await h.confirm('s5', 'a1');
      expect(rest.startedTimer!.totalSeconds, 300);
      await h.confirm('s5', 'a2');
      expect(h.state.isComplete, isTrue);
      expect(h.state.doneStepCount, 5);
      expect(h.state.focusStep(h.now), isNull);
      expect(h.state.activeTimers(h.now), isEmpty);
    });

    test('preheat prep task starts its own timer from the plan', () async {
      final h = EngineHarness();
      final r = await h.dispatcher.completePrepTask('p1');
      expect(r.isApplied, isTrue);
      expect(r.startedTimer!.timerId, 'tp1');
      expect(r.startedTimer!.totalSeconds, 900);
      expect(h.state.prepTasksToShow(h.now), isEmpty);
    });

    test('taking out of the oven early cancels the running bake timer', () async {
      final h = EngineHarness();
      await h.prepThroughSeasoning();
      await h.confirm('s3', 'a1');
      h.effects.clear();
      await h.confirm('s3', 'a2');
      expect(h.state.timers['t1']!.status, TimerStatus.dismissed);
      expect(h.effects.whereType<CancelTimerNotification>().single.timerId, 't1');
    });
  });

  group('duplicate prevention', () {
    test('confirming the same action twice is a no-op', () async {
      final h = EngineHarness();
      await h.prepThroughSeasoning();
      await h.confirm('s3', 'a1');
      final eventCount = h.store.events.length;
      h.effects.clear();

      final again = await h.confirm('s3', 'a1');
      expect(again.status, DispatchStatus.alreadyDone);
      expect(h.store.events, hasLength(eventCount));
      expect(h.effects, isEmpty);
      expect(h.state.timers, hasLength(1));
    });

    test('a UI tap followed by the agent produces one event, timer and notification', () async {
      final h = EngineHarness();
      await h.prepThroughSeasoning();
      h.effects.clear();
      await h.confirm('s3', 'a1');
      final agent = await h.confirm('s3', 'a1', source: ActionSource.agent, proposalId: 'prop-1');
      expect(agent.status, DispatchStatus.alreadyDone);
      expect(h.store.events.whereType<ActionConfirmed>().where((e) => e.stepId == 's3'), hasLength(1));
      expect(h.effects.whereType<ScheduleTimerNotification>(), hasLength(1));
    });

    test('a repeated proposal id is ignored', () async {
      final h = EngineHarness();
      final first = await h.confirm('s1', 'a1', source: ActionSource.agent, proposalId: 'p-7');
      expect(first.isApplied, isTrue);
      final replayed = await h.confirm('s1', 'a2', source: ActionSource.agent, proposalId: 'p-7');
      expect(replayed.status, DispatchStatus.alreadyDone);
      expect(h.state.isActionConfirmed('s1', 'a2'), isFalse);
    });

    test('two concurrent taps apply once', () async {
      final h = EngineHarness();
      final results = await Future.wait([h.confirm('s1', 'a1'), h.confirm('s1', 'a1')]);
      expect(results.map((r) => r.status), [DispatchStatus.applied, DispatchStatus.alreadyDone]);
      expect(h.store.events.whereType<ActionConfirmed>(), hasLength(1));
    });

    test('completing a prep task twice is a no-op', () async {
      final h = EngineHarness();
      await h.dispatcher.completePrepTask('p1');
      h.effects.clear();
      final again = await h.dispatcher.completePrepTask('p1');
      expect(again.status, DispatchStatus.alreadyDone);
      expect(h.effects, isEmpty);
    });
  });

  group('invalid actions change nothing', () {
    test('locked, out-of-order and unknown actions are rejected', () async {
      final h = EngineHarness();
      final count = h.store.events.length;
      expect((await h.confirm('s3', 'a1')).reason, 'step_locked');
      expect((await h.confirm('s1', 'a2')).reason, 'out_of_order');
      expect((await h.confirm('s1', 'zz')).reason, 'unknown_action');
      expect((await h.confirm('nope', 'a1')).reason, 'unknown_action');
      expect((await h.dispatcher.completePrepTask('p9')).reason, 'unknown_prep_task');
      expect(h.store.events, hasLength(count));
      expect(h.effects, isEmpty);
    });
  });

  test('UI and agent paths produce identical state', () async {
    final clock = FakeClock();
    final ui = EngineHarness(clock: clock);
    final agent = EngineHarness(clock: clock);
    for (final (step, action) in [('s1', 'a1'), ('s1', 'a2'), ('s2', 'a1'), ('s3', 'a1')]) {
      await ui.confirm(step, action);
      await agent.confirm(step, action, source: ActionSource.agent, proposalId: '$step$action');
    }
    expect(jsonEncode(agent.state.snapshot(clock.now)), jsonEncode(ui.state.snapshot(clock.now)));
    expect(agent.state.timers['t1']!.endsAt, ui.state.timers['t1']!.endsAt);
    expect(agent.effects.length, ui.effects.length);
  });

  group('undo', () {
    test('undoing a timer-starting action removes the timer and its notification', () async {
      final h = EngineHarness();
      await h.prepThroughSeasoning();
      await h.confirm('s3', 'a1');
      h.effects.clear();
      final r = await h.dispatcher.undoStep('s3');
      expect(r.isApplied, isTrue);
      expect(h.state.timers.containsKey('t1'), isFalse);
      expect(h.effects.single, isA<CancelTimerNotification>());
      expect(h.state.statusOf(h.state.plan.stepById('s3')!, h.now), StepStatus.ready);
    });

    test('cannot undo a step once a dependent step has progress', () async {
      final h = EngineHarness();
      await h.prepThroughSeasoning();
      expect((await h.dispatcher.undoStep('s1')).reason, 'dependent_started');
      expect((await h.dispatcher.undoStep('s4')).reason, 'nothing_to_undo');
    });

    test('undoing preheat cancels its timer', () async {
      final h = EngineHarness();
      await h.dispatcher.completePrepTask('p1');
      h.effects.clear();
      await h.dispatcher.undoPrepTask('p1');
      expect(h.state.timers.containsKey('tp1'), isFalse);
      expect(h.effects.single, isA<CancelTimerNotification>());
    });
  });

  group('timer controls', () {
    test('pause, resume and extend keep the remaining time exact', () async {
      final h = EngineHarness();
      await h.prepThroughSeasoning();
      await h.confirm('s3', 'a1');

      h.clock.advance(const Duration(seconds: 100));
      h.effects.clear();
      await h.dispatcher.pauseTimer('t1');
      expect(h.effects.single, isA<CancelTimerNotification>());
      h.clock.advance(const Duration(minutes: 10));
      expect(h.state.timers['t1']!.remaining(h.now), const Duration(seconds: 2600));

      h.effects.clear();
      await h.dispatcher.resumeTimer('t1');
      final resumed = h.effects.single as ScheduleTimerNotification;
      expect(resumed.endsAt, h.now.add(const Duration(seconds: 2600)));

      await h.dispatcher.extendTimer('t1');
      expect(h.state.timers['t1']!.remaining(h.now), const Duration(seconds: 2660));
      expect(h.state.timers['t1']!.totalSeconds, 2760);
    });

    test('extending a finished timer restarts it from now', () async {
      final h = EngineHarness();
      await h.dispatcher.completePrepTask('p1');
      h.clock.advance(const Duration(minutes: 20));
      expect(h.state.timers['tp1']!.isFinished(h.now), isTrue);
      await h.dispatcher.extendTimer('tp1');
      expect(h.state.timers['tp1']!.remaining(h.now), const Duration(seconds: 60));
    });

    test('paused timers keep the step waiting; dismissed timers disappear', () async {
      final h = EngineHarness();
      await h.prepThroughSeasoning();
      await h.confirm('s3', 'a1');
      await h.dispatcher.pauseTimer('t1');
      final s3 = h.state.plan.stepById('s3')!;
      expect(h.state.statusOf(s3, h.now), StepStatus.waitingTimer);
      await h.dispatcher.dismissTimer('t1');
      expect(h.state.activeTimers(h.now), isEmpty);
      expect((await h.dispatcher.dismissTimer('t1')).status, DispatchStatus.alreadyDone);
    });

    test('pausing a finished timer is rejected', () async {
      final h = EngineHarness();
      await h.dispatcher.completePrepTask('p1');
      h.clock.advance(const Duration(minutes: 16));
      expect((await h.dispatcher.pauseTimer('tp1')).reason, 'not_running');
    });
  });

  group('persistence', () {
    test('replaying stored events rebuilds the same state', () async {
      final h = EngineHarness();
      await h.dispatcher.completePrepTask('p1');
      await h.prepThroughSeasoning();
      await h.confirm('s3', 'a1');
      h.clock.advance(const Duration(seconds: 30));
      await h.dispatcher.pauseTimer('t1');
      await h.confirm('s4', 'a1');

      final replayed = CookingEngine.replay(h.state.plan, h.store.events);
      expect(jsonEncode(replayed.snapshot(h.now)), jsonEncode(h.state.snapshot(h.now)));
      for (final id in h.state.timers.keys) {
        expect(replayed.timers[id]!.endsAt, h.state.timers[id]!.endsAt);
        expect(replayed.timers[id]!.status, h.state.timers[id]!.status);
        expect(replayed.timers[id]!.pausedRemaining, h.state.timers[id]!.pausedRemaining);
      }
    });

    test('every event type survives JSON encoding', () {
      final at = DateTime.utc(2026, 10, 24, 18);
      final events = <CookingEvent>[
        SessionStarted(at),
        ActionConfirmed(at: at, stepId: 's1', actionId: 'a1', source: ActionSource.agent, proposalId: 'x'),
        PrepTaskDone(at: at, prepTaskId: 'p1', source: ActionSource.ui),
        PrepTaskUndone(at: at, prepTaskId: 'p1'),
        StepUndone(at: at, stepId: 's1'),
        TimerPaused(at: at, timerId: 't1'),
        TimerResumed(at: at, timerId: 't1'),
        TimerExtended(at: at, timerId: 't1', seconds: 60),
        TimerDismissed(at: at, timerId: 't1'),
      ];
      for (final e in events) {
        final decoded = CookingEvent.decode(
          e.type,
          jsonDecode(jsonEncode(e.toPayload())) as Map<String, dynamic>,
          e.at,
        );
        expect(decoded.type, e.type);
        expect(decoded.toPayload(), e.toPayload());
      }
    });
  });

  test('snapshot exposes available actions with plan timer durations', () async {
    final h = EngineHarness();
    await h.prepThroughSeasoning();
    final snap = h.state.snapshot(h.now);
    final actions = snap['available_actions']! as List;
    final bake = actions.cast<Map>().firstWhere((a) => a['step_id'] == 's3');
    expect(bake['action_id'], 'a1');
    expect((bake['starts_timer'] as Map)['seconds'], 2700);
    expect(snap['current_step_id'], 's3');
    expect(snap['completed_step_ids'], ['s1', 's2']);
  });
}
