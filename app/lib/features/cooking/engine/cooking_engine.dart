/// Deterministic cooking engine: pure Dart, no Flutter, no I/O.
///
/// State is rebuilt by replaying the session's events over the approved plan.
/// Timer durations always come from the plan; callers never pass durations
/// except an explicit user "+1 minute" extension.
library;

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
    this.stepId,
    this.prepTaskId,
  });

  final String timerId;
  final String labelHe;
  final Provenance provenance;

  /// Plan duration plus any user extensions.
  final int totalSeconds;
  final TimerStatus status;
  final DateTime? endsAt;
  final Duration? pausedRemaining;

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
  }) =>
      TimerState(
        timerId: timerId,
        labelHe: labelHe,
        provenance: provenance,
        totalSeconds: totalSeconds ?? this.totalSeconds,
        status: status ?? this.status,
        endsAt: endsAt ?? this.endsAt,
        pausedRemaining: pausedRemaining ?? this.pausedRemaining,
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

  /// The step that needs this task is already unlocked.
  final bool urgent;
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

  /// Steps that can be done while the focus step waits on a timer.
  List<PlanStep> meanwhile(DateTime now) {
    final focus = focusStep(now);
    if (focus == null || statusOf(focus, now) != StepStatus.waitingTimer) {
      return const [];
    }
    return [
      for (final step in plan.steps)
        if (step.id != focus.id &&
            step.parallelOk &&
            statusOf(step, now) != StepStatus.done &&
            statusOf(step, now) != StepStatus.locked)
          step,
    ];
  }

  List<PrepTask> pendingPrepTasks() =>
      [for (final p in plan.prepTasks) if (!prepDone.contains(p.id)) p];

  /// Prep tasks to show now: not done and their surface condition is met.
  List<PrepTaskView> prepTasksToShow(DateTime now) {
    bool unlocked(String? stepId) {
      final step = stepId == null ? null : plan.stepById(stepId);
      return step != null && statusOf(step, now) != StepStatus.locked;
    }

    return [
      for (final p in pendingPrepTasks())
        if (p.surface.atStart || unlocked(p.surface.withStep))
          PrepTaskView(p, urgent: unlocked(p.neededByStep)),
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
            'status': t.isFinished(now) ? 'finished' : t.status.name,
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
        return _withTimer(
          s,
          t.copyWith(status: TimerStatus.paused, pausedRemaining: t.remaining(at)),
          CancelTimerNotification(timerId),
        );

      case TimerResumed(:final at, :final timerId):
        final t = s.timers[timerId];
        if (t == null || t.status != TimerStatus.paused) return ReduceResult(s);
        final resumed = t.copyWith(
          status: TimerStatus.running,
          endsAt: at.add(t.pausedRemaining!),
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
            ),
          );
        }
        final base = t.isFinished(at) ? at : t.endsAt!;
        final extended = t.copyWith(
          totalSeconds: t.totalSeconds + seconds,
          endsAt: base.add(extra),
        );
        return _withTimer(s, extended, _schedule(extended));

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
