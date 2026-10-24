/// Deterministic cooking engine: pure Dart, no Flutter, no I/O.
///
/// State is rebuilt by replaying the session's events over the approved plan.
/// Timer durations always come from the plan; callers never pass durations
/// except explicit user adjustments ("+1 minute", "check again").
library;

import 'dart:math' as math;

import '../../../models/cooking_plan.dart';
import '../../../models/provenance.dart';
import 'events.dart';

enum StepStatus { locked, ready, inProgress, waitingTimer, done }

enum TimerStatus { running, paused, dismissed }

class TimerState {
  const TimerState({
    required this.timerId,
    required this.labelHe,
    required this.provenance,
    required this.totalSeconds,
    required this.status,
    this.endsAt,
    this.pausedRemaining,
    this.rangeEndsAt,
    this.pausedRangeRemaining,
    this.rechecked = false,
    this.stepId,
    this.prepTaskId,
  });

  final String timerId;
  final String labelHe;
  final Provenance provenance;

  /// Plan duration plus any user adjustments.
  final int totalSeconds;
  final TimerStatus status;

  /// When to check (the "time to check" moment).
  final DateTime? endsAt;
  final Duration? pausedRemaining;

  /// End of the plan's time range (`max_seconds`), if any.
  final DateTime? rangeEndsAt;
  final Duration? pausedRangeRemaining;

  /// "Not ready — check again" was used; the next check replaces the range end.
  final bool rechecked;

  /// Owner: the step or prep task whose action started the timer.
  final String? stepId;
  final String? prepTaskId;

  bool get isActive => status != TimerStatus.dismissed;

  bool isFinished(DateTime now) =>
      status == TimerStatus.running && !now.isBefore(endsAt!);

  /// Waiting for time to pass (running and not finished, or paused).
  bool isPending(DateTime now) =>
      status == TimerStatus.paused ||
      (status == TimerStatus.running && now.isBefore(endsAt!));

  Duration remaining(DateTime now) => switch (status) {
        TimerStatus.running =>
          now.isBefore(endsAt!) ? endsAt!.difference(now) : Duration.zero,
        TimerStatus.paused => pausedRemaining!,
        TimerStatus.dismissed => Duration.zero,
      };

  TimerState copyWith({
    int? totalSeconds,
    TimerStatus? status,
    DateTime? endsAt,
    Duration? pausedRemaining,
    DateTime? rangeEndsAt,
    Duration? pausedRangeRemaining,
    bool? rechecked,
  }) =>
      TimerState(
        timerId: timerId,
        labelHe: labelHe,
        provenance: provenance,
        totalSeconds: totalSeconds ?? this.totalSeconds,
        status: status ?? this.status,
        endsAt: endsAt ?? this.endsAt,
        pausedRemaining: pausedRemaining ?? this.pausedRemaining,
        rangeEndsAt: rangeEndsAt ?? this.rangeEndsAt,
        pausedRangeRemaining: pausedRangeRemaining ?? this.pausedRangeRemaining,
        rechecked: rechecked ?? this.rechecked,
        stepId: stepId,
        prepTaskId: prepTaskId,
      );
}

sealed class EngineEffect {
  const EngineEffect(this.timerId);
  final String timerId;
}

/// Schedule (or reschedule) the notification for a timer.
class ScheduleTimerNotification extends EngineEffect {
  const ScheduleTimerNotification(super.timerId, this.endsAt, this.labelHe);
  final DateTime endsAt;
  final String labelHe;
}

class CancelTimerNotification extends EngineEffect {
  const CancelTimerNotification(super.timerId);
}

class ReduceResult {
  const ReduceResult(this.state, [this.effects = const []]);
  final CookingState state;
  final List<EngineEffect> effects;
}

class AvailableAction {
  const AvailableAction(this.step, this.action, this.timer);
  final PlanStep step;
  final StepAction action;

  /// The plan timer this action starts, if any.
  final PlanTimer? timer;
}

