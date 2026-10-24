import 'package:flutter/widgets.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cooking_plan.dart';
import '../../models/recipe.dart';
import '../cooking/engine/action_dispatcher.dart';
import '../cooking/engine/cooking_engine.dart';
import 'assistant_models.dart';
import 'command_parser.dart';

/// What the assistant may do to a cooking session — exactly the dispatcher's operations
/// (implemented by the cooking controller in the app, by the dispatcher in tests).
abstract interface class CookingActions {
  CookingState get state;
  DateTime now();
  Future<DispatchResult> completeStep(String stepId);
  Future<DispatchResult> confirmAction(String stepId, String actionId);
  Future<DispatchResult> completePrepTask(String id);
  Future<DispatchResult> undoLast();
  Future<DispatchResult> extendTimer(String id, {int seconds});
  Future<DispatchResult> pauseTimer(String id);
  Future<DispatchResult> resumeTimer(String id);
  Future<DispatchResult> applyPlanPatch(List<Map<String, dynamic>> ops, {required String summaryHe});
}

class ChatTurn {
  const ChatTurn({required this.fromUser, required this.textHe});
  final bool fromUser;
  final String textHe;
}

/// Remy's brain (Phase 3B): local commands first, Remy (the server) for real questions,
/// and execution only through [CookingActions] after deterministic validation.
///
/// Confirmation policy (fixed here, never decided by the model):
/// - run at once: clear "next" on an ordinary step, "חזרה", a clearly reported real-world
///   action that matches an available action ("הכנסתי את העוגה לתנור"), pause/resume, and
///   extensions up to 15 minutes;
/// - ask first: steps that need the high-risk doneness check, finishing while a timer still
///   runs, "next" when the step waits for a real-world start, partial matches, extensions over
///   15 minutes, and every proposal from Remy.
class AssistantService {
  AssistantService(this.api);

  final ApiClient api;

  static const autoExtendLimitSeconds = 15 * 60;
  static const maxExtendSeconds = 3600;

  AppLocalizations get _l10n => lookupAppLocalizations(const Locale('he'));

  /// Turns the cook's words (typed or spoken) into a reply and maybe an action. Local
  /// understanding first; Remy (one server call, no retries) only for what it can't
  /// resolve confidently.
  Future<AssistantReply> interpret(
    AssistantInput input, {
    required CookingState state,
    required Recipe recipe,
    required DateTime now,
    List<ChatTurn> history = const [],
  }) async {
    if (!_intelligible(input.text)) return AssistantReply(answerHe: _l10n.remyDidntCatch);
    final local = interpretLocally(input, state: state, recipe: recipe, now: now);
    if (local != null) return local;
    return _askRemy(input, state: state, recipe: recipe, now: now, history: history);
  }

  /// Noise from speech recognition ("…", a stray letter) never goes to the server.
  static bool _intelligible(String text) =>
      RegExp(r'[\p{L}\p{N}]{2,}', unicode: true).hasMatch(normalizeCommand(text));

  /// The deterministic part: commands and simple questions, resolved against the live
  /// state and the saved recipe. Null when the message needs Remy.
  AssistantReply? interpretLocally(
    AssistantInput input, {
    required CookingState state,
    required DateTime now,
    Recipe? recipe,
  }) {
    final cmd = parseCommand(input.text);
    if (cmd == null) return null;
    final reply = _resolve(cmd, state: state, now: now, recipe: recipe);
    if (reply == null || reply.action == null || reply.requiresConfirmation || !cmd.needsConfirmation) return reply;
    // Unsure words or a near match: ask before acting.
    return AssistantReply(answerHe: _confirmText(reply.action!, state, now), action: reply.action, requiresConfirmation: true);
  }

