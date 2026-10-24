import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/provenance.dart';

/// "הערכה" chip for values the AI estimated (never shown as recipe facts).
class EstimateBadge extends StatelessWidget {
  const EstimateBadge({super.key, this.note});

  final String? note;

  @override
  Widget build(BuildContext context) => ProvenanceBadge(Provenance.inferred, note: note);
}

/// Where a value came from, for every value that is not from the original recipe.
class ProvenanceBadge extends StatelessWidget {
  const ProvenanceBadge(this.provenance, {super.key, this.note});

  final Provenance provenance;
  final String? note;

  static String? labelFor(AppLocalizations l10n, Provenance p) => switch (p) {
        Provenance.original => null,
        Provenance.inferred => l10n.estimate,
        Provenance.answered => l10n.provenanceAnswered,
        Provenance.reference => l10n.provenanceReference,
        Provenance.user => l10n.provenanceUser,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final label = labelFor(l10n, provenance);
    if (label == null) return const SizedBox.shrink();
    final estimate = provenance.isEstimate;
    // Long-press (the default) so taps reach the tile or button underneath.
    return Tooltip(
      message: note ?? (estimate ? l10n.estimateHint : label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: estimate ? scheme.tertiaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: estimate ? scheme.onTertiaryContainer : scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// [text] followed by a badge saying where the value came from (none for original values).
class ProvenancedText extends StatelessWidget {
  const ProvenancedText(this.text, this.provenance, {super.key, this.note, this.style});

  final String text;
  final Provenance provenance;
  final String? note;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(text, style: style),
          if (provenance != Provenance.original) ProvenanceBadge(provenance, note: note),
        ],
      );
}
