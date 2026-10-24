import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/clock.dart';
import '../../core/format.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cooking_plan.dart';
import 'cooking_controller.dart';
import 'engine/cooking_engine.dart';

/// The cooking screen: the current step big and clear, with one main button
/// (docs/DECISIONS.md #35, #36). Timers, prep tasks and parallel steps stay
/// available but compact; technical details are not shown.
class CookingScreen extends ConsumerWidget {
  const CookingScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(cookingControllerProvider(sessionId));
    // Rebuild every second for live countdowns.
    final now = ref.watch(tickerProvider).value ?? ref.read(clockProvider)();

    return switch (view) {
      AsyncData(:final value) => _CookingBody(sessionId: sessionId, view: value, now: now.toUtc()),
      AsyncError() => AppScaffold(title: l10n.continueCooking, body: Center(child: Text(l10n.errorGeneric))),
      _ => AppScaffold(title: l10n.continueCooking, body: const Center(child: CircularProgressIndicator())),
    };
  }
}

class _CookingBody extends ConsumerStatefulWidget {
  const _CookingBody({required this.sessionId, required this.view, required this.now});

  final String sessionId;
  final CookingView view;
  final DateTime now;

  @override
  ConsumerState<_CookingBody> createState() => _CookingBodyState();
}

class _CookingBodyState extends ConsumerState<_CookingBody> {
  /// Steps whose high-risk doneness check the cook ticked ("בדקתי…").
  final _safetyChecked = <String>{};
  final _helpOpen = <String>{};

  CookingController get _controller => ref.read(cookingControllerProvider(widget.sessionId).notifier);
  CookingState get _state => widget.view.state;
  DateTime get _now => widget.now;

  /// Minutes "צריך עוד זמן" adds: the plan's re-check interval, but never past the
  /// end of the recipe's time range (matches the engine's `TimerRechecked`).
  int _moreMinutes(TimerState t) {
    var seconds = _state.plan.timersById[t.timerId]?.recheckSeconds ?? CookingEngine.defaultRecheckSeconds;
    final range = t.rangeEndsAt;
    if (range != null && range.isAfter(_now) && range.difference(_now).inSeconds < seconds) {
      seconds = range.difference(_now).inSeconds;
    }
    return (seconds / 60).ceil();
  }

  bool _isLastStep(PlanStep step) => _state.plan.steps.where((s) => !_state.isStepDone(s) && s.id != step.id).isEmpty;

  bool _blockedBySafety(PlanStep step, StepPrimary p) => p.needsSafetyCheck && !_safetyChecked.contains(step.id);

  Future<void> _finishStep(PlanStep step) async {
    await _controller.completeStep(step.id);
    if (mounted) setState(() => _helpOpen.remove(step.id));
  }

