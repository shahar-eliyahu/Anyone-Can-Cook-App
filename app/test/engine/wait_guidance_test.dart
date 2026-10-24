import 'dart:convert';
import 'dart:io';

import 'package:anyone_can_cook/features/cooking/engine/action_dispatcher.dart';
import 'package:anyone_can_cook/features/cooking/engine/cooking_engine.dart';
import 'package:anyone_can_cook/features/cooking/engine/events.dart';
import 'package:anyone_can_cook/features/cooking/engine/plan_validator.dart';
import 'package:anyone_can_cook/features/timers/timer_coordinator.dart';
import 'package:anyone_can_cook/models/recipe_bundle.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/sample.dart';

RecipeBundle loadBread() =>
    RecipeBundle.decode(File('../shared/fixtures/sample_bread.json').readAsStringSync());

/// A started bread session whose notifications are synced after every event,
/// exactly like the app's cooking controller does.
class BreadHarness {
  BreadHarness() {
    final plan = loadBread().plan;
    final started = SessionStarted(clock.now);
    store.events.add(started);
    coordinator = TimerCoordinator(notifier, clock.call);
    dispatcher = ActionDispatcher(
      state: CookingEngine.reduce(CookingEngine.initial(plan), started).state,
      store: store,
      onEffects: (_) => coordinator.sync('S', dispatcher.state),
      clock: clock.call,
    );
  }

  final clock = FakeClock();
  final store = MemoryEventStore();
  final notifier = RecordingTimerNotifier();
  late final TimerCoordinator coordinator;
  late final ActionDispatcher dispatcher;

  CookingState get state => dispatcher.state;
  DateTime get now => clock.now;
  DateTime after(int seconds) => now.add(Duration(seconds: seconds));
  Set<String> get pending => {for (final k in notifier.scheduled.keys) k.substring(2)};

  Future<DispatchResult> confirm(String step, String action) =>
      dispatcher.confirmAction(step, action);

  /// Knead and start the first proof (60–90 minute range timer).
  Future<void> startFirstProof() async {
    await confirm('s1', 'a1');
    await confirm('s1', 'a2');
    await confirm('s2', 'a1');
  }
}