class PrepTaskView {
  const PrepTaskView(this.task, {required this.urgent});
  final PrepTask task;

  /// Needed now: the step that needs it is unlocked, or will be within the
  /// task's lead time.
  final bool urgent;
}

enum NotificationKind { check, rangeEnd, prepReminder }

/// A notification that should be scheduled for the current state.
class PlannedNotification {
  const PlannedNotification({
    required this.key,
    required this.at,
    required this.kind,
    required this.labelHe,
    this.cueHe,
    this.timerId,
    this.prepTaskId,
    this.leadMinutes,
  });

  /// Stable per session: the timer id, `{timer}#end`, or `prep:{task}`.
  final String key;
  final DateTime at;
  final NotificationKind kind;
  final String labelHe;
  final String? cueHe;
  final String? timerId;
  final String? prepTaskId;
  final int? leadMinutes;

  @override
  bool operator ==(Object other) =>
      other is PlannedNotification && other.key == key && other.at == at;

  @override
  int get hashCode => Object.hash(key, at);
}

/// Guidance for one wait: what is happening, when to check, what to do meanwhile.
class WaitGuidance {
  const WaitGuidance({
    required this.timer,
    required this.planTimer,
    required this.step,
    required this.checkDue,
    required this.suggestedActions,
    required this.suggestedPrep,
    required this.tips,
    required this.nextSteps,
  });

  final TimerState timer;
  final PlanTimer? planTimer;
  final PlanStep? step;

  /// The check time has been reached.
  final bool checkDue;
  final List<AvailableAction> suggestedActions;
  final List<PrepTask> suggestedPrep;
  final List<String> tips;

  /// Not-yet-done steps that depend on this wait's step.
  final List<PlanStep> nextSteps;

  String? get waitInfoHe => planTimer?.waitInfoHe;
  String? get checkCueHe => planTimer?.checkCueHe ?? step?.donenessCueHe;
}

class CookingState {
  const CookingState({
    required this.plan,
    this.startedAt,
    this.confirmed = const {},
    this.prepDone = const {},
    this.timers = const {},
    this.proposalIds = const {},
  });

  final CookingPlan plan;
  final DateTime? startedAt;

  /// Confirmed action ids per step, in confirmation order.
  final Map<String, List<String>> confirmed;
  final Set<String> prepDone;
  final Map<String, TimerState> timers;

  /// Agent proposal ids already applied (duplicate protection).
  final Set<String> proposalIds;

  CookingState copyWith({
    DateTime? startedAt,
    Map<String, List<String>>? confirmed,
    Set<String>? prepDone,
    Map<String, TimerState>? timers,
    Set<String>? proposalIds,
  }) =>
      CookingState(
        plan: plan,
        startedAt: startedAt ?? this.startedAt,
        confirmed: confirmed ?? this.confirmed,
        prepDone: prepDone ?? this.prepDone,
        timers: timers ?? this.timers,
        proposalIds: proposalIds ?? this.proposalIds,
      );

  // ---- Derived views -------------------------------------------------------

  List<String> confirmedIn(String stepId) => confirmed[stepId] ?? const [];

  bool isActionConfirmed(String stepId, String actionId) =>
      confirmedIn(stepId).contains(actionId);

  bool isStepDone(PlanStep step) {
    final completing = step.actions.firstWhere(
      (a) => a.completesStep,
      orElse: () => step.actions.last,
    );
    return isActionConfirmed(step.id, completing.id);
  }

  StepStatus statusOf(PlanStep step, DateTime now) {
    if (isStepDone(step)) return StepStatus.done;
    final locked = step.dependsOn.any((dep) {
      final d = plan.stepById(dep);
      return d != null && !isStepDone(d);
    });
    if (locked) return StepStatus.locked;
    final waiting = timers.values
        .any((t) => t.stepId == step.id && t.isPending(now));
    if (waiting) return StepStatus.waitingTimer;
    if (confirmedIn(step.id).isNotEmpty) return StepStatus.inProgress;
    return StepStatus.ready;
  }

