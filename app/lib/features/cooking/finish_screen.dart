import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/clock.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/motion_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../history/history_screen.dart';
import 'cooking_controller.dart';

class FinishScreen extends ConsumerStatefulWidget {
  const FinishScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<FinishScreen> createState() => _FinishScreenState();
}

class _FinishScreenState extends ConsumerState<FinishScreen> {
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final router = GoRouter.of(context);
    final notes = _notes.text.trim();
    await ref
        .read(cookingControllerProvider(widget.sessionId).notifier)
        .finish(notes: notes.isEmpty ? null : notes);
    router.go('/history/${widget.sessionId}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(cookingControllerProvider(widget.sessionId)).value;
    if (view == null) {
      return AppScaffold(title: l10n.finishTitle, body: const Center(child: CircularProgressIndicator()));
    }
    final ended = ref.read(clockProvider)();

    final theme = Theme.of(context);
    final title = view.recipeRow.customTitle ?? view.recipe.title;

    return AppScaffold(
      title: l10n.finishTitle,
      bottomBar: FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        onPressed: _saving || !view.isActive ? null : _finish,
        icon: const Icon(Icons.check_rounded),
        label: Text(l10n.saveAndFinish),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, Space.xl),
        children: [
          Center(
            child: TweenAnimationBuilder<double>(
              // The logo tilts once, like a little bow. No confetti.
              tween: Tween(begin: Motion.reduced(context) ? 0 : -0.08, end: 0),
              duration: Motion.of(context, const Duration(milliseconds: 600)),
              curve: Curves.elasticOut,
              builder: (context, turn, child) => Transform.rotate(angle: turn * 6.283, child: child),
              child: const LogoMark(size: 88),
            ),
          ),
          const SizedBox(height: Space.l),
          Appear(
            child: Column(
              spacing: Space.s,
              children: [
                Text(l10n.finishCelebrate, style: theme.textTheme.displaySmall?.copyWith(color: AppColors.onSoftBlue)),
                Text(l10n.finishSummary(title), textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: Space.s,
                  runSpacing: Space.s,
                  children: [
                    InfoPill(
                      icon: Icons.schedule_rounded,
                      label: l10n.cookingTime(cookingDurationLabel(l10n, view.session.startedAt, ended)),
                    ),
                    InfoPill(
                      icon: Icons.check_circle_outline_rounded,
                      label: l10n.cookingProgress(view.state.doneStepCount, view.state.plan.steps.length),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.xl),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: InputDecoration(labelText: l10n.notesLabel, alignLabelWithHint: true),
          ),
        ],
      ),
    );
  }
}
