import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets/components.dart';
import '../../l10n/app_localizations.dart';
import 'hands_free.dart';
import 'voice.dart';

/// The hands-free choice ("היי רמי" while cooking), the same saved preference wherever it is
/// shown: a quiet card in preparation, a row in settings. Turning it on asks for the
/// microphone first; if that is refused, it stays off and says why.
class HandsFreeChoice extends ConsumerStatefulWidget {
  const HandsFreeChoice({super.key, this.compact = false});

  /// A plain row (settings) instead of the preparation card.
  final bool compact;

  @override
  ConsumerState<HandsFreeChoice> createState() => _HandsFreeChoiceState();
}

class _HandsFreeChoiceState extends ConsumerState<HandsFreeChoice> {
  bool _busy = false;

  Future<void> _set(bool on) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      if (on) {
        final problem = await turnOnHandsFree(ref);
        if (problem != null) messenger.showMessage(problem);
      } else {
        await ref.read(handsFreePreferenceProvider.notifier).set(false);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(speechRecognizerProvider) == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final on = ref.watch(handsFreePreferenceProvider).value ?? false;
    final tile = SwitchListTile(
      value: on,
      onChanged: _busy ? null : _set,
      secondary: Icon(Icons.record_voice_over_outlined, color: on ? AppColors.primary : theme.colorScheme.onSurfaceVariant),
      title: Text(
        widget.compact ? l10n.handsFreeSettingTitle : l10n.handsFreePrepTitle,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(widget.compact ? l10n.handsFreeSettingBody : l10n.handsFreePrepBody),
    );
    if (widget.compact) return tile;
    return Material(
      color: on ? theme.colorScheme.primaryContainer.withValues(alpha: 0.6) : theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(Radii.input),
      clipBehavior: Clip.antiAlias,
      child: tile,
    );
  }
}
