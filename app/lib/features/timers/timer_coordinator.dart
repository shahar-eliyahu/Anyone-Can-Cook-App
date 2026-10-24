import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../models/cooking_plan.dart';
import '../cooking/engine/cooking_engine.dart';
import 'timer_notifier.dart';

/// Keeps a session's scheduled notifications equal to
/// [CookingState.desiredNotifications]: after every event ([sync]) and after a
/// restart or resume ([reconcile]). Nothing is scheduled twice, and nothing
/// obsolete stays pending.
class TimerCoordinator {
  TimerCoordinator(this._notifier, this._clock);

  final TimerNotifier _notifier;
  final Clock _clock;

  /// What this coordinator has scheduled: session → key → time.
  final _scheduled = <String, Map<String, DateTime>>{};

  /// Phase 1 path: applies engine effects directly. The app uses [sync].
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

  /// Schedules what changed and cancels what became obsolete.
  Future<void> sync(String sessionId, CookingState state) async {
    final now = _clock().toUtc();
    final desired = {for (final n in state.desiredNotifications(now)) n.key: n};
    final current = _scheduled.putIfAbsent(sessionId, () => {});

    for (final MapEntry(:key, value: at) in current.entries.toList()) {
      if (desired[key]?.at == at) continue;
      current.remove(key);
      // A notification already shown stays while it is still relevant; a
      // future one, or one for a finished timer or task, is removed.
      if (desired.containsKey(key) || at.isAfter(now) || !_stillRelevant(state, key)) {
        await _notifier.cancelNotification(sessionId, key);
      }
    }
    for (final n in desired.values) {
      if (current[n.key] == n.at) continue;
      await _notifier.scheduleNotification(
        sessionId: sessionId,
        key: n.key,
        at: n.at,
        title: _title(n),
        body: _body(n, state.plan),
        quiet: n.kind == NotificationKind.prepReminder,
      );
      current[n.key] = n.at;
    }
  }

  /// Makes the scheduled notifications match [state] exactly, from scratch.
  Future<void> reconcile(String sessionId, CookingState state) async {
    await _notifier.cancelSession(sessionId);
    _scheduled[sessionId] = {};
    await sync(sessionId, state);
  }

  Future<void> clearSession(String sessionId) async {
    _scheduled.remove(sessionId);
    await _notifier.cancelSession(sessionId);
  }

  static bool _stillRelevant(CookingState state, String key) {
    if (key.startsWith('prep:')) return !state.prepDone.contains(key.substring(5));
    final timerId = key.endsWith('#end') ? key.substring(0, key.length - 4) : key;
    return state.timers[timerId]?.isActive ?? false;
  }

  static String _title(PlannedNotification n) {
    final s = hebrewStrings;
    return switch (n.kind) {
      NotificationKind.check => s.notifCheckTitle(n.labelHe),
      NotificationKind.rangeEnd => s.notifRangeEndTitle(n.labelHe),
      NotificationKind.prepReminder => s.notifPrepTitle(n.labelHe),
    };
  }

  static String _body(PlannedNotification n, CookingPlan plan) {
    final s = hebrewStrings;
    final cue = n.cueHe;
    switch (n.kind) {
      case NotificationKind.check:
        if (cue != null) return s.notifCheckBody(cue);
        final prep = n.prepTaskId == null ? null : plan.prepTaskById(n.prepTaskId!);
        return prep?.kind == PrepKind.preheatOven ? s.notifPreheatBody : s.notifCheckBodyDefault;
      case NotificationKind.rangeEnd:
        return cue != null ? s.notifCheckBody(cue) : s.notifRangeEndBodyDefault;
      case NotificationKind.prepReminder:
        return s.notifPrepBody(n.leadMinutes ?? 0);
    }
  }
}

final timerCoordinatorProvider = Provider<TimerCoordinator>(
  (ref) => TimerCoordinator(ref.watch(timerNotifierProvider), ref.watch(clockProvider)),
);