void main() {
  test('the bread fixture is a valid plan', () {
    final b = loadBread();
    expect(validatePlan(b.plan, recipe: b.recipe), isEmpty);
  });

  group('wait guidance', () {
    test('explains the wait, the check time, suggestions, tips and what comes next', () async {
      final h = BreadHarness();
      await h.startFirstProof();
      final g = h.state.waitGuidance(h.now).single;
      expect(g.timer.timerId, 't2');
      expect(g.waitInfoHe, contains('הבצק תופח'));
      expect(g.checkCueHe, contains('הכפיל את נפחו'));
      expect(g.timer.endsAt, h.after(3600));
      expect(g.timer.rangeEndsAt, h.after(5400));
      expect(g.checkDue, isFalse);
      expect([for (final p in g.suggestedPrep) p.id], ['p2']);
      expect(g.tips, hasLength(2));
      expect([for (final s in g.nextSteps) s.id], ['s3']);
    });

    test('suggestions are filtered by the live state', () async {
      final h = BreadHarness();
      await h.startFirstProof();
      await h.dispatcher.completePrepTask('p2');
      expect(h.state.waitGuidance(h.now).single.suggestedPrep, isEmpty);
    });

    test('meanwhile lists the plan suggestions for the focus step wait', () async {
      final h = EngineHarness(); // chicken: bake suggests rice (s4)
      await h.prepThroughSeasoning();
      await h.confirm('s3', 'a1');
      expect([for (final s in h.state.meanwhile(h.now)) s.id], ['s4']);
    });
  });

  group('notifications derived from state', () {
    test('a range timer gets one check and one end-of-range notification', () async {
      final h = BreadHarness();
      await h.startFirstProof();
      expect(h.pending, {'t2', 't2#end'});
      expect(h.notifier.scheduled['S/t2'], h.after(3600));
      expect(h.notifier.scheduled['S/t2#end'], h.after(5400));
    });

    test('wording says "time to check", never "ready"', () async {
      final h = BreadHarness();
      await h.startFirstProof();
      final (title, body) = h.notifier.texts['S/t2']!;
      expect(title, '⏰ התפחה ראשונה: זמן לבדוק');
      expect(body, contains('הכפיל את נפחו'));
      for (final (t, b) in h.notifier.texts.values) {
        expect('$t $b', isNot(contains('מוכן!')));
        expect('$t $b', isNot(contains('הזמן נגמר')));
      }
    });

    test('"check again" leaves exactly one notification and drops the range end', () async {
      final h = BreadHarness();
      await h.startFirstProof();
      h.clock.advance(const Duration(minutes: 60)); // check time reached
      final r = await h.dispatcher.recheckTimer('t2');
      expect(r.isApplied, isTrue);
      expect(h.pending, {'t2'});
      expect(h.notifier.scheduled['S/t2'], h.after(600)); // recheck_seconds
    });

    test('"check again" never goes past the end of the range', () async {
      final h = BreadHarness();
      await h.startFirstProof();
      h.clock.advance(const Duration(minutes: 85)); // 5 minutes before the range ends
      await h.dispatcher.recheckTimer('t2');
      expect(h.state.timers['t2']!.endsAt, h.after(300));
      expect(h.pending, {'t2'});
    });

    test('"check again" is only allowed once the check time is reached', () async {
      final h = BreadHarness();
      await h.startFirstProof();
      expect((await h.dispatcher.recheckTimer('t2')).reason, 'not_due');
    });

    test('pausing cancels, resuming restores both notifications at shifted times', () async {
      final h = BreadHarness();
      await h.startFirstProof();
      h.clock.advance(const Duration(minutes: 10));
      await h.dispatcher.pauseTimer('t2');
      expect(h.pending, isEmpty);
      h.clock.advance(const Duration(minutes: 30));
      await h.dispatcher.resumeTimer('t2');
      expect(h.notifier.scheduled['S/t2'], h.after(50 * 60));
      expect(h.notifier.scheduled['S/t2#end'], h.after(80 * 60));
    });

    test('extending and shortening move the check and the range end', () async {
      final h = BreadHarness();
      await h.startFirstProof();
      await h.dispatcher.extendTimer('t2', seconds: 600);
      expect(h.notifier.scheduled['S/t2'], h.after(4200));
      expect(h.notifier.scheduled['S/t2#end'], h.after(6000));
      await h.dispatcher.shortenTimer('t2', seconds: 1200);
      expect(h.notifier.scheduled['S/t2'], h.after(3000));
      expect(h.notifier.scheduled['S/t2#end'], h.after(4800));
    });

    test('completing the step cancels every notification of its timer', () async {
      final h = BreadHarness();
      await h.startFirstProof();
      await h.confirm('s2', 'a2');
      expect(h.pending.where((k) => k.startsWith('t2')), isEmpty);
    });

    test('prep reminder fires lead minutes before the gating wait and follows timer changes', () async {
      final h = BreadHarness();
      await h.startFirstProof();
      h.clock.advance(const Duration(minutes: 60));
      await h.confirm('s2', 'a2'); // proofed
      await h.confirm('s3', 'a1'); // second proof: 30 min, gates baking (s4)
      // Preheat (20 min lead) is reminded 10 minutes into the 30-minute proof.
      expect(h.notifier.scheduled['S/prep:p1'], h.after(600));
      expect(h.notifier.quiet, contains('S/prep:p1'));
      expect(h.notifier.texts['S/prep:p1']!.$1, '⏳ הדליקו את התנור על 220 מעלות');

      await h.dispatcher.extendTimer('t3', seconds: 300);
      expect(h.notifier.scheduled['S/prep:p1'], h.after(900));
      await h.dispatcher.shortenTimer('t3', seconds: 600);
      expect(h.notifier.scheduled['S/prep:p1'], h.after(300));
      await h.dispatcher.pauseTimer('t3');
      expect(h.pending.contains('prep:p1'), isFalse);
      await h.dispatcher.resumeTimer('t3');
      expect(h.notifier.scheduled['S/prep:p1'], h.after(300));

      // Doing the task cancels the reminder and starts the preheat timer.
      await h.dispatcher.completePrepTask('p1');
      expect(h.pending.contains('prep:p1'), isFalse);
      expect(h.pending, contains('tp1'));
      expect(h.notifier.texts['S/tp1']!.$2, 'בדקו שהתנור הגיע לחום');
    });

    test('a prep task becomes urgent in the app when its lead time arrives', () async {
      final h = BreadHarness();
      await h.startFirstProof();
      h.clock.advance(const Duration(minutes: 60));
      await h.confirm('s2', 'a2');
      await h.confirm('s3', 'a1');
      bool urgent() => h.state.prepTasksToShow(h.now).any((p) => p.task.id == 'p1' && p.urgent);
      expect(urgent(), isFalse);
      h.clock.advance(const Duration(minutes: 11));
      expect(urgent(), isTrue);
    });

    test('a delivered notification stays while relevant; nothing is scheduled twice', () async {
      final h = BreadHarness();
      await h.startFirstProof();
      final schedules = h.notifier.log.where((l) => l == 'schedule t2').length;
      // Unrelated events re-sync without rescheduling t2.
      await h.dispatcher.completePrepTask('p2');
      expect(h.notifier.log.where((l) => l == 'schedule t2').length, schedules);
      // After the check time passes, an unrelated sync does not remove it from the tray.
      h.clock.advance(const Duration(minutes: 61));
      await h.dispatcher.undoPrepTask('p2');
      expect(h.notifier.log, isNot(contains('cancel t2')));
    });

    test('notifications are capped: one per timer kind and one per prep task', () async {
      final h = BreadHarness();
      await h.startFirstProof();
      h.clock.advance(const Duration(minutes: 60));
      await h.confirm('s2', 'a2');
      await h.confirm('s3', 'a1');
      final keys = h.state.desiredNotifications(h.now).map((n) => n.key).toList();
      expect(keys.toSet().length, keys.length);
      expect(keys, unorderedEquals(['t3', 'prep:p1']));
    });

    test('restore after restart computes the same notifications', () async {
      final h = BreadHarness();
      await h.startFirstProof();
      h.clock.advance(const Duration(minutes: 10));
      await h.dispatcher.extendTimer('t2', seconds: 120);
      final replayed = CookingEngine.replay(h.state.plan, h.store.events);
      expect(replayed.desiredNotifications(h.now), h.state.desiredNotifications(h.now));
      final fresh = RecordingTimerNotifier();
      await TimerCoordinator(fresh, h.clock.call).reconcile('S', replayed);
      expect(fresh.scheduled, h.notifier.scheduled);
    });
  });

  test('new events survive JSON encoding', () {
    final at = DateTime.utc(2026, 10, 24, 18);
    for (final e in <CookingEvent>[
      TimerShortened(at: at, timerId: 't1', seconds: 60),
      TimerRechecked(at: at, timerId: 't1'),
    ]) {
      final decoded = CookingEvent.decode(
        e.type,
        jsonDecode(jsonEncode(e.toPayload())) as Map<String, dynamic>,
        e.at,
      );
      expect(decoded.toPayload(), e.toPayload());
    }
  });

  test('validator rejects a suggestion that waits for the same step', () {
    final plan = loadBread().plan;
    final bad = plan.copyWith(steps: [
      for (final s in plan.steps)
        s.id == 's2'
            ? s.copyWith(timers: [s.timers.single.copyWith(suggestDuring: ['s3'])])
            : s,
    ]);
    expect(validatePlan(bad), contains('t2: suggests s3, which waits for s2'));
  });
}