  /// The next action of a step, if the step is unlocked and not done.
  AvailableAction? availableActionFor(String stepId, DateTime now) {
    final step = plan.stepById(stepId);
    if (step == null) return null;
    final status = statusOf(step, now);
    if (status == StepStatus.locked || status == StepStatus.done) return null;
    final index = confirmedIn(step.id).length;
    if (index >= step.actions.length) return null;
    final action = step.actions[index];
    final timer =
        action.startsTimer == null ? null : plan.timersById[action.startsTimer];
    return AvailableAction(step, action, timer);
  }

  /// Every action that can be confirmed right now, in plan order.
  List<AvailableAction> availableActions(DateTime now) => [
        for (final step in plan.steps) ?availableActionFor(step.id, now),
      ];

  /// The step the cook should focus on: the first unlocked step not done.
  PlanStep? focusStep(DateTime now) {
    for (final step in plan.steps) {
      final s = statusOf(step, now);
      if (s != StepStatus.done && s != StepStatus.locked) return step;
    }
    return null;
  }

  /// Steps that can be done while the focus step waits on a timer: the plan's
  /// suggestions for that wait first, then other steps marked `parallel_ok`.
  List<PlanStep> meanwhile(DateTime now) {
    final focus = focusStep(now);
    if (focus == null || statusOf(focus, now) != StepStatus.waitingTimer) {
      return const [];
    }
    bool doable(PlanStep s) =>
        s.id != focus.id &&
        statusOf(s, now) != StepStatus.done &&
        statusOf(s, now) != StepStatus.locked;
    final suggested = <String>[
      for (final t in timers.values)
        if (t.stepId == focus.id && t.isPending(now))
          ...?plan.timersById[t.timerId]?.suggestDuring,
    ];
    final result = <PlanStep>[];
    for (final id in suggested) {
      final s = plan.stepById(id);
      if (s != null && doable(s) && !result.contains(s)) result.add(s);
    }
    for (final s in plan.steps) {
      if (s.parallelOk && doable(s) && !result.contains(s)) result.add(s);
    }
    return result;
  }

  List<PrepTask> pendingPrepTasks() =>
      [for (final p in plan.prepTasks) if (!prepDone.contains(p.id)) p];

  /// Pending timers whose step must finish before [stepId] can start.
  List<TimerState> _gatingTimers(String stepId, DateTime now) {
    final step = plan.stepById(stepId);
    if (step == null) return const [];
    return [
      for (final t in timers.values)
        if (t.stepId != null && step.dependsOn.contains(t.stepId) && t.isPending(now)) t,
    ];
  }

  /// Time until [stepId] is expected to unlock, if it can be estimated: the
  /// longest gating timer, or the estimated active minutes of unfinished
  /// dependencies (only when every one of them has an estimate).
  Duration? _timeUntilNeeded(String stepId, DateTime now) {
    final step = plan.stepById(stepId);
    if (step == null) return null;
    final gating = _gatingTimers(stepId, now);
    if (gating.isNotEmpty) {
      return gating.map((t) => t.remaining(now)).reduce((a, b) => a > b ? a : b);
    }
    final open = [
      for (final dep in step.dependsOn)
        if (plan.stepById(dep) case final d? when !isStepDone(d)) d,
    ];
    if (open.isEmpty || open.any((d) => d.estimatedActiveMinutes == null)) return null;
    final minutes = open.map((d) => d.estimatedActiveMinutes!.value).fold(0, math.max);
    return Duration(minutes: minutes);
  }

