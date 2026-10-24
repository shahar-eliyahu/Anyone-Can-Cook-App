import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'assistant_controller.dart';
import 'assistant_models.dart';

/// Remy's conversation sheet in the cooking screen: typed questions and commands, quick
/// chips, and approval cards. (A microphone joins this sheet in Phase 3D; it sends the
/// same [AssistantInput] with `modality: voice`.)
Future<void> showAssistantSheet(BuildContext context, String sessionId) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: AssistantPanel(sessionId: sessionId),
        ),
      ),
    );

class AssistantPanel extends ConsumerStatefulWidget {
  const AssistantPanel({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<AssistantPanel> createState() => _AssistantPanelState();
}

class _AssistantPanelState extends ConsumerState<AssistantPanel> {
  final _text = TextEditingController();

  AssistantController get _controller => ref.read(assistantControllerProvider(widget.sessionId).notifier);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _text.clear();
    _controller.send(AssistantInput(text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = ref.watch(assistantControllerProvider(widget.sessionId));
    final pending = s.pending;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.remyTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                reverse: true,
                children: [
                  if (s.busy) Padding(padding: const EdgeInsets.all(8), child: Text(l10n.remyThinking)),
                  if (pending != null)
                    Card(
                      color: theme.colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 8,
                          children: [
                            Text(l10n.remyProposalTitle, style: theme.textTheme.titleSmall),
                            Row(
                              spacing: 8,
                              children: [
                                Expanded(
                                  child: FilledButton(onPressed: s.busy ? null : _controller.approve, child: Text(l10n.remyApprove)),
                                ),
                                Expanded(
                                  child: OutlinedButton(onPressed: s.busy ? null : _controller.reject, child: Text(l10n.remyReject)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  for (final m in s.messages.reversed) _Bubble(message: m),
                  if (s.messages.isEmpty) _Bubble(message: ChatMessage(fromUser: false, textHe: l10n.remyGreeting)),
                ],
              ),
            ),
            Wrap(
              spacing: 6,
              children: [
                for (final chip in [l10n.remyChipNow, l10n.remyChipTime, l10n.remyChipHelp])
                  ActionChip(label: Text(chip), onPressed: s.busy ? null : () => _send(chip)),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    enabled: !s.busy,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                    maxLength: 500,
                    decoration: InputDecoration(hintText: l10n.remyHint, counterText: ''),
                  ),
                ),
                IconButton(
                  tooltip: l10n.remySend,
                  onPressed: s.busy ? null : () => _send(_text.text),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: message.fromUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        decoration: BoxDecoration(
          color: message.fromUser ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message.textHe),
      ),
    );
  }
}
