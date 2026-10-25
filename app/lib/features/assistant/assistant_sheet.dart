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

/// Talking to Remy (docs/DESIGN.md §15). [listen]: open in voice mode and start listening
/// (cooking); otherwise text mode with the input focused (before cooking). [command] is
/// answered at once (what followed "היי רמי"); [handsFree] closes the sheet by itself after he
/// answered, so cooking continues without touching the screen.
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
          height: MediaQuery.sizeOf(context).height * (MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 0.9 : 0.66),
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

/// Problems that mean voice can't work right now: the sheet switches to typing by itself.
const _voiceBlocked = {VoiceIssue.permissionDenied, VoiceIssue.recognitionUnavailable, VoiceIssue.hebrewUnsupported, VoiceIssue.network};

class AssistantPanel extends ConsumerStatefulWidget {
  const AssistantPanel({
    super.key,
    required this.scope,
    this.listenOnOpen = false,
    this.command,
    this.handsFree = false,
    this.embedded = false,
    this.onOpenRecipe,
  });

  final RemyScope scope;
  final bool listenOnOpen;
  final String? command;
  final bool handsFree;

  /// On a screen of its own (creating a recipe): the screen's back arrow closes it.
  final bool embedded;

  /// Recipe creation: opens the draft Remy created.
  final void Function(String recipeId)? onOpenRecipe;

  @override
  ConsumerState<AssistantPanel> createState() => _AssistantPanelState();
}

class _AssistantPanelState extends ConsumerState<AssistantPanel> {
  /// How long a hands-free sheet stays after Remy answered.
  static const autoCloseAfter = Duration(seconds: 4);

  final _text = TextEditingController();

  /// Voice mode (big microphone) or text mode (input field). The conversation is the same.
  late bool _voiceMode = (widget.listenOnOpen || widget.command != null) && _voice.available;
  bool _touched = false;
  Timer? _autoClose;

  AssistantController get _controller => ref.read(assistantControllerProvider(widget.scope).notifier);
  VoiceController get _voice => ref.read(voiceControllerProvider(widget.scope).notifier);

