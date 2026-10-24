import 'dart:async';

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
import 'hands_free.dart';
import 'remy_widgets.dart';
import 'voice.dart';
import 'voice_controller.dart';

/// Talking to Remy (docs/DESIGN.md §13): voice first. [listen] opens him already listening (a
/// tap on Remy); [command] is answered at once (what followed "היי רמי"); [handsFree] closes
/// the sheet by itself after he answered, so cooking continues without touching the screen.
Future<void> showAssistantSheet(
  BuildContext context,
  RemyScope scope, {
  bool listen = false,
  String? command,
  bool handsFree = false,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final gate = container.read(remySheetOpenProvider.notifier);
  gate.open(); // hands-free listening steps aside
  try {
    await container.read(speechRecognizerProvider)?.cancel(); // and hands the microphone over
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          // Taller with large text, so the conversation keeps some room.
          height: MediaQuery.sizeOf(context).height * (MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 0.94 : 0.8),
          child: AssistantPanel(scope: scope, listenOnOpen: listen, command: command, handsFree: handsFree),
        ),
      ),
    );
  } finally {
    // The sheet's own listening ends first; then "היי רמי" gets the microphone back.
    if (container.read(remySheetOpenProvider) == 1) await container.read(speechRecognizerProvider)?.cancel();
    await Future<void>.delayed(Motion.medium);
    gate.close();
  }
}

class AssistantPanel extends ConsumerStatefulWidget {
  const AssistantPanel({
    super.key,
    required this.scope,
    this.listenOnOpen = false,
    this.command,
    this.handsFree = false,
  });

  final RemyScope scope;
  final bool listenOnOpen;
  final String? command;
  final bool handsFree;

  @override
  ConsumerState<AssistantPanel> createState() => _AssistantPanelState();
}

class _AssistantPanelState extends ConsumerState<AssistantPanel> {
  /// How long a hands-free sheet stays after Remy answered.
  static const autoCloseAfter = Duration(seconds: 4);

  final _text = TextEditingController();
  late bool _typing = !ref.read(voiceControllerProvider(widget.scope).notifier).available;
  bool _showAll = false;
  bool _touched = false;
  Timer? _autoClose;

  AssistantController get _controller => ref.read(assistantControllerProvider(widget.scope).notifier);
  VoiceController get _voice => ref.read(voiceControllerProvider(widget.scope).notifier);

