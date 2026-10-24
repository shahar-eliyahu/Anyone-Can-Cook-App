import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../import/import_errors.dart';
import 'preparation.dart';
import 'preparation_service.dart';

/// "אין לכם X?": a local answer at once when the table has one, otherwise (or on
/// request) one server call with what the cook has instead. Nothing changes until the
/// cook taps "להשתמש בזה".
Future<void> showSubstitutionSheet(
  BuildContext context, {
  required PrepView view,
  required ItemKind kind,
  required String targetId,
  required String name,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: _SubstitutionSheet(view: view, kind: kind, targetId: targetId, name: name),
      ),
    );

class _SubstitutionSheet extends ConsumerStatefulWidget {
  const _SubstitutionSheet({required this.view, required this.kind, required this.targetId, required this.name});

  final PrepView view;
  final ItemKind kind;
  final String targetId;
  final String name;

  @override
  ConsumerState<_SubstitutionSheet> createState() => _SubstitutionSheetState();
}

class _SubstitutionSheetState extends ConsumerState<_SubstitutionSheet> {
  final _note = TextEditingController();
  SubstitutionProposal? _proposal;
  bool _busy = false;
  String? _error;

  PreparationService get _service => ref.read(preparationServiceProvider);

  @override
  void initState() {
    super.initState();
    _proposal = _service.proposeLocally(widget.view, widget.kind, widget.targetId);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final p = await _service.propose(widget.view, widget.kind, widget.targetId, noteHe: _note.text);
      if (mounted) setState(() => _proposal = p);
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = importErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept(SubstitutionProposal p) async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await _service.accept(widget.view.row.id, widget.kind, widget.targetId, p);
      navigator.pop();
    } on SubstitutionFailed {
      if (mounted) setState(() => _error = l10n.substitutionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = _proposal;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(l10n.sheetTitle(widget.name), style: theme.textTheme.titleLarge),
            if (p != null) ...[
              _ProposalCard(proposal: p),
              if (p.canApply) ...[
                FilledButton(onPressed: _busy ? null : () => _accept(p), child: Text(l10n.useThis)),
                TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: Text(l10n.noThanks)),
              ] else
                FilledButton(onPressed: () => Navigator.pop(context), child: Text(l10n.understood)),
              if (p.source == SubstitutionSource.local || !p.canApply)
                TextButton(
                  onPressed: _busy ? null : () => setState(() => _proposal = null),
                  child: Text(l10n.sheetTryOther),
                ),
            ] else ...[
              TextField(
                controller: _note,
                enabled: !_busy,
                decoration: InputDecoration(hintText: l10n.sheetNoteHint, border: const OutlineInputBorder()),
              ),
              if (_busy)
                Row(
                  spacing: 12,
                  children: [
                    const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    Text(l10n.sheetSearching),
                  ],
                )
              else
                FilledButton(onPressed: _find, child: Text(l10n.sheetFind)),
            ],
            if (_error case final e?) Text(e, style: TextStyle(color: theme.colorScheme.error)),
          ],
        ),
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({required this.proposal});

  final SubstitutionProposal proposal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = proposal;
    final (IconData icon, String title) = switch (p.verdict) {
      'works' => (Icons.check_circle_outline, l10n.verdictWorks),
      'changes_result' => (Icons.info_outline, l10n.verdictChanges),
      'not_recommended' => (Icons.warning_amber, l10n.verdictNotRecommended),
      _ => (Icons.block, l10n.verdictNone),
    };
    final amount = p.ops
        .where((o) => o['op'] == 'replace_ingredient' && o['quantity'] != null)
        .map((o) => (o['quantity'] as Map)['display'] as String)
        .firstOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Row(spacing: 8, children: [Icon(icon), Expanded(child: Text(title, style: theme.textTheme.titleMedium))]),
            if (p.replacementNameHe case final r?) Text(amount == null ? r : '$r — $amount', style: theme.textTheme.titleSmall),
            Text(p.explanationHe),
            if (p.effectsHe case final e?) Text(e, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