  AssistantReply? _resolve(ParsedCommand cmd, {required CookingState state, required DateTime now, Recipe? recipe}) {
    final l10n = _l10n;
    final focus = state.focusStep(now);
    switch (cmd.kind) {
      case CommandKind.next:
        if (state.isComplete) return AssistantReply(answerHe: l10n.remyAllDone);
        if (focus == null) return AssistantReply(answerHe: l10n.remyNotPossible);
        return _finishStep(focus, state, now);
      case CommandKind.back:
        if (state.log.isEmpty) return AssistantReply(answerHe: l10n.remyNothingToUndo);
        return AssistantReply(answerHe: l10n.remyUndone, action: const UndoLastAction());
      case CommandKind.timeLeft:
        return AssistantReply(answerHe: _timersText(state, now));
      case CommandKind.whatNow:
        return AssistantReply(answerHe: _nowText(state, now));
      case CommandKind.nextStepPreview:
        return AssistantReply(answerHe: _nextText(state, now));
      case CommandKind.help:
        return AssistantReply(answerHe: _helpText(state, now));
      case CommandKind.stepsLeft:
        final left = state.plan.steps.where((s) => !state.isStepDone(s)).length;
        return AssistantReply(answerHe: left == 0 ? l10n.remyAllDone : l10n.remyStepsLeft(left, state.plan.steps.length));
      case CommandKind.temperature:
        final step = focus ?? state.plan.steps.last;
        final withTemp = step.temperature != null
            ? step
            : state.plan.steps.where((s) => !state.isStepDone(s) && s.temperature != null).firstOrNull;
        return AssistantReply(
          answerHe: withTemp == null ? l10n.remyNoTemperature : l10n.remyTemperature(withTemp.title, withTemp.temperature!.value),
        );
      case CommandKind.stepIngredients:
        if (focus == null || recipe == null) return AssistantReply(answerHe: l10n.remyNoStepIngredients);
        final names = {for (final i in recipe.ingredients) i.id: i};
        final items = [
          for (final u in focus.ingredientUses)
            if (names[u.ingredientId] case final i?) u.quantity == null ? i.name : '${i.name} ${u.quantity!.display}',
          if (focus.ingredientUses.isEmpty)
            for (final id in focus.ingredientIds) ?names[id]?.name,
        ];
        return AssistantReply(answerHe: items.isEmpty ? l10n.remyNoStepIngredients : l10n.remyStepIngredients(items.join(', ')));
      case CommandKind.ingredientAmount:
        if (recipe == null) return null;
        final wanted = stemsOf(cmd.subject ?? '').toSet();
        final hits = [for (final i in recipe.ingredients) if (!i.omitted && stemsOf(i.name).any(wanted.contains)) i];
        if (hits.isEmpty) return null; // not an ingredient here: Remy may know what was meant
        return AssistantReply(
          answerHe: [for (final i in hits) l10n.remyIngredientAmount(i.name, i.quantity?.display ?? '—')].join(' '),
        );
      case CommandKind.pauseTimer || CommandKind.resumeTimer:
        final pause = cmd.kind == CommandKind.pauseTimer;
        final candidates = [
          for (final t in state.activeTimers(now))
            if (pause ? t.status == TimerStatus.running && !t.isFinished(now) : t.status == TimerStatus.paused) t,
        ];
        final timer = _pickTimer(candidates, cmd.normalized);
        if (candidates.isEmpty) return AssistantReply(answerHe: l10n.remyNoTimers);
        if (timer == null) return AssistantReply(answerHe: l10n.remyWhichTimer(candidates.map((t) => t.labelHe).join(', ')));
        return AssistantReply(
          answerHe: pause ? l10n.remyPausedDone(timer.labelHe) : l10n.remyResumedDone(timer.labelHe),
          action: pause ? PauseTimerAction(timer.timerId) : ResumeTimerAction(timer.timerId),
        );
      case CommandKind.extendTimer:
        final candidates = state.activeTimers(now);
        if (candidates.isEmpty) return AssistantReply(answerHe: l10n.remyNoTimers);
        final timer = _pickTimer(candidates, cmd.normalized);
        if (timer == null) return AssistantReply(answerHe: l10n.remyWhichTimer(candidates.map((t) => t.labelHe).join(', ')));
        // "עוד קצת": the plan's own re-check time, asked first.
        final seconds = cmd.seconds ?? state.plan.timersById[timer.timerId]?.recheckSeconds ?? CookingEngine.defaultRecheckSeconds;
        if (seconds > maxExtendSeconds) return AssistantReply(answerHe: l10n.remyTooLong);
        return AssistantReply(
          answerHe: l10n.remyConfirmExtend(durationWords(Duration(seconds: seconds)), timer.labelHe),
          action: ExtendTimerAction(timer.timerId, seconds),
          requiresConfirmation: seconds > autoExtendLimitSeconds,
        );
      case CommandKind.reportedAction:
        return _reported(cmd, state, now);
    }
  }