  /// Prep tasks to show now: not done, and their surface condition is met or
  /// they are needed now.
  List<PrepTaskView> prepTasksToShow(DateTime now) {
    bool unlocked(String? stepId) {
      final step = stepId == null ? null : plan.stepById(stepId);
      return step != null && statusOf(step, now) != StepStatus.locked;
    }

    bool dueByTime(PrepTask p) {
      final lead = p.leadMinutes?.value;
      final needed = p.neededByStep;
      if (lead == null || needed == null) return false;
      final until = _timeUntilNeeded(needed, now);
      return until != null && until <= Duration(minutes: lead);
    }

    return [
      for (final p in pendingPrepTasks())
        if (p.surface.atStart || unlocked(p.surface.withStep) || dueByTime(p))
          PrepTaskView(p, urgent: unlocked(p.neededByStep) || dueByTime(p)),
    ];
  }

  /// Timers to show, finished ones first, then by time remaining.
  List<TimerState> activeTimers(DateTime now) {
    final list = [for (final t in timers.values) if (t.isActive) t];
    list.sort((a, b) {
      final fa = a.isFinished(now), fb = b.isFinished(now);
      if (fa != fb) return fa ? -1 : 1;
      return a.remaining(now).compareTo(b.remaining(now));
    });
    return list;
  }

  /// Guidance for each active step timer: what is happening, when to check,
  /// what to do meanwhile (filtered by the live state) and what comes next.
  List<WaitGuidance> waitGuidance(DateTime now) {
    final result = <WaitGuidance>[];
    for (final t in activeTimers(now)) {
      final planTimer = plan.timersById[t.timerId];
      final step = t.stepId == null ? null : plan.stepById(t.stepId!);
      if (step == null) continue;
      final actions = <AvailableAction>[];
      final prep = <PrepTask>[];
      for (final id in planTimer?.suggestDuring ?? const <String>[]) {
        if (availableActionFor(id, now) case final a? when id != step.id) {
          actions.add(a);
        } else if (plan.prepTaskById(id) case final p? when !prepDone.contains(p.id)) {
          prep.add(p);
        }
      }
      result.add(WaitGuidance(
        timer: t,
        planTimer: planTimer,
        step: step,
        checkDue: t.isFinished(now),
        suggestedActions: actions,
        suggestedPrep: prep,
        tips: planTimer?.meanwhileTipsHe ?? const [],
        nextSteps: [
          for (final s in plan.steps)
            if (s.dependsOn.contains(step.id) && !isStepDone(s)) s,
        ],
      ));
    }
    return result;
  }

  /// Every notification that should exist for this state. At most: one check
  /// per running timer, one end-of-range per range timer (until "check again"
  /// is used), and one reminder per prep task. Past times are left out.
  List<PlannedNotification> desiredNotifications(DateTime now) {
    final result = <PlannedNotification>[];
    for (final t in timers.values) {
      if (t.status != TimerStatus.running) continue;
      final planTimer = plan.timersById[t.timerId];
      final step = t.stepId == null ? null : plan.stepById(t.stepId!);
      final cue = planTimer?.checkCueHe ?? step?.donenessCueHe;
      if (t.endsAt!.isAfter(now)) {
        result.add(PlannedNotification(
          key: t.timerId,
          at: t.endsAt!,
          kind: NotificationKind.check,
          labelHe: t.labelHe,
          cueHe: cue,
          timerId: t.timerId,
          prepTaskId: t.prepTaskId,
        ));
      }
      final rangeEnd = t.rangeEndsAt;
      if (!t.rechecked && rangeEnd != null && rangeEnd.isAfter(t.endsAt!) && rangeEnd.isAfter(now)) {
        result.add(PlannedNotification(
          key: '${t.timerId}#end',
          at: rangeEnd,
          kind: NotificationKind.rangeEnd,
          labelHe: t.labelHe,
          cueHe: cue,
          timerId: t.timerId,
        ));
      }
    }
    for (final p in pendingPrepTasks()) {
      final lead = p.leadMinutes?.value;
      final needed = p.neededByStep;
      if (!p.remindBeforeNeeded || lead == null || needed == null) continue;
      final gating = _gatingTimers(needed, now).where((t) => t.status == TimerStatus.running);
      if (gating.isEmpty) continue;
      final gateEnd = gating.map((t) => t.endsAt!).reduce((a, b) => a.isAfter(b) ? a : b);
      final at = gateEnd.subtract(Duration(minutes: lead));
      if (at.isAfter(now)) {
        result.add(PlannedNotification(
          key: 'prep:${p.id}',
          at: at,
          kind: NotificationKind.prepReminder,
          labelHe: p.textHe,
          prepTaskId: p.id,
          leadMinutes: lead,
        ));
      }
    }
    return result;
  }

