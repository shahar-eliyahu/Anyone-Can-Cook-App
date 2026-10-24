import 'dart:async';

import 'cooking_engine.dart';
import 'events.dart';

enum DispatchStatus { applied, alreadyDone, invalid }

class DispatchResult {
  const DispatchResult(this.status, {this.reason, this.startedTimer});

  const DispatchResult.alreadyDone() : this(DispatchStatus.alreadyDone);
  const DispatchResult.invalid(String reason)
      : this(DispatchStatus.invalid, reason: reason);

  final DispatchStatus status;

  /// Machine-readable reason for [DispatchStatus.invalid].
  final String? reason;

  /// The timer started by this action, if any (duration comes from the plan).
  final TimerState? startedTimer;

  bool get isApplied => status == DispatchStatus.applied;
}

/// Persists events; implemented by the session repository.
abstract interface class CookingEventStore {
  Future<void> append(CookingEvent event);
}

typedef EffectHandler = Future<void> Function(List<EngineEffect> effects);

/// The single entry point for changing a cooking session. UI buttons and the
/// agent (Phase 3) both go through here, so they produce identical events.
///
/// Every call is validated against the live state, then persisted, reduced and
/// its effects run. Calls are serialized; duplicates are no-ops.
class ActionDispatcher {
  ActionDispatcher({
    required this._state,
    required this._store,
    required this._onEffects,
    required this._clock,
  });

  CookingState _state;
  final CookingEventStore _store;
  final EffectHandler _onEffects;
  final DateTime Function() _clock;
  Future<void> _queue = Future.value();

  CookingState get state => _state;

  /// Current time in UTC, truncated to whole seconds (matches stored events).
  DateTime now() {
    final ms = _clock().toUtc().millisecondsSinceEpoch;
    return DateTime.fromMillisecondsSinceEpoch(ms - ms % 1000, isUtc: true);
  }

  Future<DispatchResult> confirmAction(
    String stepId,
    String actionId, {
    ActionSource source = ActionSource.ui,
    String? proposalId,
  }) =>
      _serialized(() {
        if (proposalId != null && _state.proposalIds.contains(proposalId)) {
          return const DispatchResult.alreadyDone();
        }
        final step = _state.plan.stepById(stepId);
        if (step == null || step.actionById(actionId) == null) {
          return const DispatchResult.invalid('unknown_action');
        }
        if (_state.isActionConfirmed(stepId, actionId)) {
          return const DispatchResult.alreadyDone();
        }
        final at = now();
        final available = _state.availableActionFor(stepId, at);
        if (available == null || available.action.id != actionId) {
          return DispatchResult.invalid(switch (_state.statusOf(step, at)) {
            StepStatus.locked => 'step_locked',
            StepStatus.done => 'step_done',
            _ => 'out_of_order',
          });
        }
        return ActionConfirmed(
          at: at,
          stepId: stepId,
          actionId: actionId,
          source: source,
          proposalId: proposalId,
        );
      });

  /// "סיימתי — לשלב הבא" / "מוכן — לשלב הבא": confirms the step's remaining
  /// actions in order, as ordinary [ActionConfirmed] events from one tap (same
  /// time), and stops before an action that starts a timer: timers start only
  /// from the explicit tap that marks the real-world start.
  Future<DispatchResult> completeStep(
    String stepId, {
    ActionSource source = ActionSource.ui,
  }) =>
      _serialized(() {
        final step = _state.plan.stepById(stepId);
        if (step == null) return const DispatchResult.invalid('unknown_step');
        final at = now();
        switch (_state.statusOf(step, at)) {
          case StepStatus.done:
            return const DispatchResult.alreadyDone();
          case StepStatus.locked:
            return const DispatchResult.invalid('step_locked');
          default:
        }
        final events = [
          for (final a in _state.actionsToFinish(step))
            ActionConfirmed(at: at, stepId: stepId, actionId: a.id, source: source),
        ];
        if (events.isEmpty) return const DispatchResult.invalid('needs_timer_start');
        return events;
      });

  /// "חזרה": undoes the cook's last tap — every action it confirmed (cancelling
  /// a timer it started) or a finished prep task — unless a later step that
  /// depends on it already has progress.
  Future<DispatchResult> undoLast() => _serialized(() {
        final tap = _state.lastTap();
        if (tap.isEmpty) return const DispatchResult.invalid('nothing_to_undo');
        final at = now();
        if (tap.first.prepTaskId case final prep?) return PrepTaskUndone(at: at, prepTaskId: prep);
        final stepId = tap.first.stepId!;
        final dependentStarted = _state.plan.steps.any(
          (s) => s.dependsOn.contains(stepId) && _state.confirmedIn(s.id).isNotEmpty,
        );
        if (dependentStarted) return const DispatchResult.invalid('dependent_started');
        return [for (final _ in tap) StepUndone(at: at, stepId: stepId)];
      });