  String _nowText(CookingState state, DateTime now) {
    final focus = state.focusStep(now);
    if (state.isComplete) return _l10n.remyAllDone;
    if (focus == null) return _l10n.remyNotPossible;
    return _l10n.remyNow(focus.title, focus.instructionHe);
  }

  String _nextText(CookingState state, DateTime now) {
    final focus = state.focusStep(now);
    final later = [for (final s in state.plan.steps) if (!state.isStepDone(s) && s.id != focus?.id) s];
    return later.isEmpty ? _l10n.remyLastStep : _l10n.remyNextPreview(later.first.title);
  }

  String _helpText(CookingState state, DateTime now) {
    final focus = state.focusStep(now);
    if (focus == null) return _l10n.remyAllDone;
    final help = [?focus.helpHe, ?focus.donenessCueHe].join(' ');
    return help.isEmpty ? focus.instructionHe : help;
  }

  /// Wording for actions that need a "yes" first.
  String _confirmText(AssistantAction action, CookingState state, DateTime now) {
    final l10n = _l10n;
    String timerLabel(String id) => state.timers[id]?.labelHe ?? '';
    return switch (action) {
      CompleteStepAction(:final stepId) => l10n.remyConfirmNext(state.plan.stepById(stepId)?.title ?? ''),
      ConfirmStepAction(:final stepId, :final actionId) => () {
          final step = state.plan.stepById(stepId);
          final a = step?.actionById(actionId);
          final t = a?.startsTimer == null ? null : state.plan.timersById[a!.startsTimer];
          return t == null
              ? l10n.remyConfirmAction(a?.labelHe ?? '')
              : l10n.remyConfirmActionTimer(a!.labelHe, durationWords(Duration(seconds: t.seconds)));
        }(),
      CompletePrepAction(:final prepTaskId) => l10n.remyConfirmAction(state.plan.prepTaskById(prepTaskId)?.textHe ?? ''),
      UndoLastAction() => l10n.remyConfirmUndo,
      ExtendTimerAction(:final timerId, :final seconds) =>
        l10n.remyConfirmExtend(durationWords(Duration(seconds: seconds)), timerLabel(timerId)),
      PauseTimerAction(:final timerId) => l10n.remyConfirmPause(timerLabel(timerId)),
      ResumeTimerAction(:final timerId) => l10n.remyConfirmResume(timerLabel(timerId)),
      PatchPlanAction(:final summaryHe) => summaryHe,
    };
  }

  /// "next" on the current step, following the step's main action.
  AssistantReply _finishStep(PlanStep step, CookingState state, DateTime now) {
    final l10n = _l10n;
    final p = state.primaryFor(step, now);
    if (p == null) return AssistantReply(answerHe: l10n.remyNotPossible);
    switch (p.kind) {
      case PrimaryKind.startTimer:
        // "Next" doesn't say the real-world wait began: ask before starting the timer.
        final a = p.action!;
        return AssistantReply(
          answerHe: l10n.remyStartFirst(a.action.labelHe),
          action: ConfirmStepAction(step.id, a.action.id),
          requiresConfirmation: true,
        );
      case PrimaryKind.waiting:
        return AssistantReply(
          answerHe: l10n.remyFinishEarly(p.timer!.labelHe, durationWords(p.timer!.remaining(now))),
          action: CompleteStepAction(step.id),
          requiresConfirmation: true,
        );
      case PrimaryKind.checkDue || PrimaryKind.next:
        if (p.needsSafetyCheck) {
          final cue = step.donenessCueHe ?? step.warningsHe.firstOrNull ?? '';
          return AssistantReply(
            answerHe: l10n.remySafetyCheck(cue),
            action: CompleteStepAction(step.id),
            requiresConfirmation: true,
          );
        }
        return AssistantReply(answerHe: l10n.remyStepDone(step.title), action: CompleteStepAction(step.id));
    }
  }