  int get doneStepCount => plan.steps.where(isStepDone).length;

  bool get isComplete => plan.steps.every(isStepDone);

  /// Compact JSON of the live state, used as context for the cooking agent.
  Map<String, Object?> snapshot(DateTime now) {
    final focus = focusStep(now);
    return {
      'current_step_id': focus?.id,
      'completed_step_ids': [
        for (final s in plan.steps) if (isStepDone(s)) s.id,
      ],
      'pending_step_ids': [
        for (final s in plan.steps) if (!isStepDone(s)) s.id,
      ],
      'available_actions': [
        for (final a in availableActions(now))
          {
            'step_id': a.step.id,
            'action_id': a.action.id,
            'label_he': a.action.labelHe,
            'starts_timer': a.timer == null
                ? null
                : {
                    'id': a.timer!.id,
                    'label_he': a.timer!.labelHe,
                    'seconds': a.timer!.seconds,
                  },
          },
      ],
      'pending_prep_tasks': [
        for (final p in pendingPrepTasks()) {'id': p.id, 'text_he': p.textHe},
      ],
      'active_timers': [
        for (final t in activeTimers(now))
          {
            'id': t.timerId,
            'label_he': t.labelHe,
            'status': t.isFinished(now) ? 'check_due' : t.status.name,
            'remaining_seconds': t.remaining(now).inSeconds,
          },
      ],
      'next_guidance': {
        'focus_step_id': focus?.id,
        'meanwhile_step_ids': [for (final s in meanwhile(now)) s.id],
        'due_prep_task_ids': [
          for (final p in prepTasksToShow(now)) if (p.urgent) p.task.id,
        ],
      },
    };
  }
}

abstract final class CookingEngine {
  static CookingState initial(CookingPlan plan) => CookingState(plan: plan);

  static CookingState replay(CookingPlan plan, Iterable<CookingEvent> events) =>
      events.fold(initial(plan), (state, e) => reduce(state, e).state);

