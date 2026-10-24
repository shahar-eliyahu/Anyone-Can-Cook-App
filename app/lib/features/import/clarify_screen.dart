import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_scaffold.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/recipe_analysis.dart';
import 'import_errors.dart';
import 'import_service.dart';

/// The questions the analysis could not resolve from the recipe or the food-safety
/// reference. Unanswered questions and "לא יודע/ת" are sent as unknown; they are
/// never asked again (the plan then uses a labeled estimate or explains the limitation).
class ClarifyScreen extends ConsumerStatefulWidget {
  const ClarifyScreen({super.key, required this.draftId, this.planError});

  final String draftId;

  /// Set when generating the plan failed right after the import (e.g. AI quota used up).
  final Object? planError;

  @override
  ConsumerState<ClarifyScreen> createState() => _ClarifyScreenState();
}

class _ClarifyScreenState extends ConsumerState<ClarifyScreen> {
  RecipeAnalysis? _analysis;
  bool _missing = false;
  final _fields = <String, TextEditingController>{};
  final _choices = <String, String>{};
  final _unknown = <String>{};
  bool _busy = false;
  String? _error;
  late bool _failed = widget.planError != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.planError case final e? when _error == null && _failed) {
      final l10n = AppLocalizations.of(context);
      _error = '${importErrorText(l10n, e)}\n${l10n.importPlanFailedNote}';
    }
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final analysis = (await ref.read(recipeRepositoryProvider).getRecipe(widget.draftId))?.analysis;
    if (!mounted) return;
    setState(() {
      _analysis = analysis;
      _missing = analysis == null;
      final previous = {for (final a in analysis?.answers ?? const <Answer>[]) a.questionId: a};
      for (final q in analysis?.questions ?? const <Question>[]) {
        final a = previous[q.id];
        if (a?.unknown ?? false) _unknown.add(q.id);
        if (q.kind == QuestionKind.choice) {
          if (a?.value case final v?) _choices[q.id] = v;
        } else {
          _fields[q.id] = TextEditingController(text: a?.value ?? '');
        }
      }
    });
  }

  List<Answer> get _answers => [
        for (final q in _analysis!.questions)
          switch ((_unknown.contains(q.id), q.kind == QuestionKind.choice ? _choices[q.id] : _fields[q.id]!.text.trim())) {
            (false, final v?) when v.isNotEmpty => Answer(questionId: q.id, value: v),
            _ => Answer(questionId: q.id, unknown: true),
          },
      ];

  Future<void> _continue() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Answers are saved before the plan call, so a failure keeps them.
      await ref.read(importServiceProvider).submitAnswers(widget.draftId, _answers);
      if (mounted) context.pushReplacement('/drafts/${widget.draftId}/review');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = importErrorText(l10n, e);
          _failed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final analysis = _analysis;
    if (analysis == null) {
      return AppScaffold(
        title: l10n.clarifyTitle,
        body: Center(child: _missing ? Text(l10n.recipeNotFound) : const CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      title: l10n.clarifyTitle,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (analysis.recipe?.title case final t?) Text(t, style: theme.textTheme.titleLarge),
          if (analysis.questions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(l10n.clarifyIntro),
          ],
          const SizedBox(height: 8),
          for (final q in analysis.questions)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    if (q.required || q.category == GapCategory.safety)
                      Text('⚠️ ${l10n.clarifyRequired}', style: TextStyle(color: theme.colorScheme.error)),
                    Text(q.textHe, style: theme.textTheme.titleSmall),
                    Text(q.whyHe, style: theme.textTheme.bodySmall),
                    if (!_unknown.contains(q.id))
                      if (q.kind == QuestionKind.choice)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final o in q.options)
                              ChoiceChip(
                                label: Text(o),
                                selected: _choices[q.id] == o,
                                onSelected: _busy ? null : (_) => setState(() => _choices[q.id] = o),
                              ),
                          ],
                        )
                      else
                        TextField(
                          controller: _fields[q.id],
                          enabled: !_busy,
                          keyboardType: q.kind == QuestionKind.number
                              ? const TextInputType.numberWithOptions(decimal: true)
                              : TextInputType.text,
                          decoration: InputDecoration(
                            hintText: l10n.clarifyAnswerHint,
                            suffixText: q.unitHe,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                    FilterChip(
                      label: Text(l10n.clarifyDontKnow),
                      selected: _unknown.contains(q.id),
                      onSelected: _busy
                          ? null
                          : (on) => setState(() => on ? _unknown.add(q.id) : _unknown.remove(q.id)),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (_busy)
            Row(
              spacing: 16,
              children: [
                const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3)),
                Text(l10n.importStagePlanning),
              ],
            )
          else
            FilledButton.icon(
              onPressed: _continue,
              icon: Icon(_failed ? Icons.refresh : Icons.auto_awesome),
              label: Text(_failed ? l10n.importRetry : l10n.clarifyContinue),
            ),
          if (_error case final e?) ...[
            const SizedBox(height: 16),
            Text(e, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy
                ? null
                : () async {
                    final router = GoRouter.of(context);
                    await ref.read(importServiceProvider).discard(widget.draftId);
                    router.go('/');
                  },
            child: Text(l10n.reviewCancelImport),
          ),
        ],
      ),
    );
  }
}