  /// "הכנסתי את העוגה לתנור": match the report against the actions and prep tasks
  /// available right now. Only a clear match runs at once; intentions never confirm.
  AssistantReply? _reported(ParsedCommand cmd, CookingState state, DateTime now) {
    final l10n = _l10n;
    final said = stemsOf(cmd.normalized).toSet();
    ({String label, AssistantAction action, int matched, bool strong, AvailableAction? available})? best;
    void consider(String label, AssistantAction action, AvailableAction? available) {
      final keys = stemsOf(label).take(2).toList();
      if (keys.isEmpty) return;
      final matched = keys.where(said.contains).length;
      if (matched == 0) return;
      final strong = matched == keys.length;
      if (best == null || matched > best!.matched || (strong && !best!.strong)) {
        best = (label: label, action: action, matched: matched, strong: strong, available: available);
      }
    }

    for (final a in state.availableActions(now)) {
      final action = a.action.completesStep && a.action.startsTimer == null
          ? CompleteStepAction(a.step.id) as AssistantAction
          : ConfirmStepAction(a.step.id, a.action.id);
      consider(a.action.labelHe, action, a);
    }
    for (final p in state.pendingPrepTasks()) {
      consider(p.textHe, CompletePrepAction(p.id), null);
    }
    final b = best;
    if (cmd.intention) {
      final timerAction = b?.available?.action.startsTimer != null ? b!.label : null;
      return AssistantReply(answerHe: timerAction == null ? l10n.remyTellMeWhenGeneric : l10n.remyTellMeWhen(timerAction));
    }
    if (b == null) return null; // not something on the plan right now: ask Remy
    final available = b.available;
    final timer = available?.timer;
    var confirm = !b.strong;
    if (b.action is CompleteStepAction && available != null) {
      final p = state.primaryFor(available.step, now);
      if (p != null && (p.needsSafetyCheck || p.kind == PrimaryKind.waiting)) confirm = true;
    }
    final text = timer != null
        ? l10n.remyConfirmActionTimer(b.label, durationWords(Duration(seconds: timer.seconds)))
        : l10n.remyConfirmAction(b.label);
    return AssistantReply(answerHe: text, action: b.action, requiresConfirmation: confirm);
  }

  TimerState? _pickTimer(List<TimerState> timers, String said) {
    if (timers.length == 1) return timers.single;
    final words = stemsOf(said).toSet();
    final named = [for (final t in timers) if (stemsOf(t.labelHe).any(words.contains)) t];
    return named.length == 1 ? named.single : null;
  }

  String _timersText(CookingState state, DateTime now) {
    final l10n = _l10n;
    final timers = state.activeTimers(now);
    if (timers.isEmpty) return l10n.remyNoTimers;
    return [
      for (final t in timers)
        t.isFinished(now)
            ? l10n.remyTimerDue(t.labelHe)
            : t.status == TimerStatus.paused
                ? l10n.remyTimerPausedLeft(t.labelHe, durationWords(t.remaining(now)))
                : l10n.remyTimerLeft(t.labelHe, durationWords(t.remaining(now))),
    ].join('\n');
  }