  @override
  void initState() {
    super.initState();
    if (!_voiceMode) return;
    // Starts while the sheet slides in: the short wait lets the microphone be released by
    // whoever had it (hands-free listening) without the cook noticing.
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      widget.command != null ? _voice.respondTo(widget.command!) : _voice.listen();
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

  void _toText() {
    _voice.cancel();
    setState(() => _voiceMode = false);
  }

  void _toVoice() {
    FocusScope.of(context).unfocus();
    setState(() => _voiceMode = true);
    _voice.listen();
  }

  /// Hands-free: once Remy is done (nothing pending, nobody touching the screen), the sheet
  /// steps away and "היי רמי" listens again.
  void _maybeAutoClose(VoiceState voice, AssistantState s) {
    _autoClose?.cancel();
    if (!widget.handsFree || _touched) return;
    final done = voice.phase == VoicePhase.idle && !s.busy && s.pending == null;
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
    ref.listen(voiceControllerProvider(widget.scope), (_, v) {
      _maybeAutoClose(v, ref.read(assistantControllerProvider(widget.scope)));
      if (_voiceMode && _voiceBlocked.contains(v.issue)) setState(() => _voiceMode = false);
    });
    ref.listen(assistantControllerProvider(widget.scope), (_, a) => _maybeAutoClose(ref.read(voiceControllerProvider(widget.scope)), a));
    final canListen = _voice.available;
    final pending = s.pending;
    final listening = voice.phase == VoicePhase.listening;
    final hearing = voice.partial.isNotEmpty && (listening || voice.phase == VoicePhase.processing);
    // A pending question is shown in its own card with "כן" / "לא", not repeated as a bubble.
    final asked = pending != null && s.messages.isNotEmpty && !s.messages.last.fromUser;
    final shown = asked ? s.messages.sublist(0, s.messages.length - 1) : s.messages;
    final latestRecipe = shown.reversed.toList().indexWhere((m) => m.recipeId != null);

    final status = switch (voice.phase) {
      VoicePhase.preparing => l10n.voicePreparing,
      VoicePhase.listening => l10n.voiceListening,
      VoicePhase.processing => l10n.voiceProcessing,
      VoicePhase.speaking => l10n.voiceSpeaking,
      VoicePhase.idle when s.busy => l10n.remyThinking,
      VoicePhase.idle => _voiceMode ? l10n.voiceTapToSpeak : l10n.remyRole,
    };
    final quiet = voice.phase == VoicePhase.idle && !s.busy;

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
            // Remy, small, and what he is doing.
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(Space.page, 0, Space.s, Space.s),
              child: Row(
                spacing: Space.m,
                children: [
                  BreathingRing(active: listening, child: const RemyAvatar(size: 40)),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(header: true, child: Text(l10n.remyOpen, style: theme.textTheme.titleLarge)),
                          Text(
                            status,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: quiet ? theme.colorScheme.onSurfaceVariant : AppColors.primary,
                              fontWeight: quiet ? null : FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (s.busy || voice.phase == VoicePhase.processing) const ThinkingDots(size: 6),
                  if (!widget.embedded)
                    IconButton(
                      tooltip: l10n.remyClose,
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // The conversation about this recipe.
            Expanded(
              child: shown.isEmpty && pending == null && !hearing
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(Space.xl),
                        child: Text(
                          widget.scope.isCreation ? l10n.createEmptyHint : l10n.remyEmptyHint,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  : ListView(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(Space.page, Space.m, Space.page, Space.m),
                      children: [
                        if (pending != null)
                          _ConfirmCard(question: pending.answerHe, busy: s.busy, voice: canListen, controller: _controller),
                        // What is being heard, as a faint bubble of its own.
                        if (hearing) _Bubble(message: ChatMessage(fromUser: true, textHe: voice.partial), draft: true),
                        for (final (i, m) in shown.reversed.indexed) ...[
                          // Under Remy's latest message: the dishes he offered, and the draft he made.
                          if (i == 0 && !m.fromUser && m.options.isNotEmpty && !s.busy && pending == null)
                            _Options(options: m.options, onChoose: _send),
                          if (m.recipeId case final id? when widget.onOpenRecipe != null && i == latestRecipe)
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: Space.s),
                                child: FilledButton.tonalIcon(
                                  onPressed: () => widget.onOpenRecipe!(id),
                                  icon: const Icon(Icons.menu_book_rounded),
                                  label: Text(l10n.createOpenRecipe),
                                ),
                              ),
                            ),
                          _Bubble(key: ValueKey(shown.length - i), message: m),
                        ],
                      ],
                    ),
            ),
            if (voice.messageHe != null && voice.phase == VoicePhase.idle)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.page),
                child: NoteBanner(voice.messageHe!, kind: NoteKind.warning, icon: Icons.mic_off_outlined),
              ),
            // Without a Hebrew voice, spoken requests still work; the answers stay on screen.
            if (voice.hebrewVoice == false && _voiceMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.page),
                child: Text(
                  l10n.voiceNoHebrewVoice,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            AnimatedSwitcher(
              duration: Motion.of(context, Motion.medium),
              child: _voiceMode ? _voiceControls(l10n, theme, voice, s) : _textInput(l10n, theme, s, canListen),
            ),
          ],
        ),
      ),
    );
  }

  /// Voice mode: one big microphone; typing on one side, stop on the other.
  Widget _voiceControls(AppLocalizations l10n, ThemeData theme, VoiceState voice, AssistantState s) {
    final active = voice.phase != VoicePhase.idle;
    return Padding(
      key: const ValueKey('voice'),
      padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.m),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(onPressed: _toText, icon: const Icon(Icons.keyboard_outlined), label: Text(l10n.remyTypeInstead)),
            ),
          ),
          BreathingRing(
            active: voice.phase == VoicePhase.listening,
            child: IconButton.filled(
              tooltip: l10n.voiceMic,
              iconSize: 32,
              style: IconButton.styleFrom(
                minimumSize: const Size(68, 68),
                backgroundColor: active ? AppColors.onSoftBlue : theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              // Tapping while listening finishes the utterance; while speaking, stops Remy.
              onPressed: s.busy && !active ? null : _voice.toggle,
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
              child: active
                  ? TextButton.icon(onPressed: _voice.cancel, icon: const Icon(Icons.stop_rounded), label: Text(l10n.voiceStop))
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  /// Text mode: the input, focused; a small microphone to talk instead.
  Widget _textInput(AppLocalizations l10n, ThemeData theme, AssistantState s, bool canListen) => Padding(
        key: const ValueKey('text'),
        padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.m),
        child: Row(
          spacing: Space.s,
          children: [
            Expanded(
              child: TextField(
                controller: _text,
                enabled: !s.busy,
                autofocus: true,
                // A one-line keyboard: Enter sends (long messages still wrap to 3 lines).
                keyboardType: TextInputType.text,
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
              IconButton.filledTonal(
                tooltip: l10n.voiceMic,
                onPressed: s.busy ? null : _toVoice,
                icon: const Icon(Icons.mic_none_rounded),
              ),
          ],
        ),
      );
}

/// The dishes Remy offered (recipe creation): a tap answers with that dish.
class _Options extends StatelessWidget {
  const _Options({required this.options, required this.onChoose});

  final List<String> options;
  final void Function(String) onChoose;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Space.s),
        child: Wrap(
          spacing: Space.s,
          runSpacing: Space.s,
          children: [
            for (final o in options)
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(48, 44)),
                onPressed: () => onChoose(o),
                child: Text(tidyHe(o)),
              ),
          ],
        ),
      );
}