  Future<DispatchResult> completePrepTask(
    String prepTaskId, {
    ActionSource source = ActionSource.ui,
    String? proposalId,
  }) =>
      _serialized(() {
        if (proposalId != null && _state.proposalIds.contains(proposalId)) {
          return const DispatchResult.alreadyDone();
        }
        if (_state.plan.prepTaskById(prepTaskId) == null) {
          return const DispatchResult.invalid('unknown_prep_task');
        }
        if (_state.prepDone.contains(prepTaskId)) {
          return const DispatchResult.alreadyDone();
        }
        return PrepTaskDone(
          at: now(),
          prepTaskId: prepTaskId,
          source: source,
          proposalId: proposalId,
        );
      });

  Future<DispatchResult> undoPrepTask(String prepTaskId) => _serialized(() {
        if (!_state.prepDone.contains(prepTaskId)) {
          return const DispatchResult.invalid('not_done');
        }
        return PrepTaskUndone(at: now(), prepTaskId: prepTaskId);
      });

  /// Undo the latest action of a step, unless a dependent step has progress.
  Future<DispatchResult> undoStep(String stepId) => _serialized(() {
        if (_state.confirmedIn(stepId).isEmpty) {
          return const DispatchResult.invalid('nothing_to_undo');
        }
        final dependentStarted = _state.plan.steps.any(
          (s) => s.dependsOn.contains(stepId) && _state.confirmedIn(s.id).isNotEmpty,
        );
        if (dependentStarted) return const DispatchResult.invalid('dependent_started');
        return StepUndone(at: now(), stepId: stepId);
      });

  Future<DispatchResult> pauseTimer(String timerId) => _serialized(() {
        final t = _state.timers[timerId];
        final at = now();
        if (t == null || t.status != TimerStatus.running || t.isFinished(at)) {
          return const DispatchResult.invalid('not_running');
        }
        return TimerPaused(at: at, timerId: timerId);
      });

  Future<DispatchResult> resumeTimer(String timerId) => _serialized(() {
        if (_state.timers[timerId]?.status != TimerStatus.paused) {
          return const DispatchResult.invalid('not_paused');
        }
        return TimerResumed(at: now(), timerId: timerId);
      });

  Future<DispatchResult> extendTimer(String timerId, {int seconds = 60}) =>
      _serialized(() {
        if (!(_state.timers[timerId]?.isActive ?? false)) {
          return const DispatchResult.invalid('not_active');
        }
        if (seconds <= 0 || seconds > 3600) {
          return const DispatchResult.invalid('bad_duration');
        }
        return TimerExtended(at: now(), timerId: timerId, seconds: seconds);
      });

  Future<DispatchResult> shortenTimer(String timerId, {int seconds = 60}) =>
      _serialized(() {
        final t = _state.timers[timerId];
        if (t == null || !t.isActive || t.isFinished(now())) {
          return const DispatchResult.invalid('not_pending');
        }
        if (seconds <= 0 || seconds > 3600) {
          return const DispatchResult.invalid('bad_duration');
        }
        return TimerShortened(at: now(), timerId: timerId, seconds: seconds);
      });

  /// "Not ready — check again": only once the check time has been reached.
  Future<DispatchResult> recheckTimer(String timerId) => _serialized(() {
        final at = now();
        if (!(_state.timers[timerId]?.isFinished(at) ?? false)) {
          return const DispatchResult.invalid('not_due');
        }
        return TimerRechecked(at: at, timerId: timerId);
      });

  Future<DispatchResult> dismissTimer(String timerId) => _serialized(() {
        if (!(_state.timers[timerId]?.isActive ?? false)) {
          return const DispatchResult.alreadyDone();
        }
        return TimerDismissed(at: now(), timerId: timerId);
      });

  /// Runs [decide] after all earlier calls finish. [decide] returns either a
  /// final [DispatchResult] (nothing to do), the event to apply, or several
  /// events from one tap (applied in order; effects handled once at the end).
  Future<DispatchResult> _serialized(Object Function() decide) {
    final completer = Completer<DispatchResult>();
    _queue = _queue.then((_) async {
      try {
        final decision = decide();
        if (decision is DispatchResult) {
          completer.complete(decision);
          return;
        }
        final events = decision is List<CookingEvent> ? decision : [decision as CookingEvent];
        final before = _state.timers;
        final effects = <EngineEffect>[];
        for (final event in events) {
          await _store.append(event);
          final result = CookingEngine.reduce(_state, event);
          _state = result.state;
          effects.addAll(result.effects);
        }
        await _onEffects(effects);
        TimerState? started;
        for (final e in effects) {
          if (e is ScheduleTimerNotification && !before.containsKey(e.timerId)) {
            started = _state.timers[e.timerId];
          }
        }
        completer.complete(
          DispatchResult(DispatchStatus.applied, startedTimer: started),
        );
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }
}