  Future<AssistantReply> _askRemy(
    AssistantInput input, {
    required CookingState state,
    required Recipe recipe,
    required DateTime now,
    required List<ChatTurn> history,
  }) async {
    final l10n = _l10n;
    final AssistantTurnResult res;
    try {
      res = await api.assistantTurn(
        messageHe: input.text.trim(),
        modality: input.modality.name,
        recipe: recipe,
        plan: state.plan,
        snapshot: state.snapshot(now),
        history: [
          for (final t in history.length > 6 ? history.sublist(history.length - 6) : history)
            {'role': t.fromUser ? 'user' : 'assistant', 'text': t.textHe.length > 600 ? t.textHe.substring(0, 600) : t.textHe},
        ],
      );
    } on ApiFailure catch (e) {
      final text = e.code == 'offline' || e.code == 'timeout' ? l10n.remyOffline : l10n.remyUnavailable;
      return AssistantReply(answerHe: text, source: ReplySource.ai);
    }
    if (res.command case final c?) {
      final mapped = _fromCommand(c, state, now);
      if (mapped != null) return mapped;
    }
    final p = res.proposal;
    AssistantAction? action;
    var answer = res.answerHe;
    if (p != null && p.kind == 'extend_timer' && p.timerId != null && p.seconds != null) {
      if (state.timers[p.timerId]?.isActive ?? false) action = ExtendTimerAction(p.timerId!, p.seconds!);
    } else if (p != null && p.kind == 'patch' && p.ops.isNotEmpty) {
      if (patchProblem(state, p.ops) == null) {
        action = PatchPlanAction(p.ops, p.summaryHe);
      } else {
        answer = '$answer\n${l10n.remyChangeNotPossible}';
      }
    }
    return AssistantReply(
      answerHe: answer,
      speechHe: answer == res.answerHe ? res.speechHe : speakable(answer),
      action: action,
      requiresConfirmation: action != null, // every AI proposal is approved by the cook
      source: ReplySource.ai,
    );
  }

  /// A command interpreted by Remy, validated against the live state like a local one.
  /// Info commands are answered from local data; anything that records a real-world fact
  /// (finishing a step, starting a timer) or undoes one always asks first; unsure or
  /// low-confidence interpretations ask first. Invalid commands are dropped (null).
  AssistantReply? _fromCommand(AssistantCommandData c, CookingState state, DateTime now) {
    final unsure = c.lowConfidence || c.userUncertain;
    AssistantReply ask(AssistantAction a) =>
        AssistantReply(answerHe: _confirmText(a, state, now), action: a, requiresConfirmation: true, source: ReplySource.ai);
    switch (c.action) {
      case 'get_timer_status':
        return AssistantReply(answerHe: _timersText(state, now), source: ReplySource.ai);
      case 'whats_next':
        return AssistantReply(answerHe: _nowText(state, now), source: ReplySource.ai);
      case 'help':
        return AssistantReply(answerHe: _helpText(state, now), source: ReplySource.ai);
      case 'undo':
        return state.log.isEmpty ? AssistantReply(answerHe: _l10n.remyNothingToUndo, source: ReplySource.ai) : ask(const UndoLastAction());
      case 'complete_step':
        final focus = state.focusStep(now);
        if (focus == null || c.stepId != focus.id) return null;
        final p = state.primaryFor(focus, now);
        if (p == null) return null;
        if (p.kind == PrimaryKind.startTimer) return ask(ConfirmStepAction(focus.id, p.action!.action.id));
        return ask(CompleteStepAction(focus.id));
      case 'start_timer_action':
        final available = state.availableActions(now).where((a) => a.step.id == c.stepId && a.action.id == c.actionId).firstOrNull;
        if (available == null || available.action.startsTimer == null) return null;
        return ask(ConfirmStepAction(available.step.id, available.action.id));
      case 'extend_timer':
        final t = state.timers[c.timerId];
        final seconds = c.seconds;
        if (t == null || !t.isActive || seconds == null || seconds <= 0 || seconds > maxExtendSeconds) return null;
        final a = ExtendTimerAction(t.timerId, seconds);
        if (unsure || seconds > autoExtendLimitSeconds) return ask(a);
        return AssistantReply(answerHe: _confirmText(a, state, now), action: a, source: ReplySource.ai);
      case 'pause_timer' || 'resume_timer':
        final pause = c.action == 'pause_timer';
        final candidates = [
          for (final t in state.activeTimers(now))
            if (pause ? t.status == TimerStatus.running && !t.isFinished(now) : t.status == TimerStatus.paused) t,
        ];
        final t = c.timerId == null
            ? (candidates.length == 1 ? candidates.single : null)
            : candidates.where((x) => x.timerId == c.timerId).firstOrNull;
        if (t == null) return null;
        final a = pause ? PauseTimerAction(t.timerId) as AssistantAction : ResumeTimerAction(t.timerId);
        return unsure ? ask(a) : AssistantReply(answerHe: _confirmText(a, state, now), action: a, source: ReplySource.ai);
    }
    return null; // unknown or unsupported: never executed
  }

