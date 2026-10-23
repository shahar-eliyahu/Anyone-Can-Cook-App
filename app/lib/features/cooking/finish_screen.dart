import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/clock.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../l10n/app_localizations.dart';
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
    final minutes = ref.read(clockProvider)().difference(view.session.startedAt).inMinutes;

    return AppScaffold(
      title: l10n.finishTitle,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.finishSummary(view.recipeRow.customTitle ?? view.recipe.title),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(l10n.cookingTime(l10n.minutesShort(minutes))),
          Text(l10n.cookingProgress(view.state.doneStepCount, view.state.plan.steps.length)),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.notesLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving || !view.isActive ? null : _finish,
            child: Text(l10n.saveAndFinish),
          ),
        ],
      ),
    );
  }
}
