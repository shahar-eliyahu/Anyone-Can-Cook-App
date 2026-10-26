import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/clock.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/motion_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cooking_plan.dart';
import '../assistant/assistant_models.dart';
import '../assistant/assistant_sheet.dart';
import '../assistant/hands_free.dart';
import '../assistant/remy_widgets.dart';
import 'cooking_controller.dart';
import 'engine/cooking_engine.dart';
import 'guidance.dart';

/// The cooking screen: the current step big and clear, with one main button and Remy beside
/// it at the bottom (docs/DECISIONS.md #35, #36; docs/DESIGN.md §5). Timers, prep tasks and
/// parallel steps stay available but compact; technical details are not shown. Leaving the
/// screen never stops cooking.
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
  late final String? _noticeStepId = advanceNoticeStepId(widget.view.state.plan);
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
    HapticFeedback.lightImpact(); // felt with wet hands, without looking
    await _controller.completeStep(step.id);
    if (mounted) setState(() => _helpOpen.remove(step.id));
  }

  Future<void> _back() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await _controller.undoLast();
    if (result.reason == 'dependent_started') {
      messenger.showMessage(l10n.undoNotAllowed);
    }
  }

  Future<void> _abandon() async {
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final ok = await confirmDialog(
      context,
      message: l10n.abandonConfirm,
      confirmLabel: l10n.abandonAction,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!ok) return;
    await _controller.abandon();
    router.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final view = widget.view;
    final plan = _state.plan;
    final title = view.recipeRow.customTitle ?? view.recipe.title;

    if (!view.isActive) {
      return AppScaffold(
        title: title,
        body: EmptyState(
          icon: Icons.check_circle_outline_rounded,
          title: l10n.sessionEnded,
          action: OutlinedButton(
            onPressed: () => context.go('/history/${widget.sessionId}'),
            child: Text(l10n.cookingHistory),
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
    final total = plan.steps.length;
    final done = _state.doneStepCount;
    final handsFree = ref.watch(handsFreeControllerProvider(widget.sessionId));
    // "היי רמי" heard: Remy opens without a touch (answering at once when a request followed).
    ref.listen(handsFreeControllerProvider(widget.sessionId).select((s) => s.wake?.id), (previous, id) {
      final wake = ref.read(handsFreeControllerProvider(widget.sessionId)).wake;
      if (id == null || id == previous || wake == null || !mounted) return;
      showAssistantSheet(
        context,
        RemyScope.session(widget.sessionId),
        listen: wake.command.isEmpty,
        command: wake.command.isEmpty ? null : wake.command,
        handsFree: true,
      );
    });

    return AppScaffold(
      title: title,
      actions: [
        if (handsFree.enabled)
          _HandsFreeIndicator(state: handsFree, controller: ref.read(handsFreeControllerProvider(widget.sessionId).notifier)),
      ],
      bottomBar: _state.isComplete
          ? null
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: Space.m,
              children: [
                RemyButton(scope: RemyScope.session(widget.sessionId)),
                Expanded(
                  child: focus == null || primary == null ? const SizedBox.shrink() : _primaryButtons(focus, primary),
                ),
              ],
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.xl),
        children: [
          // Where we are, in one light line, with the one-tap undo beside it.
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: Space.s,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (!_state.isComplete && focus != null)
                      Text(
                        l10n.stepOfTotal(plan.steps.indexOf(focus) + 1, total),
                        style: theme.textTheme.titleSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    Text(l10n.cookingProgress(done, total), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _state.log.isEmpty ? null : _back,
                icon: const Icon(Icons.undo_rounded, size: 20),
                label: Text(l10n.backButton),
              ),
            ],
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(end: total == 0 ? 0 : done / total),
            duration: Motion.of(context, Motion.long),
            curve: Motion.standard,
            builder: (context, v, _) => LinearProgressIndicator(value: v, minHeight: 4, semanticsLabel: l10n.progressLabel),
          ),
          const SizedBox(height: Space.m),
          // The instruction first: what to do now.
          AnimatedSwitcher(
            duration: Motion.of(context, Motion.medium),
            switchInCurve: Motion.enter,
            switchOutCurve: Motion.exit,
            transitionBuilder: (child, animation) => _stepTransition(context, child, animation),
            child: _state.isComplete
                ? _CompleteCard(key: const ValueKey('complete'), onFinish: () => context.go('/cook/${widget.sessionId}/finish'))
                : focus != null
                    ? KeyedSubtree(key: ValueKey(focus.id), child: _stepCard(focus, primary, guidance, emphasized: true))
                    : const SizedBox.shrink(),
          ),
          if (prep.isNotEmpty) ...[
            SectionTitle(l10n.prepTasks),
            for (final p in prep) _PrepCard(view: p, onDone: () => _controller.completePrepTask(p.task.id)),
          ],
          if (otherTimers.isNotEmpty) ...[
            SectionTitle(l10n.timersTitle),
            for (final t in otherTimers) _timerTile(t, guidance[t.timerId]),
          ],
          if (meanwhile.isNotEmpty) ...[
            SectionTitle(l10n.meanwhileTitle),
            for (final s in meanwhile) _stepCard(s, _state.primaryFor(s, _now), guidance, emphasized: false),
          ],
          const SizedBox(height: Space.m),
          _AllStepsList(state: _state, onUndoStep: (id) async {
            final messenger = ScaffoldMessenger.of(context);
            final result = await _controller.undoStep(id);
            if (result.reason == 'dependent_started') {
              messenger.showMessage(l10n.undoNotAllowed);
            }
          }),
          const SizedBox(height: Space.s),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              onPressed: _abandon,
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(l10n.abandonCooking),
            ),
          ),
        ],
      ),
    );
  }

  /// The next step slides in from the reading direction; reduced motion: a fade.
  Widget _stepTransition(BuildContext context, Widget child, Animation<double> animation) {
    final fade = FadeTransition(opacity: animation, child: child);
    if (Motion.reduced(context)) return fade;
    final sign = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    return SlideTransition(
      position: Tween(begin: Offset(0.06 * sign, 0), end: Offset.zero).animate(animation),
      child: fade,
    );
  }

  /// The main button(s) for the current step, shown in the fixed bottom bar.
  Widget _primaryButtons(PlanStep step, StepPrimary p) {
    final l10n = AppLocalizations.of(context);
    final last = _isLastStep(step);
    final blocked = _blockedBySafety(step, p);
    const big = Size.fromHeight(56);
    return switch (p.kind) {
      PrimaryKind.startTimer => FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: big),
          onPressed: () {
            HapticFeedback.lightImpact();
            _controller.confirmAction(step.id, p.action!.action.id);
          },
          icon: const Icon(Icons.timer_outlined),
          label: Text(p.action!.action.labelHe),
        ),
      PrimaryKind.next => FilledButton(
          style: FilledButton.styleFrom(minimumSize: big),
          onPressed: blocked ? null : () => _finishStep(step),
          child: Text(last ? l10n.stepPrimaryLast : l10n.stepPrimaryNext),
        ),
      PrimaryKind.checkDue => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Space.s,
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
    final ingredients = {for (final i in widget.view.displayRecipe.ingredients) i.id: i};
    final timer = p?.timer;
    final g = timer == null ? null : guidance[timer.timerId];
    final checkDue = p?.kind == PrimaryKind.checkDue;
    final cue = (checkDue ? g?.checkCueHe : null) ?? step.donenessCueHe;
    final helpOpen = _helpOpen.contains(step.id);
    final hasHelp = step.helpHe != null || (step.donenessCueHe != null && !checkDue);
    final showSafety = p != null && p.needsSafetyCheck && p.kind != PrimaryKind.startTimer;
    final uses = [
      for (final use in step.ingredientUses)
        if (ingredients[use.ingredientId] case final i?) use.quantity == null ? i.name : '${i.name}: ${use.quantity!.display}',
      if (step.ingredientUses.isEmpty)
        for (final id in step.ingredientIds) ?ingredients[id]?.name,
    ];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: emphasized ? AppColors.brandBlue.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant, width: emphasized ? 1.5 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Space.s,
          children: [
            Text(step.title, style: (emphasized ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)?.copyWith(fontWeight: FontWeight.w700)),
            Text(
              tidyHe(step.instructionHe),
              style: emphasized ? theme.textTheme.bodyLarge?.copyWith(fontSize: 20, height: 1.5) : theme.textTheme.bodyMedium,
            ),
            for (final n in step.notesHe)
              Text('🔄 $n', style: theme.textTheme.titleSmall?.copyWith(color: context.palette.onBeige)),
            if (uses.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Space.m),
                decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(Radii.input)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Space.xs,
                  children: [
                    if (emphasized)
                      Text(l10n.stepIngredientsTitle, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    for (final u in uses) Text('• $u', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            if (step.temperature case final t?)
              InfoPill(icon: Icons.thermostat_rounded, label: l10n.temperatureLabel(t.value)),
            // Planning-ahead advice ("לנוח במקרר לילה שלם") shows with the step it is about;
            // before cooking it is in preparation.
            if (emphasized && step.id == _noticeStepId)
              if (_state.plan.advanceNoticeHe case final notice?)
                NoteBanner(tidyHe(notice), kind: NoteKind.tip, icon: Icons.schedule_rounded),
            if (timer != null) _TimerStatus(timer: timer, now: _now, guidance: g, controller: _controller),
            if (checkDue && cue != null) Text('👀 ${tidyHe(cue)}', style: theme.textTheme.titleSmall),
            if (p?.kind == PrimaryKind.startTimer)
              if (p!.action!.timer case final t?)
                Row(
                  spacing: Space.xs,
                  children: [
                    Icon(Icons.timer_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                    Flexible(
                      child: Text(
                        l10n.stepStartsTimer(formatSeconds(t.seconds)),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
            if (!showSafety)
              for (final w in step.warningsHe) NoteBanner(tidyHe(w), kind: NoteKind.safety),
            if (showSafety)
              Material(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(Radii.input),
                child: CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _safetyChecked.contains(step.id),
                  onChanged: (v) => setState(() => v == true ? _safetyChecked.add(step.id) : _safetyChecked.remove(step.id)),
                  title: Text(cue != null ? l10n.safetyCheckLabel(cue) : l10n.safetyCheckGeneric),
                ),
              ),
            if (hasHelp)
              TextButton.icon(
                onPressed: () => setState(() => helpOpen ? _helpOpen.remove(step.id) : _helpOpen.add(step.id)),
                icon: Icon(helpOpen ? Icons.expand_less_rounded : Icons.help_outline_rounded),
                label: Text(helpOpen ? l10n.stepHideHelp : l10n.stepHelp),
              ),
            AnimatedSize(
              duration: Motion.of(context, Motion.medium),
              curve: Motion.standard,
              alignment: AlignmentDirectional.topStart,
              child: helpOpen
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: Space.xs,
                      children: [
                        if (step.helpHe case final h?) NoteBanner(tidyHe(h), kind: NoteKind.tip),
                        if (step.donenessCueHe case final c? when !checkDue && !showSafety) Text('👀 ${tidyHe(c)}'),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
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
      spacing: Space.s,
      runSpacing: Space.xs,
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
    final checkDue = t.isFinished(_now);
    final step = t.stepId == null ? null : _state.plan.stepById(t.stepId!);
    final stepPrimary = step == null ? null : _state.primaryFor(step, _now);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Space.s,
        children: [
          _TimerStatus(timer: t, now: _now, guidance: g, controller: _controller, showLabel: true),
          if (checkDue)
            Wrap(
              spacing: Space.s,
              runSpacing: Space.xs,
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
    );
  }
}

/// A countdown that is easy to read from across the kitchen, with its controls in plain
/// words. When time is up it turns amber and pulses a few times ("time to check", never
/// "ready").
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
    final p = context.palette;
    final checkDue = timer.isFinished(now);
    final paused = timer.status == TimerStatus.paused;
    final g = guidance;
    final fg = checkDue ? p.onTimerDoneContainer : theme.colorScheme.onSurface;
    final soft = checkDue ? p.onTimerDoneContainer : theme.colorScheme.onSurfaceVariant;

    return AttentionPulse(
      active: checkDue,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.medium),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(Space.m + 2, Space.m, Space.m + 2, Space.s),
        decoration: BoxDecoration(
          color: checkDue ? p.timerDoneContainer : theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(Radii.input + 2),
          border: Border.all(color: checkDue ? p.timerDone : Colors.transparent, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Row(
              spacing: Space.m,
              children: [
                Icon(
                  checkDue ? Icons.alarm_on_rounded : (paused ? Icons.pause_circle_outline_rounded : Icons.timer_outlined),
                  color: checkDue ? p.timerDone : AppColors.primary,
                  size: 28,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showLabel) Text(timer.labelHe, style: theme.textTheme.titleSmall?.copyWith(color: fg)),
                      Text(
                        checkDue ? l10n.timerCheckDue : formatDuration(timer.remaining(now)),
                        textDirection: checkDue ? null : TextDirection.ltr,
                        style: theme.textTheme.headlineMedium?.copyWith(color: fg, fontFeatures: tabularFigures),
                      ),
                      if (paused && !checkDue) Text(l10n.timerPaused, style: theme.textTheme.labelMedium?.copyWith(color: soft)),
                    ],
                  ),
                ),
              ],
            ),
            if (!checkDue && !paused) Text(l10n.checkAtLabel(formatWhen(timer.endsAt!, now, l10n)), style: TextStyle(color: soft)),
            if (timer.rangeEndsAt case final end? when !timer.rechecked && end.isAfter(now))
              Text(l10n.rangeUntil(formatWhen(end, now, l10n)), style: theme.textTheme.bodySmall?.copyWith(color: soft)),
            if (!checkDue) ...[
              if (g?.waitInfoHe case final info?) Text(tidyHe(info)),
              for (final tip in g?.tips ?? const <String>[]) Text('💡 $tip'),
              for (final next in g?.nextSteps ?? const <PlanStep>[])
                Text(l10n.nextStepPreview(next.title), style: theme.textTheme.bodySmall?.copyWith(color: soft)),
            ],
            // Controls in words: one hand, wet fingers, no guessing.
            Wrap(
              spacing: Space.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!checkDue)
                  TextButton.icon(
                    onPressed: () => paused ? controller.resumeTimer(timer.timerId) : controller.pauseTimer(timer.timerId),
                    icon: Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                    label: Text(paused ? l10n.resume : l10n.pause),
                  ),
                TextButton.icon(
                  onPressed: () => controller.extendTimer(timer.timerId),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.addMinute),
                ),
                PopupMenuButton<String>(
                  tooltip: l10n.timerOptions,
                  onSelected: (v) => v == 'minus' ? controller.shortenTimer(timer.timerId) : controller.dismissTimer(timer.timerId),
                  itemBuilder: (context) => [
                    if (!checkDue) PopupMenuItem(value: 'minus', child: Text(l10n.removeMinute)),
                    PopupMenuItem(value: 'stop', child: Text(l10n.dismissTimer)),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.m),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: Space.xs,
                      children: [
                        Icon(Icons.more_horiz_rounded, color: AppColors.primary),
                        Text(l10n.timerOptions, style: theme.textTheme.labelLarge?.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Hands-free in the header: "מקשיב" only while it really listens (a tap stops it for this
/// cooking session); a muted microphone to turn it back on when it was stopped or can't
/// listen; nothing while starting or while Remy's sheet is open. Setup lives in preparation
/// and settings, not on every step.
class _HandsFreeIndicator extends StatelessWidget {
  const _HandsFreeIndicator({required this.state, required this.controller});

  final HandsFreeState state;
  final HandsFreeController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    switch (state.status) {
      case HandsFreeStatus.listening:
        return Semantics(
          button: true,
          label: l10n.handsFreeIndicatorLabel,
          excludeSemantics: true,
          child: Material(
            color: theme.colorScheme.primaryContainer,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () {
                controller.stopForNow();
                ScaffoldMessenger.of(context).showMessage(l10n.handsFreeStopped);
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.m),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: Space.xs,
                    children: [
                      BreathingRing(active: true, child: Icon(Icons.mic_rounded, size: 18, color: AppColors.primary)),
                      Text(
                        l10n.handsFreeIndicator,
                        style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      case HandsFreeStatus.stopped || HandsFreeStatus.unavailable:
        final why = state.status == HandsFreeStatus.unavailable ? state.messageHe : null;
        return IconButton(
          tooltip: why ?? l10n.handsFreeResume,
          icon: Icon(Icons.mic_off_outlined, color: theme.colorScheme.onSurfaceVariant),
          onPressed: () {
            if (why != null) ScaffoldMessenger.of(context).showMessage(why);
            controller.resume();
          },
        );
      case HandsFreeStatus.off || HandsFreeStatus.starting || HandsFreeStatus.paused:
        return const SizedBox.shrink();
    }
  }
}

class _PrepCard extends StatelessWidget {
  const _PrepCard({required this.view, required this.onDone});

  final PrepTaskView view;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final task = view.task;
    return Card(
      color: view.urgent ? context.palette.timerDoneContainer : null,
      child: CheckboxListTile(
        value: false,
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: (_) => onDone(),
        title: Text(tidyHe(task.textHe)),
        subtitle: view.urgent
            ? Text(l10n.prepNeededNow, style: TextStyle(color: context.palette.onTimerDoneContainer, fontWeight: FontWeight.w700))
            : null,
        secondary: Icon(Icons.kitchen_outlined, color: theme.colorScheme.onSurfaceVariant),
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
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.format_list_numbered_rounded, color: AppColors.brandBlue),
        title: Text(l10n.allSteps, style: theme.textTheme.titleMedium),
        children: [
          for (final (i, step) in state.plan.steps.indexed)
            ListTile(
              leading: Icon(
                state.isStepDone(step) ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: state.isStepDone(step) ? context.palette.success : theme.colorScheme.outline,
              ),
              title: Text('${l10n.stepNumber(i + 1)} · ${step.title}'),
              trailing: state.confirmedIn(step.id).isEmpty
                  ? null
                  : IconButton(
                      tooltip: l10n.undoLastAction,
                      icon: const Icon(Icons.undo_rounded),
                      onPressed: () => onUndoStep(step.id),
                    ),
            ),
        ],
      ),
    );
  }
}

class _CompleteCard extends StatelessWidget {
  const _CompleteCard({super.key, required this.onFinish});

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      color: context.palette.successContainer,
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          spacing: Space.m,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: Motion.reduced(context) ? 1 : 0.6, end: 1),
              duration: Motion.of(context, Motion.long),
              curve: Curves.easeOutBack,
              builder: (context, s, child) => Transform.scale(scale: s, child: child),
              child: Icon(Icons.celebration_rounded, size: 48, color: context.palette.wood),
            ),
            Text(l10n.allStepsDone, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            FilledButton(onPressed: onFinish, child: Text(l10n.goToFinish)),
          ],
        ),
      ),
    );
  }
}