  /// Executes an approved (or automatic) action and describes the engine's result.
  Future<AssistantReply> execute(AssistantAction action, CookingActions cooking) async {
    final l10n = _l10n;
    final before = cooking.state;
    String describe(DispatchResult r, String Function() applied) => switch (r.status) {
          DispatchStatus.applied => applied(),
          DispatchStatus.alreadyDone => l10n.remyAlreadyDone,
          DispatchStatus.invalid => r.reason == 'dependent_started'
              ? l10n.undoNotAllowed
              : r.reason == 'step_started' || r.reason == 'timer_started'
                  ? l10n.remyChangeNotPossible
                  : l10n.remyNotPossible,
        };
    String startedOr(DispatchResult r, String label) {
      final t = r.startedTimer;
      return t == null ? l10n.remyMarked(label) : l10n.remyTimerStarted(t.labelHe, durationWords(Duration(seconds: t.totalSeconds)));
    }

    final String text;
    switch (action) {
      case CompleteStepAction(:final stepId):
        final step = before.plan.stepById(stepId);
        final r = await cooking.completeStep(stepId);
        text = describe(r, () {
          final after = cooking.state;
          final next = after.focusStep(cooking.now());
          return [
            l10n.remyStepDone(step?.title ?? ''),
            if (after.isComplete) l10n.remyAllDone else if (next != null) l10n.remyNextStep(next.title),
          ].join(' ');
        });
      case ConfirmStepAction(:final stepId, :final actionId):
        final label = before.plan.stepById(stepId)?.actionById(actionId)?.labelHe ?? '';
        final r = await cooking.confirmAction(stepId, actionId);
        text = describe(r, () => startedOr(r, label));
      case CompletePrepAction(:final prepTaskId):
        final label = before.plan.prepTaskById(prepTaskId)?.textHe ?? '';
        final r = await cooking.completePrepTask(prepTaskId);
        text = describe(r, () => startedOr(r, label));
      case UndoLastAction():
        text = describe(await cooking.undoLast(), () => l10n.remyUndone);
      case ExtendTimerAction(:final timerId, :final seconds):
        final r = await cooking.extendTimer(timerId, seconds: seconds);
        text = describe(r, () {
          final t = cooking.state.timers[timerId];
          return l10n.remyExtended(
            durationWords(Duration(seconds: seconds)),
            t?.labelHe ?? '',
            durationWords(t?.remaining(cooking.now()) ?? Duration.zero),
          );
        });
      case PauseTimerAction(:final timerId):
        final label = before.timers[timerId]?.labelHe ?? '';
        text = describe(await cooking.pauseTimer(timerId), () => l10n.remyPausedDone(label));
      case ResumeTimerAction(:final timerId):
        final label = before.timers[timerId]?.labelHe ?? '';
        text = describe(await cooking.resumeTimer(timerId), () => l10n.remyResumedDone(label));
      case PatchPlanAction(:final ops, :final summaryHe):
        text = describe(await cooking.applyPlanPatch(ops, summaryHe: summaryHe), () => l10n.remyPatched(summaryHe));
    }
    return AssistantReply(answerHe: text, speechHe: speakable(text));
  }
}

/// "12 דקות ו-30 שניות", "שעה ו-5 דקות", "דקה" — readable on screen and by text-to-speech.
String durationWords(Duration d) {
  final l10n = lookupAppLocalizations(const Locale('he'));
  final total = d.inSeconds < 0 ? 0 : d.inSeconds;
  final h = total ~/ 3600, m = (total % 3600) ~/ 60, s = total % 60;
  String minutes(int n) => n == 1 ? l10n.durMinute : l10n.durMinutes(n);
  if (h > 0) {
    final hours = h == 1 ? l10n.durHour : l10n.durHours(h);
    return m == 0 ? hours : l10n.durAnd(hours, minutes(m));
  }
  if (m == 0) return l10n.durSeconds(s);
  return s == 0 || m >= 5 ? minutes(m) : l10n.durAnd(minutes(m), l10n.durSeconds(s));
}