  static ReduceResult reduce(CookingState s, CookingEvent event) {
    final plan = s.plan;
    switch (event) {
      case SessionStarted(:final at):
        return ReduceResult(s.copyWith(startedAt: s.startedAt ?? at));

      case ActionConfirmed(:final at, :final stepId, :final actionId):
        final step = plan.stepById(stepId);
        final action = step?.actionById(actionId);
        if (step == null || action == null || s.isActionConfirmed(stepId, actionId)) {
          return ReduceResult(s);
        }
        final timers = Map.of(s.timers);
        final effects = <EngineEffect>[];
        final timerId = action.startsTimer;
        if (timerId != null && !timers.containsKey(timerId)) {
          final t = plan.timersById[timerId];
          if (t != null) {
            timers[timerId] = _start(t, at, stepId: stepId);
            effects.add(_schedule(timers[timerId]!));
          }
        }
        if (action.completesStep) {
          for (final t in step.timers) {
            final current = timers[t.id];
            if (current != null && current.isActive) {
              timers[t.id] = current.copyWith(status: TimerStatus.dismissed);
              effects.add(CancelTimerNotification(t.id));
            }
          }
        }
        return ReduceResult(
          s.copyWith(
            confirmed: {...s.confirmed, stepId: [...s.confirmedIn(stepId), actionId]},
            timers: timers,
            proposalIds: _withProposal(s.proposalIds, event.proposalId),
          ),
          effects,
        );

      case PrepTaskDone(:final at, :final prepTaskId):
        final task = plan.prepTaskById(prepTaskId);
        if (task == null || s.prepDone.contains(prepTaskId)) return ReduceResult(s);
        final timers = Map.of(s.timers);
        final effects = <EngineEffect>[];
        final t = task.timer;
        if (t != null && !timers.containsKey(t.id)) {
          timers[t.id] = _start(t, at, prepTaskId: prepTaskId);
          effects.add(_schedule(timers[t.id]!));
        }
        return ReduceResult(
          s.copyWith(
            prepDone: {...s.prepDone, prepTaskId},
            timers: timers,
            proposalIds: _withProposal(s.proposalIds, event.proposalId),
          ),
          effects,
        );

      case PrepTaskUndone(:final prepTaskId):
        final task = plan.prepTaskById(prepTaskId);
        if (task == null || !s.prepDone.contains(prepTaskId)) return ReduceResult(s);
        final timers = Map.of(s.timers);
        final effects = <EngineEffect>[];
        if (task.timer != null && timers.remove(task.timer!.id) != null) {
          effects.add(CancelTimerNotification(task.timer!.id));
        }
        return ReduceResult(
          s.copyWith(prepDone: {...s.prepDone}..remove(prepTaskId), timers: timers),
          effects,
        );

      case StepUndone(:final stepId):
        final step = plan.stepById(stepId);
        final done = s.confirmedIn(stepId);
        if (step == null || done.isEmpty) return ReduceResult(s);
        final action = step.actionById(done.last);
        final timers = Map.of(s.timers);
        final effects = <EngineEffect>[];
        final timerId = action?.startsTimer;
        if (timerId != null && timers.remove(timerId) != null) {
          effects.add(CancelTimerNotification(timerId));
        }
        return ReduceResult(
          s.copyWith(
            confirmed: {...s.confirmed, stepId: done.sublist(0, done.length - 1)},
            timers: timers,
          ),
          effects,
        );

      case TimerPaused(:final at, :final timerId):
        final t = s.timers[timerId];
        if (t == null || t.status != TimerStatus.running || t.isFinished(at)) {
          return ReduceResult(s);
        }
        final rangeEnd = t.rangeEndsAt;
        return _withTimer(
          s,
          t.copyWith(
            status: TimerStatus.paused,
            pausedRemaining: t.remaining(at),
            pausedRangeRemaining:
                rangeEnd != null && rangeEnd.isAfter(at) ? rangeEnd.difference(at) : null,
          ),
          CancelTimerNotification(timerId),
        );

      case TimerResumed(:final at, :final timerId):
        final t = s.timers[timerId];
        if (t == null || t.status != TimerStatus.paused) return ReduceResult(s);
        final resumed = t.copyWith(
          status: TimerStatus.running,
          endsAt: at.add(t.pausedRemaining!),
          rangeEndsAt: t.pausedRangeRemaining == null ? null : at.add(t.pausedRangeRemaining!),
        );
        return _withTimer(s, resumed, _schedule(resumed));

      case TimerExtended(:final at, :final timerId, :final seconds):
        final t = s.timers[timerId];
        if (t == null || !t.isActive || seconds <= 0) return ReduceResult(s);
        final extra = Duration(seconds: seconds);
        if (t.status == TimerStatus.paused) {
          return _withTimer(
            s,
            t.copyWith(
              totalSeconds: t.totalSeconds + seconds,
              pausedRemaining: t.pausedRemaining! + extra,
              pausedRangeRemaining: t.pausedRangeRemaining == null ? null : t.pausedRangeRemaining! + extra,
            ),
          );
        }
        final finished = t.isFinished(at);
        final newEnd = (finished ? at : t.endsAt!).add(extra);
        final range = t.rangeEndsAt;
        final extended = t.copyWith(
          totalSeconds: t.totalSeconds + seconds,
          endsAt: newEnd,
          // The range keeps its width when extended early; it never ends before the check.
          rangeEndsAt: range == null
              ? null
              : finished
                  ? (range.isAfter(newEnd) ? range : newEnd)
                  : range.add(extra),
        );
        return _withTimer(s, extended, _schedule(extended));

      case TimerShortened(:final at, :final timerId, :final seconds):
        final t = s.timers[timerId];
        if (t == null || !t.isActive || seconds <= 0) return ReduceResult(s);
        final less = Duration(seconds: seconds);
        if (t.status == TimerStatus.paused) {
          final left = t.pausedRemaining! - less;
          final pausedLeft = left.isNegative ? Duration.zero : left;
          final rangeLeft = t.pausedRangeRemaining == null ? null : t.pausedRangeRemaining! - less;
          return _withTimer(
            s,
            t.copyWith(
              totalSeconds: math.max(1, t.totalSeconds - seconds),
              pausedRemaining: pausedLeft,
              pausedRangeRemaining: rangeLeft == null || rangeLeft < pausedLeft ? null : rangeLeft,
            ),
          );
        }
        if (t.isFinished(at)) return ReduceResult(s);
        final candidate = t.endsAt!.subtract(less);
        final newEnd = candidate.isBefore(at) ? at : candidate;
        final range = t.rangeEndsAt?.subtract(less);
        final shortened = t.copyWith(
          totalSeconds: math.max(1, t.totalSeconds - seconds),
          endsAt: newEnd,
          rangeEndsAt: range == null || !range.isAfter(newEnd) ? newEnd : range,
        );
        return _withTimer(s, shortened, _schedule(shortened));

      case TimerRechecked(:final at, :final timerId):
        final t = s.timers[timerId];
        if (t == null || !t.isFinished(at)) return ReduceResult(s);
        final planTimer = plan.timersById[timerId];
        var next = at.add(Duration(seconds: planTimer?.recheckSeconds ?? defaultRecheckSeconds));
        final range = t.rangeEndsAt;
        if (range != null && range.isAfter(at) && range.isBefore(next)) next = range;
        final rechecked = t.copyWith(
          totalSeconds: t.totalSeconds + next.difference(t.endsAt!).inSeconds,
          endsAt: next,
          rechecked: true,
        );
        return _withTimer(s, rechecked, _schedule(rechecked));

      case TimerDismissed(:final timerId):
        final t = s.timers[timerId];
        if (t == null || !t.isActive) return ReduceResult(s);
        return _withTimer(
          s,
          t.copyWith(status: TimerStatus.dismissed),
          CancelTimerNotification(timerId),
        );
    }
  }

  /// Used when the plan gives no `recheck_seconds`.
  static const defaultRecheckSeconds = 300;

  static TimerState _start(
    PlanTimer t,
    DateTime at, {
    String? stepId,
    String? prepTaskId,
  }) =>
      TimerState(
        timerId: t.id,
        labelHe: t.labelHe,
        provenance: t.provenance,
        totalSeconds: t.seconds,
        status: TimerStatus.running,
        endsAt: at.add(Duration(seconds: t.seconds)),
        rangeEndsAt: t.maxSeconds == null ? null : at.add(Duration(seconds: t.maxSeconds!)),
        stepId: stepId,
        prepTaskId: prepTaskId,
      );

  static ScheduleTimerNotification _schedule(TimerState t) =>
      ScheduleTimerNotification(t.timerId, t.endsAt!, t.labelHe);

  static ReduceResult _withTimer(
    CookingState s,
    TimerState t, [
    EngineEffect? effect,
  ]) =>
      ReduceResult(
        s.copyWith(timers: {...s.timers, t.timerId: t}),
        [?effect],
      );

  static Set<String> _withProposal(Set<String> ids, String? proposalId) =>
      proposalId == null ? ids : {...ids, proposalId};
}