/// A question Remy asked: "כן" / "לא" (or say it).
class _ConfirmCard extends StatelessWidget {
  const _ConfirmCard({required this.question, required this.busy, required this.voice, required this.controller});

  final String question;
  final bool busy;
  final bool voice;
  final AssistantController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Appear(
      child: Card(
        color: theme.colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(Space.m + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Space.s,
            children: [
              Text(l10n.remyProposalTitle, style: theme.textTheme.labelLarge?.copyWith(color: context.palette.wood)),
              Text(tidyHe(question), style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
              Row(
                spacing: Space.s,
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      onPressed: busy ? null : controller.approve,
                      child: Text(l10n.remyApprove),
                    ),
                  ),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      onPressed: busy ? null : controller.reject,
                      child: Text(l10n.remyReject),
                    ),
                  ),
                ],
              ),
              if (voice)
                Text(
                  l10n.remyAnswerHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSecondaryContainer),
                ),
            ],
          ),
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
  const _Bubble({super.key, required this.message, this.draft = false});

  final ChatMessage message;

  /// Still being heard: faint, not part of the conversation yet.
  final bool draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = message.fromUser;
    final bubble = Align(
      alignment: user ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: Space.xs),
        padding: const EdgeInsets.symmetric(horizontal: Space.m + 2, vertical: Space.s + 2),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        decoration: BoxDecoration(
          color: draft ? scheme.surfaceContainerLow : (user ? scheme.surfaceContainerHigh : scheme.primaryContainer),
          border: draft ? Border.all(color: scheme.outlineVariant) : null,
          borderRadius: _bubbleRadius(fromUser: user),
        ),
        child: Text(
          user ? message.textHe : tidyHe(message.textHe),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: draft ? scheme.onSurfaceVariant : (user ? scheme.onSurface : scheme.onPrimaryContainer),
          ),
        ),
      ),
    );
    return draft ? bubble : Appear(child: bubble);
  }
}
