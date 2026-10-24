/// Remy's input and output, independent of how the cook spoke to him (Phase 3B).
///
/// Typed text now and speech recognition later (Phase 3D) both become an
/// [AssistantInput]; every [AssistantReply] carries [AssistantReply.speechHe] for
/// text-to-speech. Actions are executed only by the app's deterministic engine.
library;

enum InputModality { text, voice }

class AssistantInput {
  const AssistantInput(this.text, {this.modality = InputModality.text});
  final String text;
  final InputModality modality;
}

/// Something the app can do for the cook, always through the ActionDispatcher.
sealed class AssistantAction {
  const AssistantAction();
}

/// Finish a step ("סיימתי — לשלב הבא").
class CompleteStepAction extends AssistantAction {
  const CompleteStepAction(this.stepId);
  final String stepId;
}

/// Confirm one specific action of a step: one that starts a timer ("הכנסתי לתנור").
class ConfirmStepAction extends AssistantAction {
  const ConfirmStepAction(this.stepId, this.actionId);
  final String stepId;
  final String actionId;
}

/// A prep task the cook reported done ("הדלקתי את התנור"); may start its timer.
class CompletePrepAction extends AssistantAction {
  const CompletePrepAction(this.prepTaskId);
  final String prepTaskId;
}

/// "חזרה": undo the last tap.
class UndoLastAction extends AssistantAction {
  const UndoLastAction();
}

class ExtendTimerAction extends AssistantAction {
  const ExtendTimerAction(this.timerId, this.seconds);
  final String timerId;
  final int seconds;
}

class PauseTimerAction extends AssistantAction {
  const PauseTimerAction(this.timerId);
  final String timerId;
}

class ResumeTimerAction extends AssistantAction {
  const ResumeTimerAction(this.timerId);
  final String timerId;
}

/// A change to steps not started yet (a substitution or a step change from Remy).
class PatchPlanAction extends AssistantAction {
  const PatchPlanAction(this.ops, this.summaryHe);
  final List<Map<String, dynamic>> ops;
  final String summaryHe;
}

enum ReplySource { local, ai }

class AssistantReply {
  const AssistantReply({
    required this.answerHe,
    String? speechHe,
    this.action,
    this.requiresConfirmation = false,
    this.source = ReplySource.local,
  }) : speechHe = speechHe ?? answerHe;

  /// What Remy says on screen.
  final String answerHe;

  /// The same as plain text for text-to-speech (no emoji or symbols).
  final String speechHe;

  /// What to do, if anything. Executed at once unless [requiresConfirmation].
  final AssistantAction? action;
  final bool requiresConfirmation;
  final ReplySource source;
}

/// Plain text for text-to-speech: no emoji or symbols.
String speakable(String text) => text
    .replaceAll(RegExp(r'[^\p{L}\p{N}\s.,:;!?"()\-–—%°/]', unicode: true), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
