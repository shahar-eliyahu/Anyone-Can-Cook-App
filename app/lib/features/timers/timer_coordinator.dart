import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../cooking/engine/cooking_engine.dart';
import 'timer_notifier.dart';

/// Turns engine effects into scheduled notifications, and restores a session's
/// notifications from its replayed state (after app restart or force stop).
class TimerCoordinator {
  TimerCoordinator(this._notifier, this._clock);

  final TimerNotifier _notifier;
  final Clock _clock;

  Future<void> apply(String sessionId, List<EngineEffect> effects) async {
    for (final effect in effects) {
      switch (effect) {
        case ScheduleTimerNotification(:final timerId, :final endsAt, :final labelHe):
          await _notifier.scheduleTimer(
            sessionId: sessionId,
            timerId: timerId,
            endsAt: endsAt,
            labelHe: labelHe,
          );
        case CancelTimerNotification(:final timerId):
          await _notifier.cancelTimer(sessionId, timerId);
      }
    }
  }

  /// Makes the scheduled notifications match [state] exactly.
  Future<void> reconcile(String sessionId, CookingState state) async {
    await _notifier.cancelSession(sessionId);
    final now = _clock();
    for (final t in state.timers.values) {
      if (t.status == TimerStatus.running && t.endsAt!.isAfter(now)) {
        await _notifier.scheduleTimer(
          sessionId: sessionId,
          timerId: t.timerId,
          endsAt: t.endsAt!,
          labelHe: t.labelHe,
        );
      }
    }
  }

  Future<void> clearSession(String sessionId) => _notifier.cancelSession(sessionId);
}

final timerCoordinatorProvider = Provider<TimerCoordinator>(
  (ref) => TimerCoordinator(ref.watch(timerNotifierProvider), ref.watch(clockProvider)),
);
