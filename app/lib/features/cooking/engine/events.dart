/// Append-only cooking events. A session's state is `replay(plan, events)`.
library;

enum ActionSource { ui, agent }

sealed class CookingEvent {
  const CookingEvent(this.at);

  /// When the event happened (UTC, whole seconds).
  final DateTime at;

  String get type;
  Map<String, Object?> toPayload();

  static const payloadSchemaVersion = 1;

  static CookingEvent decode(String type, Map<String, dynamic> p, DateTime at) {
    final utc = at.toUtc();
    return switch (type) {
      'SessionStarted' => SessionStarted(utc),
      'ActionConfirmed' => ActionConfirmed(
          at: utc,
          stepId: p['step_id'] as String,
          actionId: p['action_id'] as String,
          source: ActionSource.values.byName(p['source'] as String),
          proposalId: p['proposal_id'] as String?,
        ),
      'PrepTaskDone' => PrepTaskDone(
          at: utc,
          prepTaskId: p['prep_task_id'] as String,
          source: ActionSource.values.byName(p['source'] as String),
          proposalId: p['proposal_id'] as String?,
        ),
      'PrepTaskUndone' =>
        PrepTaskUndone(at: utc, prepTaskId: p['prep_task_id'] as String),
      'StepUndone' => StepUndone(at: utc, stepId: p['step_id'] as String),
      'TimerPaused' => TimerPaused(at: utc, timerId: p['timer_id'] as String),
      'TimerResumed' => TimerResumed(at: utc, timerId: p['timer_id'] as String),
      'TimerExtended' => TimerExtended(
          at: utc,
          timerId: p['timer_id'] as String,
          seconds: p['seconds'] as int,
        ),
      'TimerDismissed' =>
        TimerDismissed(at: utc, timerId: p['timer_id'] as String),
      _ => throw FormatException('Unknown cooking event type: $type'),
    };
  }
}

class SessionStarted extends CookingEvent {
  const SessionStarted(super.at);
  @override
  String get type => 'SessionStarted';
  @override
  Map<String, Object?> toPayload() => {};
}

class ActionConfirmed extends CookingEvent {
  const ActionConfirmed({
    required DateTime at,
    required this.stepId,
    required this.actionId,
    required this.source,
    this.proposalId,
  }) : super(at);

  final String stepId;
  final String actionId;
  final ActionSource source;
  final String? proposalId;

  @override
  String get type => 'ActionConfirmed';
  @override
  Map<String, Object?> toPayload() => {
        'step_id': stepId,
        'action_id': actionId,
        'source': source.name,
        if (proposalId != null) 'proposal_id': proposalId,
      };
}

class PrepTaskDone extends CookingEvent {
  const PrepTaskDone({
    required DateTime at,
    required this.prepTaskId,
    required this.source,
    this.proposalId,
  }) : super(at);

  final String prepTaskId;
  final ActionSource source;
  final String? proposalId;

  @override
  String get type => 'PrepTaskDone';
  @override
  Map<String, Object?> toPayload() => {
        'prep_task_id': prepTaskId,
        'source': source.name,
        if (proposalId != null) 'proposal_id': proposalId,
      };
}

class PrepTaskUndone extends CookingEvent {
  const PrepTaskUndone({required DateTime at, required this.prepTaskId})
      : super(at);
  final String prepTaskId;
  @override
  String get type => 'PrepTaskUndone';
  @override
  Map<String, Object?> toPayload() => {'prep_task_id': prepTaskId};
}

/// Undoes the most recent confirmed action of a step.
class StepUndone extends CookingEvent {
  const StepUndone({required DateTime at, required this.stepId}) : super(at);
  final String stepId;
  @override
  String get type => 'StepUndone';
  @override
  Map<String, Object?> toPayload() => {'step_id': stepId};
}

class TimerPaused extends CookingEvent {
  const TimerPaused({required DateTime at, required this.timerId}) : super(at);
  final String timerId;
  @override
  String get type => 'TimerPaused';
  @override
  Map<String, Object?> toPayload() => {'timer_id': timerId};
}

class TimerResumed extends CookingEvent {
  const TimerResumed({required DateTime at, required this.timerId}) : super(at);
  final String timerId;
  @override
  String get type => 'TimerResumed';
  @override
  Map<String, Object?> toPayload() => {'timer_id': timerId};
}

class TimerExtended extends CookingEvent {
  const TimerExtended({
    required DateTime at,
    required this.timerId,
    required this.seconds,
  }) : super(at);
  final String timerId;
  final int seconds;
  @override
  String get type => 'TimerExtended';
  @override
  Map<String, Object?> toPayload() => {'timer_id': timerId, 'seconds': seconds};
}

class TimerDismissed extends CookingEvent {
  const TimerDismissed({required DateTime at, required this.timerId})
      : super(at);
  final String timerId;
  @override
  String get type => 'TimerDismissed';
  @override
  Map<String, Object?> toPayload() => {'timer_id': timerId};
}
