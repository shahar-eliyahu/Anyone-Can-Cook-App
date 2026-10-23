import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/clock.dart';
import '../../core/format.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/estimate_badge.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cooking_plan.dart';
import '../../models/recipe.dart';
import 'cooking_controller.dart';
import 'engine/action_dispatcher.dart';
import 'engine/cooking_engine.dart';

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

class _CookingBody extends ConsumerWidget {
  const _CookingBody({required this.sessionId, required this.view, required this.now});

  final String sessionId;
  final CookingView view;
  final DateTime now;

  CookingController _controller(WidgetRef ref) =>
      ref.read(cookingControllerProvider(sessionId).notifier);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = view.state;
    final plan = state.plan;

    if (!view.isActive) {
      return AppScaffold(
        title: view.recipeRow.customTitle ?? view.recipe.title,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.sessionEnded),
              TextButton(
                onPressed: () => context.go('/history/$sessionId'),
                child: Text(l10n.cookingHistory),
              ),
            ],
          ),
        ),
      );
    }

    final focus = state.focusStep(now);
    final meanwhile = state.meanwhile(now);
    final timers = state.activeTimers(now);
    final prep = state.prepTasksToShow(now);

    return AppScaffold(
      title: view.recipeRow.customTitle ?? view.recipe.title,
      actions: [
        PopupMenuButton<String>(
          onSelected: (_) => _abandon(context, ref),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'abandon', child: Text(l10n.abandonCooking)),
          ],
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(l10n.cookingProgress(state.doneStepCount, plan.steps.length)),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: state.doneStepCount / plan.steps.length),
          if (timers.isNotEmpty) ...[
            SectionTitle(l10n.timersTitle),
            for (final t in timers) _TimerCard(timer: t, now: now, controller: _controller(ref)),
          ],
          if (prep.isNotEmpty) ...[
            SectionTitle(l10n.prepTasks),
            for (final p in prep) _PrepCard(view: p, onDone: () => _completePrep(context, ref, p.task)),
          ],
          if (state.isComplete)
            _CompleteCard(onFinish: () => context.go('/cook/$sessionId/finish'))
          else if (focus != null) ...[
            SectionTitle(l10n.nowLabel),
            _StepCard(
              step: focus,
              recipe: view.recipe,
              state: state,
              now: now,
              emphasized: true,
              onAction: (a) => _confirm(context, ref, a),
            ),
          ],
          if (meanwhile.isNotEmpty) ...[
            SectionTitle(l10n.meanwhileTitle),
            for (final s in meanwhile)
              _StepCard(
                step: s,
                recipe: view.recipe,
                state: state,
                now: now,
                onAction: (a) => _confirm(context, ref, a),
              ),
          ],
          const SizedBox(height: 8),
          _AllStepsList(
            state: state,
            now: now,
            onAction: (a) => _confirm(context, ref, a),
            onUndo: (stepId) => _undoStep(context, ref, stepId),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref, AvailableAction a) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (a.action.confirmPolicy == ConfirmPolicy.alwaysAsk) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.confirmActionTitle(a.action.labelHe)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (a.step.donenessCueHe != null || a.step.warningsHe.isNotEmpty)
                Text(l10n.confirmCheck),
              if (a.step.donenessCueHe != null) Text('• ${a.step.donenessCueHe}'),
              for (final w in a.step.warningsHe) Text('⚠️ $w'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.confirmNotYet)),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.confirmYes(a.action.labelHe)),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    final result = await _controller(ref).confirmAction(a.step.id, a.action.id);
    messenger.hideCurrentSnackBar();
    switch (result.status) {
      case DispatchStatus.applied:
        final t = result.startedTimer;
        messenger.showSnackBar(SnackBar(
          content: Text(t == null
              ? l10n.actionDone(a.action.labelHe)
              : l10n.actionDoneWithTimer(a.action.labelHe, t.labelHe, formatSeconds(t.totalSeconds))),
          action: SnackBarAction(label: l10n.undo, onPressed: () => _undoStep(context, ref, a.step.id)),
        ));
      case DispatchStatus.alreadyDone:
        messenger.showSnackBar(SnackBar(content: Text(l10n.actionAlreadyDone)));
      case DispatchStatus.invalid:
        messenger.showSnackBar(SnackBar(content: Text(l10n.actionNotAvailable)));
    }
  }

  Future<void> _completePrep(BuildContext context, WidgetRef ref, PrepTask task) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await _controller(ref).completePrepTask(task.id);
    if (!result.isApplied) return;
    final t = result.startedTimer;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(t == null
            ? l10n.actionDone(task.textHe)
            : l10n.actionDoneWithTimer(task.textHe, t.labelHe, formatSeconds(t.totalSeconds))),
        action: SnackBarAction(label: l10n.undo, onPressed: () => _controller(ref).undoPrepTask(task.id)),
      ));
  }

  Future<void> _undoStep(BuildContext context, WidgetRef ref, String stepId) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await _controller(ref).undoStep(stepId);
    if (result.reason == 'dependent_started') {
      messenger.showSnackBar(SnackBar(content: Text(l10n.undoNotAllowed)));
    }
  }

  Future<void> _abandon(BuildContext context, WidgetRef ref) async {
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
    await _controller(ref).abandon();
    router.go('/');
  }
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({required this.timer, required this.now, required this.controller});

  final TimerState timer;
  final DateTime now;
  final CookingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final finished = timer.isFinished(now);
    final paused = timer.status == TimerStatus.paused;

    return Card(
      color: finished ? scheme.errorContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProvenancedText(timer.labelHe, timer.provenance, style: Theme.of(context).textTheme.titleSmall),
            Text(
              finished ? l10n.timerFinished : formatDuration(timer.remaining(now)),
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            Wrap(
              spacing: 8,
              children: [
                if (!finished)
                  OutlinedButton(
                    onPressed: () => paused ? controller.resumeTimer(timer.timerId) : controller.pauseTimer(timer.timerId),
                    child: Text(paused ? l10n.resume : l10n.pause),
                  ),
                OutlinedButton(
                  onPressed: () => controller.extendTimer(timer.timerId),
                  child: Text(l10n.addMinute),
                ),
                TextButton(
                  onPressed: () => controller.dismissTimer(timer.timerId),
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (view.urgent)
              Text(l10n.prepNeededNow, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (task.leadMinutes case final m?)
              ProvenancedText(l10n.leadTime(m.value), m.provenance, note: m.noteHe),
            if (task.timer case final t?)
              ProvenancedText(l10n.startsTimer(t.labelHe, formatSeconds(t.seconds)), t.provenance, note: t.noteHe),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.recipe,
    required this.state,
    required this.now,
    required this.onAction,
    this.emphasized = false,
  });

  final PlanStep step;
  final Recipe recipe;
  final CookingState state;
  final DateTime now;
  final bool emphasized;
  final void Function(AvailableAction) onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final available = state.availableActionFor(step.id, now);
    final waitingOn = [
      for (final t in state.timers.values)
        if (t.stepId == step.id && t.isPending(now)) t,
    ];
    final ingredients = {for (final i in recipe.ingredients) i.id: i};

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
            if (step.temperature case final t?)
              ProvenancedText(l10n.temperatureLabel(t.value), t.provenance),
            if (step.ingredientIds.isNotEmpty)
              Text(
                [
                  for (final id in step.ingredientIds)
                    if (ingredients[id] case final i?) i.name,
                ].join(' · '),
                style: theme.textTheme.bodySmall,
              ),
            if (step.donenessCueHe != null) Text('👀 ${step.donenessCueHe}'),
            for (final w in step.warningsHe)
              Text('⚠️ $w', style: TextStyle(color: theme.colorScheme.error)),
            for (final t in waitingOn) Text(l10n.waitingForTimer(t.labelHe)),
            if (available != null) ...[
              const SizedBox(height: 4),
              FilledButton(
                onPressed: () => onAction(available),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: Text(available.action.labelHe),
              ),
              if (available.timer case final t?)
                ProvenancedText(
                  l10n.startsTimer(t.labelHe, formatSeconds(t.seconds)),
                  t.provenance,
                  note: t.noteHe,
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AllStepsList extends StatelessWidget {
  const _AllStepsList({
    required this.state,
    required this.now,
    required this.onAction,
    required this.onUndo,
  });

  final CookingState state;
  final DateTime now;
  final void Function(AvailableAction) onAction;
  final void Function(String stepId) onUndo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String label(StepStatus s) => switch (s) {
          StepStatus.locked => l10n.stepLocked,
          StepStatus.ready => l10n.stepReady,
          StepStatus.inProgress => l10n.stepInProgress,
          StepStatus.waitingTimer => l10n.stepWaiting,
          StepStatus.done => l10n.stepDone,
        };
    IconData icon(StepStatus s) => switch (s) {
          StepStatus.locked => Icons.lock_outline,
          StepStatus.ready => Icons.radio_button_unchecked,
          StepStatus.inProgress => Icons.timelapse,
          StepStatus.waitingTimer => Icons.hourglass_bottom,
          StepStatus.done => Icons.check_circle,
        };

    return Card(
      child: ExpansionTile(
        title: Text(l10n.allSteps),
        children: [
          for (final (i, step) in state.plan.steps.indexed)
            Builder(builder: (context) {
              final status = state.statusOf(step, now);
              final available = state.availableActionFor(step.id, now);
              return ListTile(
                leading: Icon(icon(status)),
                title: Text('${l10n.stepNumber(i + 1)} · ${step.title}'),
                subtitle: Text(label(status)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (available != null)
                      TextButton(onPressed: () => onAction(available), child: Text(available.action.labelHe)),
                    if (state.confirmedIn(step.id).isNotEmpty)
                      IconButton(
                        tooltip: l10n.undoLastAction,
                        icon: const Icon(Icons.undo),
                        onPressed: () => onUndo(step.id),
                      ),
                  ],
                ),
              );
            }),
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
