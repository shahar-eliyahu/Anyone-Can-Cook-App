import 'package:anyone_can_cook/features/cooking/engine/cooking_engine.dart';
import 'package:anyone_can_cook/features/timers/timer_coordinator.dart';
import 'package:anyone_can_cook/features/timers/timer_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/sample.dart';

void main() {
  test('engine effects become scheduled and cancelled notifications', () async {
    final h = EngineHarness();
    final notifier = RecordingTimerNotifier();
    final coordinator = TimerCoordinator(notifier, h.clock.call);
    await h.prepThroughSeasoning();
    await h.confirm('s3', 'a1');
    await coordinator.apply('S', h.effects);
    expect(notifier.scheduled, {'S/t1': h.now.add(const Duration(seconds: 2700))});

    h.effects.clear();
    await h.confirm('s3', 'a2');
    await coordinator.apply('S', h.effects);
    expect(notifier.scheduled, isEmpty);
  });

  test('reconcile restores running timers after a restart, skipping paused and finished ones', () async {
    final h = EngineHarness();
    await h.dispatcher.completePrepTask('p1'); // tp1: 15 min
    await h.prepThroughSeasoning();
    await h.confirm('s3', 'a1'); // t1: 45 min
    await h.confirm('s4', 'a1'); // t2: 18 min
    await h.dispatcher.pauseTimer('t2');
    h.clock.advance(const Duration(minutes: 20)); // tp1 has finished

    // Simulate an app restart: replay stored events, then reconcile.
    final restored = CookingEngine.replay(h.state.plan, h.store.events);
    final notifier = RecordingTimerNotifier()
      ..scheduled['S/stale'] = DateTime.utc(2000); // left over from before
    await TimerCoordinator(notifier, h.clock.call).reconcile('S', restored);

    expect(notifier.scheduled.keys, ['S/t1']);
    expect(notifier.scheduled['S/t1'], h.state.timers['t1']!.endsAt);
  });

  test('notification ids are stable and distinct per session timer', () {
    expect(timerNotificationId('a', 't1'), timerNotificationId('a', 't1'));
    expect(timerNotificationId('a', 't1'), isNot(timerNotificationId('a', 't2')));
    expect(timerNotificationId('a', 't1'), isNot(timerNotificationId('b', 't1')));
    expect(timerNotificationId('a', 't1'), greaterThan(1));
  });
}
