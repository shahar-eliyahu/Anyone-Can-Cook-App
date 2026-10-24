import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/motion_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'assistant_controller.dart';
import 'assistant_models.dart';
import 'remy_widgets.dart';
import 'voice_controller.dart';

/// Remy's conversation (docs/DESIGN.md §6.3): typed or spoken requests through the same
/// pipeline, quick chips, approval for anything that needs a "yes", and clear listening /
/// thinking / speaking states. [listen] opens it already listening.
Future<void> showAssistantSheet(BuildContext context, RemyScope scope, {bool listen = false}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          // Taller with large text, so the conversation keeps some room.
          height: MediaQuery.sizeOf(context).height * (MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 0.94 : 0.78),
          child: AssistantPanel(scope: scope, listenOnOpen: listen),
        ),
      ),
    );

class AssistantPanel extends ConsumerStatefulWidget {
  const AssistantPanel({super.key, required this.scope, this.listenOnOpen = false});

  final RemyScope scope;
  final bool listenOnOpen;

  @override
  ConsumerState<AssistantPanel> createState() => _AssistantPanelState();
}

class _AssistantPanelState extends ConsumerState<AssistantPanel> {
  final _text = TextEditingController();

  AssistantController get _controller => ref.read(assistantControllerProvider(widget.scope).notifier);
  VoiceController get _voice => ref.read(voiceControllerProvider(widget.scope).notifier);