  Future<void> _back() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await _controller.undoLast();
    if (result.reason == 'dependent_started') {
      messenger.showSnackBar(SnackBar(content: Text(l10n.undoNotAllowed)));
    }
  }

  Future<void> _abandon() async {
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.abandonConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.abandonAction)),
        ],
      ),
    );
    if (ok != true) return;
    await _controller.abandon();
    router.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = widget.view;
    final plan = _state.plan;
    final title = view.recipeRow.customTitle ?? view.recipe.title;

    if (!view.isActive) {
      return AppScaffold(
        title: title,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.sessionEnded),
              TextButton(
                onPressed: () => context.go('/history/${widget.sessionId}'),
                child: Text(l10n.cookingHistory),
              ),
            ],
          ),
        ),
      );
    }

    final focus = _state.focusStep(_now);
    final primary = focus == null ? null : _state.primaryFor(focus, _now);
    final meanwhile = _state.meanwhile(_now);
    final guidance = {for (final g in _state.waitGuidance(_now)) g.timer.timerId: g};
    final shownWithSteps = {focus?.id, for (final s in meanwhile) s.id};
    final otherTimers = [
      for (final t in _state.activeTimers(_now))
        if (t.stepId == null || !shownWithSteps.contains(t.stepId)) t,
    ];
    final prep = [
      ..._state.prepTasksToShow(_now),
      for (final g in guidance.values)
        for (final task in g.suggestedPrep) PrepTaskView(task, urgent: false),
    ];
    final prepIds = <String>{};
    prep.retainWhere((v) => prepIds.add(v.task.id));

    return AppScaffold(
      title: title,
      actions: [
        PopupMenuButton<String>(
          onSelected: (_) => _abandon(),
          itemBuilder: (context) => [PopupMenuItem(value: 'abandon', child: Text(l10n.abandonCooking))],
        ),
      ],
      bottomBar: _state.isComplete
          ? null
          : _BottomBar(
              primary: focus == null || primary == null ? const SizedBox.shrink() : _primaryButtons(focus, primary),
              onBack: _state.log.isEmpty ? null : _back,
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(l10n.cookingProgress(_state.doneStepCount, plan.steps.length)),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: _state.doneStepCount / plan.steps.length),
          if (plan.advanceNoticeHe case final notice? when _state.doneStepCount == 0)
            Padding(padding: const EdgeInsets.only(top: 8), child: Text('🕒 $notice')),
          if (prep.isNotEmpty) ...[
            SectionTitle(l10n.prepTasks),
            for (final p in prep)
              _PrepCard(view: p, onDone: () => _controller.completePrepTask(p.task.id)),
          ],
          if (_state.isComplete)
            _CompleteCard(onFinish: () => context.go('/cook/${widget.sessionId}/finish'))
          else if (focus != null) ...[
            const SizedBox(height: 12),
            _stepCard(focus, primary, guidance, emphasized: true),
          ],
          if (otherTimers.isNotEmpty) ...[
            SectionTitle(l10n.timersTitle),
            for (final t in otherTimers) _timerTile(t, guidance[t.timerId]),
          ],
          if (meanwhile.isNotEmpty) ...[
            SectionTitle(l10n.meanwhileTitle),
            for (final s in meanwhile) _stepCard(s, _state.primaryFor(s, _now), guidance, emphasized: false),
          ],
          const SizedBox(height: 8),
          _AllStepsList(state: _state, onUndoStep: (id) async {
            final messenger = ScaffoldMessenger.of(context);
            final result = await _controller.undoStep(id);
            if (result.reason == 'dependent_started') {
              messenger.showSnackBar(SnackBar(content: Text(l10n.undoNotAllowed)));
            }
          }),
        ],
      ),
    );
  }

  /// The main button(s) for the current step, shown in the fixed bottom bar.
  Widget _primaryButtons(PlanStep step, StepPrimary p) {
    final l10n = AppLocalizations.of(context);
    final last = _isLastStep(step);
    final blocked = _blockedBySafety(step, p);
    const big = Size.fromHeight(52);
    return switch (p.kind) {
      PrimaryKind.startTimer => FilledButton(
          style: FilledButton.styleFrom(minimumSize: big),
          onPressed: () => _controller.confirmAction(step.id, p.action!.action.id),
          child: Text(p.action!.action.labelHe),
        ),
      PrimaryKind.next => FilledButton(
          style: FilledButton.styleFrom(minimumSize: big),
          onPressed: blocked ? null : () => _finishStep(step),
          child: Text(last ? l10n.stepPrimaryLast : l10n.stepPrimaryNext),
        ),
      PrimaryKind.checkDue => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => _controller.recheckTimer(p.timer!.timerId),
              child: Text(l10n.stepNeedMoreTime(_moreMinutes(p.timer!))),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: big),
              onPressed: blocked ? null : () => _finishStep(step),
              child: Text(last ? l10n.stepPrimaryReadyLast : l10n.stepPrimaryReady),
            ),
          ],
        ),
      PrimaryKind.waiting => OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: big),
          onPressed: blocked ? null : () => _finishStep(step),
          child: Text(l10n.stepReadyEarly),
        ),
    };
  }

  Widget _stepCard(PlanStep step, StepPrimary? p, Map<String, WaitGuidance> guidance, {required bool emphasized}) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ingredients = {for (final i in widget.view.recipe.ingredients) i.id: i};
    final timer = p?.timer;
    final g = timer == null ? null : guidance[timer.timerId];
    final checkDue = p?.kind == PrimaryKind.checkDue;
    final cue = (checkDue ? g?.checkCueHe : null) ?? step.donenessCueHe;
    final helpOpen = _helpOpen.contains(step.id);
    final hasHelp = step.helpHe != null || (step.donenessCueHe != null && !checkDue);
    final showSafety = p != null && p.needsSafetyCheck && p.kind != PrimaryKind.startTimer;

    return Card(
      color: emphasized ? theme.colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Text(step.title, style: emphasized ? theme.textTheme.titleLarge : theme.textTheme.titleMedium),
            Text(step.instructionHe, style: emphasized ? theme.textTheme.bodyLarge : null),
            for (final use in step.ingredientUses)
              if (ingredients[use.ingredientId] case final i?)
                Text(use.quantity == null ? '• ${i.name}' : '• ${i.name} — ${use.quantity!.display}'),
            if (step.ingredientUses.isEmpty && step.ingredientIds.isNotEmpty)
              Text(
                [for (final id in step.ingredientIds) if (ingredients[id] case final i?) i.name].join(' · '),
                style: theme.textTheme.bodySmall,
              ),
            if (step.temperature case final t?) Text(l10n.temperatureLabel(t.value)),
            if (timer != null) _TimerStatus(timer: timer, now: _now, guidance: g, controller: _controller),
            if (checkDue && cue != null) Text('👀 $cue', style: theme.textTheme.titleSmall),
            if (p?.kind == PrimaryKind.startTimer)
              if (p!.action!.timer case final t?)
                Text(l10n.stepStartsTimer(formatSeconds(t.seconds)), style: theme.textTheme.bodySmall),
            if (!showSafety)
              for (final w in step.warningsHe) Text('⚠️ $w', style: theme.textTheme.bodySmall),
            if (showSafety)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _safetyChecked.contains(step.id),
                onChanged: (v) => setState(() => v == true ? _safetyChecked.add(step.id) : _safetyChecked.remove(step.id)),
                title: Text(cue != null ? l10n.safetyCheckLabel(cue) : l10n.safetyCheckGeneric),
              ),
            if (hasHelp)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => setState(() => helpOpen ? _helpOpen.remove(step.id) : _helpOpen.add(step.id)),
                  icon: Icon(helpOpen ? Icons.expand_less : Icons.help_outline),
                  label: Text(helpOpen ? l10n.stepHideHelp : l10n.stepHelp),
                ),
              ),
            if (helpOpen) ...[
              if (step.helpHe case final h?) Text(h),
              if (step.donenessCueHe case final c? when !checkDue && !showSafety) Text('👀 $c'),
            ],
            if (!emphasized && p != null) _inlineButtons(step, p),
          ],
        ),
      ),
    );
  }

  /// Buttons inside a "בינתיים אפשר" card (the current step uses the bottom bar).
  Widget _inlineButtons(PlanStep step, StepPrimary p) {
    final l10n = AppLocalizations.of(context);
    final blocked = _blockedBySafety(step, p);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: switch (p.kind) {
        PrimaryKind.startTimer => [
            FilledButton.tonal(
              onPressed: () => _controller.confirmAction(step.id, p.action!.action.id),
              child: Text(p.action!.action.labelHe),
            ),
          ],
        PrimaryKind.next => [
            FilledButton.tonal(onPressed: blocked ? null : () => _finishStep(step), child: Text(l10n.stepPrimaryLast)),
          ],
        PrimaryKind.checkDue => [
            FilledButton.tonal(
              onPressed: blocked ? null : () => _finishStep(step),
              child: Text(l10n.stepPrimaryReadyLast),
            ),
            OutlinedButton(
              onPressed: () => _controller.recheckTimer(p.timer!.timerId),
              child: Text(l10n.stepNeedMoreTime(_moreMinutes(p.timer!))),
            ),
          ],
        PrimaryKind.waiting => const [],
      },
    );
  }

  /// A timer not shown inside a step card (a prep timer, or a step that is
  /// neither current nor suggested now).
  Widget _timerTile(TimerState t, WaitGuidance? g) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final checkDue = t.isFinished(_now);
    final step = t.stepId == null ? null : _state.plan.stepById(t.stepId!);
    final stepPrimary = step == null ? null : _state.primaryFor(step, _now);
    return Card(
      color: checkDue ? theme.colorScheme.errorContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            _TimerStatus(timer: t, now: _now, guidance: g, controller: _controller, showLabel: true),
            if (checkDue)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (step != null && stepPrimary?.kind == PrimaryKind.checkDue) ...[
                    FilledButton.tonal(
                      onPressed: _blockedBySafety(step, stepPrimary!) ? null : () => _finishStep(step),
                      child: Text(l10n.stepPrimaryReadyLast),
                    ),
                    OutlinedButton(
                      onPressed: () => _controller.recheckTimer(t.timerId),
                      child: Text(l10n.stepNeedMoreTime(_moreMinutes(t))),
                    ),
                  ] else
                    FilledButton.tonal(
                      onPressed: () => _controller.dismissTimer(t.timerId),
                      child: Text(l10n.dismissTimer),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// The fixed bottom area: "חזרה" (undo the last tap) and the main button.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.primary, required this.onBack});

  final Widget primary;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.undo),
            label: Text(AppLocalizations.of(context).backButton),
          ),
          const SizedBox(width: 8),
          Expanded(child: primary),
        ],
      );
}