  @override
  void initState() {
    super.initState();
    // Starts while the sheet slides in: the short wait lets the microphone be released by
    // whoever had it (hands-free listening) without the cook noticing.
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (widget.command != null) {
        _voice.respondTo(widget.command!);
      } else if (widget.listenOnOpen && !_typing) {
        _voice.listen();
      }
    });
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _text.clear();
    _voice.cancel(); // typing takes over from the microphone
    _controller.send(AssistantInput(text));
  }

  void _startTyping() {
    _voice.cancel();
    setState(() => _typing = true);
  }

  /// Hands-free: once Remy is done (nothing pending, nobody touching the screen), the sheet
  /// steps away and "היי רמי" listens again.
  void _maybeAutoClose(VoiceState voice, AssistantState s) {
    _autoClose?.cancel();
    if (!widget.handsFree || _touched) return;
    final done = voice.phase == VoicePhase.idle && !s.busy && s.pending == null && !voice.continuous;
    if (!done) return;
    _autoClose = Timer(autoCloseAfter, () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = ref.watch(assistantControllerProvider(widget.scope));
    final voice = ref.watch(voiceControllerProvider(widget.scope));
    ref.listen(
      voiceControllerProvider(widget.scope),
      (_, v) => _maybeAutoClose(v, ref.read(assistantControllerProvider(widget.scope))),
    );
    ref.listen(
      assistantControllerProvider(widget.scope),
      (_, a) => _maybeAutoClose(ref.read(voiceControllerProvider(widget.scope)), a),
    );
    final canListen = _voice.available;
    final session = widget.scope.isSession;
    final pending = s.pending;
    final chips = session
        ? [l10n.remyChipNow, l10n.remyChipTime, l10n.remyChipHelp]
        : [l10n.remyPrepChipFirst, l10n.remyPrepChipTime, l10n.remyPrepChipMissing];
    // A pending question is shown in its own card with "כן" / "לא", not repeated as a bubble.
    final asked = pending != null && s.messages.isNotEmpty && !s.messages.last.fromUser;
    final history = asked ? s.messages.sublist(0, s.messages.length - 1) : s.messages;
    final shown = _showAll || history.length <= 2 ? history : history.sublist(history.length - 2);

    final (String headline, String? subline) = switch (voice.phase) {
      VoicePhase.preparing => (l10n.voicePreparing, null),
      VoicePhase.listening => (l10n.voiceListening, voice.partial.isEmpty ? null : voice.partial),
      VoicePhase.processing => (l10n.voiceProcessing, voice.partial.isEmpty ? null : voice.partial),
      VoicePhase.speaking => (l10n.voiceSpeaking, null),
      VoicePhase.idle when s.busy => (l10n.remyThinking, null),
      VoicePhase.idle => (l10n.remyOpen, canListen && !_typing ? l10n.voiceTapToSpeak : l10n.remyRole),
    };
    final transcript = voice.partial.isNotEmpty && voice.phase != VoicePhase.idle;
    // Typing or reading a note: a slim header leaves room for the conversation.
    final compact = _typing || (voice.phase == VoicePhase.idle && voice.messageHe != null);

    return Listener(
      // Any touch means the cook is here: a hands-free sheet then stays open.
      onPointerDown: (_) {
        _touched = true;
        _autoClose?.cancel();
      },
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Who and what: Remy, and what he is doing right now.
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.s, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!compact) const SizedBox(width: 48), // balances the close button: the avatar stays centred
                  if (compact)
                    Expanded(
                      child: Row(
                        spacing: Space.m,
                        children: [
                          const RemyAvatar(size: 40),
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                headline,
                                style: theme.textTheme.titleLarge?.copyWith(color: AppColors.onSoftBlue),
                              ),
                            ),
                          ),
                          if (s.busy) const ThinkingDots(),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: Semantics(
                        liveRegion: true,
                        child: Column(
                          spacing: Space.xs,
                          children: [
                            BreathingRing(
                              active: voice.phase == VoicePhase.listening,
                              child: const RemyAvatar(size: 64),
                            ),
                            Semantics(
                              header: true,
                              child: Text(
                                headline,
                                style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.onSoftBlue),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (voice.phase == VoicePhase.processing || (voice.phase == VoicePhase.idle && s.busy))
                              const ThinkingDots(),
                            if (subline != null)
                              Text(
                                subline,
                                textAlign: TextAlign.center,
                                style: transcript
                                    ? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500)
                                    : theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                          ],
                        ),
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
            // The latest exchange (the rest of the conversation on request, always in view).
            if (history.length > 2)
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  child: Text(_showAll ? l10n.remyHideConversation : l10n.remyShowConversation(history.length)),
                ),
              ),
            Expanded(
              flex: 3,
              child: ListView(
                reverse: true,
                padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.s),
                children: [
                  if (pending != null)
                    Appear(
                      child: Card(
                        color: theme.colorScheme.secondaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(Space.m + 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: Space.s,
                            children: [
                              Text(
                                l10n.remyProposalTitle,
                                style: theme.textTheme.labelLarge?.copyWith(color: context.palette.wood),
                              ),
                              Text(
                                tidyHe(pending.answerHe),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                              Row(
                                spacing: Space.s,
                                children: [
                                  Expanded(
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                                      onPressed: s.busy ? null : _controller.approve,
                                      child: Text(l10n.remyApprove),
                                    ),
                                  ),
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                                      onPressed: s.busy ? null : _controller.reject,
                                      child: Text(l10n.remyReject),
                                    ),
                                  ),
                                ],
                              ),
                              if (canListen)
                                Text(
                                  l10n.remyAnswerHint,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  for (final (i, m) in shown.reversed.indexed)
                    _Bubble(key: ValueKey(s.messages.length - i), message: m),
                  if (s.messages.isEmpty)
                    _Bubble(
                      message: ChatMessage(
                        fromUser: false,
                        textHe: session ? l10n.remyGreeting : l10n.remyPrepGreeting,
                      ),
                    ),
                ],
              ),
            ),
            // Notes and quick requests: they scroll rather than crowd out the input and microphone.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: Space.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (voice.messageHe != null && voice.phase == VoicePhase.idle)
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
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: Space.s,
                      runSpacing: Space.xs,
                      children: [
                        for (final chip in chips)
                          ActionChip(label: Text(chip), onPressed: s.busy ? null : () => _send(chip)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Typing, only when asked for (or when this phone can't listen).
            AnimatedSize(
              duration: Motion.of(context, Motion.medium),
              curve: Motion.standard,
              child: _typing
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, 0),
                      child: TextField(
                        controller: _text,
                        enabled: !s.busy,
                        autofocus: canListen, // chosen on purpose; without a microphone it is simply there
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
                    )
                  : const SizedBox(width: double.infinity),
            ),
            // The microphone in the middle; typing on one side, voice options on the other.
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.m),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: canListen && !_typing
                          ? TextButton.icon(
                              onPressed: _startTyping,
                              icon: const Icon(Icons.keyboard_outlined),
                              label: Text(l10n.remyTypeInstead),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  if (canListen)
                    BreathingRing(
                      active: voice.phase == VoicePhase.listening,
                      child: IconButton.filled(
                        tooltip: l10n.voiceMic,
                        iconSize: 34,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(76, 76),
                          backgroundColor: voice.phase == VoicePhase.idle
                              ? theme.colorScheme.primary
                              : AppColors.onSoftBlue,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        // Tapping while listening finishes the utterance; while speaking, stops Remy.
                        onPressed: s.busy && voice.phase == VoicePhase.idle ? null : _voice.toggle,
                        icon: Icon(switch (voice.phase) {
                          VoicePhase.speaking => Icons.stop_rounded,
                          VoicePhase.idle => Icons.mic_none_rounded,
                          _ => Icons.mic_rounded,
                        }),
                      ),
                    ),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: !canListen
                          ? const SizedBox.shrink()
                          : voice.phase == VoicePhase.idle
                          ? FilterChip(
                              avatar: voice.continuous ? null : const Icon(Icons.all_inclusive_rounded, size: 18),
                              label: Text(l10n.voiceContinuous),
                              selected: voice.continuous,
                              onSelected: _voice.setContinuous,
                            )
                          : TextButton.icon(
                              onPressed: _voice.cancel,
                              icon: const Icon(Icons.stop_rounded),
                              label: Text(l10n.voiceStop),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
          decoration: BoxDecoration(
            color: user ? scheme.surfaceContainerHigh : scheme.primaryContainer,
            borderRadius: _bubbleRadius(fromUser: user),
          ),
          child: Text(
            user ? message.textHe : tidyHe(message.textHe),
            style: (user ? theme.textTheme.bodyLarge : theme.textTheme.titleMedium)?.copyWith(
              color: user ? scheme.onSurface : scheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
