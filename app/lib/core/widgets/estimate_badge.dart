import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/provenance.dart';

/// "הערכה" chip for values the AI estimated (never shown as recipe facts).
class EstimateBadge extends StatelessWidget {
  const EstimateBadge({super.key, this.note});

  final String? note;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    // Long-press (the default) so taps reach the tile or button underneath.
    return Tooltip(
      message: note ?? l10n.estimateHint,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          l10n.estimate,
          style: TextStyle(fontSize: 12, color: scheme.onTertiaryContainer),
        ),
      ),
    );
  }
}

/// [text] followed by an estimate badge when [provenance] is an AI estimate.
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
          if (provenance.isEstimate) EstimateBadge(note: note),
        ],
      );
}