/// Countdown (or "time to check"), check time, what's happening, and a small
/// menu for pause / ±1 minute / stop.
class _TimerStatus extends StatelessWidget {
  const _TimerStatus({
    required this.timer,
    required this.now,
    required this.controller,
    this.guidance,
    this.showLabel = false,
  });

  final TimerState timer;
  final DateTime now;
  final CookingController controller;
  final WaitGuidance? guidance;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final checkDue = timer.isFinished(now);
    final paused = timer.status == TimerStatus.paused;
    final g = guidance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showLabel) Text(timer.labelHe, style: theme.textTheme.titleSmall),
                  Text(
                    checkDue ? l10n.timerCheckDue : formatDuration(timer.remaining(now)),
                    textDirection: checkDue ? null : TextDirection.ltr,
                    style: theme.textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: l10n.timerOptions,
              icon: const Icon(Icons.more_vert),
              onSelected: (v) => switch (v) {
                'pause' => controller.pauseTimer(timer.timerId),
                'resume' => controller.resumeTimer(timer.timerId),
                'plus' => controller.extendTimer(timer.timerId),
                'minus' => controller.shortenTimer(timer.timerId),
                _ => controller.dismissTimer(timer.timerId),
              },
              itemBuilder: (context) => [
                if (!checkDue) PopupMenuItem(value: paused ? 'resume' : 'pause', child: Text(paused ? l10n.resume : l10n.pause)),
                PopupMenuItem(value: 'plus', child: Text(l10n.addMinute)),
                if (!checkDue) PopupMenuItem(value: 'minus', child: Text(l10n.removeMinute)),
                PopupMenuItem(value: 'stop', child: Text(l10n.dismissTimer)),
              ],
            ),
          ],
        ),
        if (!checkDue && !paused) Text(l10n.checkAtLabel(formatWhen(timer.endsAt!, now, l10n))),
        if (timer.rangeEndsAt case final end? when !timer.rechecked && end.isAfter(now))
          Text(l10n.rangeUntil(formatWhen(end, now, l10n)), style: theme.textTheme.bodySmall),
        if (!checkDue) ...[
          if (g?.waitInfoHe case final info?) Text(info),
          for (final tip in g?.tips ?? const <String>[]) Text('💡 $tip'),
          for (final next in g?.nextSteps ?? const <PlanStep>[])
            Text(l10n.nextStepPreview(next.title), style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _PrepCard extends StatelessWidget {
  const _PrepCard({required this.view, required this.onDone});

  final PrepTaskView view;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final task = view.task;
    return Card(
      child: CheckboxListTile(
        value: false,
        onChanged: (_) => onDone(),
        title: Text(task.textHe),
        subtitle: view.urgent
            ? Text(l10n.prepNeededNow, style: TextStyle(color: Theme.of(context).colorScheme.error))
            : null,
      ),
    );
  }
}

/// All steps, collapsed: done / current / later, and an undo per step for corrections.
class _AllStepsList extends StatelessWidget {
  const _AllStepsList({required this.state, required this.onUndoStep});

  final CookingState state;
  final void Function(String stepId) onUndoStep;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ExpansionTile(
        title: Text(l10n.allSteps),
        children: [
          for (final (i, step) in state.plan.steps.indexed)
            ListTile(
              leading: Icon(state.isStepDone(step) ? Icons.check_circle : Icons.radio_button_unchecked),
              title: Text('${l10n.stepNumber(i + 1)} · ${step.title}'),
              trailing: state.confirmedIn(step.id).isEmpty
                  ? null
                  : IconButton(
                      tooltip: l10n.undoLastAction,
                      icon: const Icon(Icons.undo),
                      onPressed: () => onUndoStep(step.id),
                    ),
            ),
        ],
      ),
    );
  }
}

class _CompleteCard extends StatelessWidget {
  const _CompleteCard({required this.onFinish});

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(l10n.allStepsDone, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            FilledButton(onPressed: onFinish, child: Text(l10n.goToFinish)),
          ],
        ),
      ),
    );
  }
}