  @override
  void initState() {
    super.initState();
    if (widget.listenOnOpen) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _voice.listen() : null);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _text.clear();
    _voice.cancel(); // typing takes over from the microphone
    _controller.send(AssistantInput(text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = ref.watch(assistantControllerProvider(widget.scope));
    final pending = s.pending;
    final voice = ref.watch(voiceControllerProvider(widget.scope));
    final canListen = _voice.available;
    final voiceActive = voice.phase != VoicePhase.idle;
    final session = widget.scope.isSession;
    final chips = session
        ? [l10n.remyChipNow, l10n.remyChipTime, l10n.remyChipHelp]
        : [l10n.remyPrepChipFirst, l10n.remyPrepChipTime, l10n.remyPrepChipMissing];

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: who this is and how to talk to him.
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.s, Space.s),
            child: Row(
              spacing: Space.m,
              children: [
                const RemyAvatar(size: 44),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(header: true, child: Text(l10n.remyTitle, style: theme.textTheme.titleLarge)),
                      Text(
                        l10n.remySheetSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.remyClose,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // The conversation, newest at the bottom.
          Expanded(
            child: ListView(
              reverse: true,
              padding: const EdgeInsets.fromLTRB(Space.page, Space.m, Space.page, Space.m),
              children: [
                if (s.busy) const _ThinkingBubble(),
                if (pending != null)
                  Appear(
                    child: Card(
                      color: theme.colorScheme.secondaryContainer,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card)),
                      child: Padding(
                        padding: const EdgeInsets.all(Space.m + 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: Space.s,
                          children: [
                            Row(
                              spacing: Space.s,
                              children: [
                                Icon(Icons.help_outline_rounded, color: context.palette.wood, size: 20),
                                Text(
                                  l10n.remyProposalTitle,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              spacing: Space.s,
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: s.busy ? null : _controller.approve,
                                    child: Text(l10n.remyApprove),
                                  ),
                                ),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: s.busy ? null : _controller.reject,
                                    child: Text(l10n.remyReject),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                for (final (i, m) in s.messages.reversed.indexed)
                  _Bubble(key: ValueKey(s.messages.length - i), message: m),
                if (s.messages.isEmpty)
                  _Bubble(
                    message: ChatMessage(fromUser: false, textHe: session ? l10n.remyGreeting : l10n.remyPrepGreeting),
                  ),
              ],
            ),
          ),
          // Voice state, notes and quick requests: scrolls rather than crowding out the input.
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Space.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedSize(
                    duration: Motion.of(context, Motion.medium),
                    curve: Motion.standard,
                    child: voiceActive
                        ? _VoiceStatus(voice: voice, onStop: _voice.cancel)
                        : const SizedBox(width: double.infinity),
                  ),
                  if (voice.messageHe != null && !voiceActive)
                    NoteBanner(voice.messageHe!, kind: NoteKind.warning, icon: Icons.mic_off_outlined),
                  // Without a Hebrew voice, spoken requests still work; the answers stay on screen.
                  if (voice.hebrewVoice == false)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.xs),
                      child: Text(
                        l10n.voiceNoHebrewVoice,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  // Wrapped, not scrolled: every quick request stays in view.
                  Wrap(
                    spacing: Space.s,
                    runSpacing: Space.xs,
                    children: [
                      for (final chip in chips)
                        ActionChip(label: Text(chip), onPressed: s.busy ? null : () => _send(chip)),
                    ],
                  ),
                  // Voice options sit on the microphone's side, always in view.
                  if (canListen)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: FilterChip(
                        avatar: voice.continuous ? null : const Icon(Icons.all_inclusive_rounded, size: 18),
                        label: Text(l10n.voiceContinuous),
                        selected: voice.continuous,
                        onSelected: _voice.setContinuous,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Input: type or speak.
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.m),
            child: Row(
              spacing: Space.s,
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    enabled: !s.busy,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                    maxLength: 500,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: l10n.remyHint,
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(26)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(26),
                        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(26),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                      ),
                      suffixIcon: IconButton(
                        tooltip: l10n.remySend,
                        onPressed: s.busy ? null : () => _send(_text.text),
                        icon: const Icon(Icons.send_rounded),
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                if (canListen)
                  BreathingRing(
                    active: voice.phase == VoicePhase.listening,
                    child: IconButton.filled(
                      tooltip: l10n.voiceMic,
                      iconSize: 28,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(56, 56),
                        backgroundColor: voiceActive ? AppColors.onSoftBlue : theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      // Tapping while listening finishes the utterance; while speaking, stops Remy.
                      onPressed: s.busy && !voiceActive ? null : _voice.toggle,
                      icon: Icon(switch (voice.phase) {
                        VoicePhase.speaking => Icons.stop_rounded,
                        VoicePhase.idle => Icons.mic_none_rounded,
                        _ => Icons.mic_rounded,
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What the microphone is doing right now, with one way to stop.
class _VoiceStatus extends StatelessWidget {
  const _VoiceStatus({required this.voice, required this.onStop});

  final VoiceState voice;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (IconData icon, String text) = switch (voice.phase) {
      VoicePhase.preparing => (Icons.mic_none_rounded, l10n.voicePreparing),
      VoicePhase.listening => (
        Icons.mic_rounded,
        voice.partial.isEmpty ? l10n.voiceListening : '${l10n.voiceListening} ${voice.partial}',
      ),
      VoicePhase.processing => (Icons.hourglass_top_rounded, '${l10n.voiceProcessing} ${voice.partial}'),
      VoicePhase.speaking => (Icons.graphic_eq_rounded, l10n.voiceSpeaking),
      VoicePhase.idle => (Icons.mic_none_rounded, ''),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: Space.s),
        padding: const EdgeInsetsDirectional.fromSTEB(Space.m, Space.xs, Space.xs, Space.xs),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(Radii.input),
        ),
        child: Row(
          spacing: Space.s,
          children: [
            Icon(icon, color: AppColors.primary),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
            if (voice.phase == VoicePhase.processing) const ThinkingDots(size: 6),
            TextButton.icon(onPressed: onStop, icon: const Icon(Icons.stop_rounded), label: Text(l10n.voiceStop)),
          ],
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Semantics(
      label: AppLocalizations.of(context).remyThinking,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: Space.xs),
        padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m + 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: _bubbleRadius(fromUser: false),
        ),
        child: const ThinkingDots(),
      ),
    ),
  );
}

BorderRadiusGeometry _bubbleRadius({required bool fromUser}) => BorderRadiusDirectional.only(
  topStart: const Radius.circular(18),
  topEnd: const Radius.circular(18),
  bottomStart: Radius.circular(fromUser ? 18 : 4),
  bottomEnd: Radius.circular(fromUser ? 4 : 18),
);

class _Bubble extends StatelessWidget {
  const _Bubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = message.fromUser;
    return Appear(
      child: Align(
        alignment: user ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: Space.xs),
          padding: const EdgeInsets.symmetric(horizontal: Space.m + 2, vertical: Space.s + 2),
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
          decoration: BoxDecoration(
            color: user ? scheme.surfaceContainerHigh : scheme.primaryContainer,
            borderRadius: _bubbleRadius(fromUser: user),
          ),
          child: Text(
            user ? message.textHe : tidyHe(message.textHe),
            style: theme.textTheme.bodyLarge?.copyWith(color: user ? scheme.onSurface : scheme.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}
