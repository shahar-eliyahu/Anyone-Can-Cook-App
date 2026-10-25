import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'assistant_controller.dart';
import 'assistant_models.dart';
import 'voice.dart';

enum VoicePhase { idle, preparing, listening, processing, speaking }

class VoiceState {
  const VoiceState({
    this.phase = VoicePhase.idle,
    this.partial = '',
    this.messageHe,
    this.issue,
    this.hebrewVoice,
  });

  final VoicePhase phase;

  /// What has been heard so far in this utterance.
  final String partial;

  /// A friendly note when voice can't be used (permission, no Hebrew, offline…).
  final String? messageHe;

  /// Why the last attempt to listen failed (the sheet falls back to typing when voice can't work).
  final VoiceIssue? issue;

  /// Null until checked; false when the phone has no Hebrew voice (replies stay text).
  final bool? hebrewVoice;

  VoiceState copyWith({
    VoicePhase? phase,
    String? partial,
    String? messageHe,
    VoiceIssue? issue,
    bool clearMessage = false,
    bool? hebrewVoice,
  }) =>
      VoiceState(
        phase: phase ?? this.phase,
        partial: partial ?? this.partial,
        messageHe: clearMessage ? null : messageHe ?? this.messageHe,
        issue: clearMessage ? null : issue ?? this.issue,
        hebrewVoice: hebrewVoice ?? this.hebrewVoice,
      );
}

/// Talking with Remy (Phase 3D, DECISIONS #82): listen → the same Remy pipeline as typed text →
/// read the reply aloud → listen once more for a follow-up, like a conversation. The first
/// silence ends the turn quietly; nothing listens after that until the cook asks (a tap, or
/// "היי רמי" in hands-free cooking). Uses the phone's own speech services; every problem
/// becomes a friendly message and typing keeps working.
class VoiceController extends Notifier<VoiceState> {
  VoiceController(this.scope);

  final RemyScope scope;

  /// Follow-up listening in a row, so even a long exchange ends by itself.
  static const maxFollowUps = 6;
  int _followUps = 0;

  /// This conversation is holding the microphone right now (read where `state` can't be).
  bool _usingMic = false;

  @override
  VoiceState build() {
    // Closing the sheet ends the conversation (no listening in the background).
    final recognizer = ref.read(speechRecognizerProvider);
    final tts = ref.read(speechSynthesizerProvider);
    ref.onDispose(() {
      // Only this conversation's own listening; the microphone may already be hands-free's.
      if (_usingMic) recognizer?.cancel();
      tts.stop();
    });
    return const VoiceState();
  }

  AppLocalizations get _l10n => lookupAppLocalizations(const Locale('he'));
  SpeechRecognizer? get _recognizer => ref.read(speechRecognizerProvider);
  SpeechSynthesizer get _tts => ref.read(speechSynthesizerProvider);

  bool get available => _recognizer != null;

  /// The microphone button: start listening, or stop what is happening now.
  Future<void> toggle() async {
    switch (state.phase) {
      case VoicePhase.idle:
        await listen();
      case VoicePhase.listening:
        await _recognizer?.stop(); // what was heard becomes the utterance
      case VoicePhase.speaking:
        state = state.copyWith(phase: VoicePhase.idle);
        await _tts.stop();
      case VoicePhase.preparing || VoicePhase.processing:
        break;
    }
  }

  /// Switching to typing (or closing the sheet): drop the utterance and stop speaking.
  Future<void> cancel() async {
    if (state.phase == VoicePhase.idle) return;
    state = state.copyWith(phase: VoicePhase.idle, partial: '');
    await _recognizer?.cancel();
    await _tts.stop();
  }

  /// Listens for one utterance. [followUp]: right after Remy answered; silence then simply
  /// ends the conversation turn (no "לא שמעתי").
  Future<void> listen({bool followUp = false}) async {
    final recognizer = _recognizer;
    if (recognizer == null || state.phase != VoicePhase.idle) return;
    if (!followUp) _followUps = 0;
    state = state.copyWith(phase: VoicePhase.preparing, partial: '', clearMessage: true);
    try {
      await recognizer.prepare();
      final voice = await _tts.prepare();
      if (!_active) return;
      state = state.copyWith(phase: VoicePhase.listening, hebrewVoice: voice);
      _usingMic = true;
      Future<String> once() => recognizer.listenOnce(onPartial: (p) {
            if (_active) state = state.copyWith(partial: p);
          });
      String text;
      try {
        try {
          text = (await once()).trim();
        } on VoiceException catch (e) {
          // The recognizer may still be letting go of a previous session (hands-free had it a
          // moment ago): one quiet retry before telling the cook.
          if (e.issue != VoiceIssue.other || !_active) rethrow;
          await Future<void>.delayed(const Duration(milliseconds: 500));
          if (!_active) return;
          text = (await once()).trim();
        }
      } finally {
        _usingMic = false;
      }
      if (!_active) return; // cancelled while listening
      if (text.isEmpty) {
        if (followUp) {
          state = state.copyWith(phase: VoicePhase.idle, partial: ''); // the cook is done for now
        } else {
          _stop(VoiceIssue.noSpeech);
        }
        return;
      }
      await _respond(text, voice);
    } on VoiceException catch (e) {
      if (ref.mounted) _stop(e.issue);
    }
  }

  /// Hands-free: what the cook said right after "היי רמי" is answered at once, without
  /// listening again first. An empty command just listens.
  Future<void> respondTo(String transcript) async {
    final text = transcript.trim();
    if (text.isEmpty) return listen();
    if (state.phase != VoicePhase.idle) return;
    state = state.copyWith(phase: VoicePhase.processing, partial: text, clearMessage: true);
    final voice = state.hebrewVoice ?? await _tts.prepare();
    if (!_active) return;
    state = state.copyWith(hebrewVoice: voice);
    try {
      await _respond(text, voice);
    } on VoiceException catch (e) {
      if (ref.mounted) _stop(e.issue);
    }
  }

  Future<void> _respond(String text, bool voice) async {
    state = state.copyWith(phase: VoicePhase.processing, partial: text, clearMessage: true);
    final reply = await ref.read(assistantControllerProvider(scope).notifier).sendSpoken(text);
    if (!_active) return;
    if (reply != null && voice) {
      state = state.copyWith(phase: VoicePhase.speaking);
      await _tts.speak(reply.speechHe);
      if (!_active) return; // stopped while speaking
    }
    state = state.copyWith(phase: VoicePhase.idle, partial: '');
    // A spoken exchange continues by voice: Remy listens once more (always for the answer to
    // a question he asked, "לסמן…?"). A long exchange still ends after [maxFollowUps].
    final asked = ref.read(assistantControllerProvider(scope)).pending != null;
    if (asked || _followUps < maxFollowUps) {
      _followUps++;
      await listen(followUp: true);
    }
  }

  /// Still mounted and not stopped/cancelled meanwhile.
  bool get _active => ref.mounted && state.phase != VoicePhase.idle;

  void _stop(VoiceIssue issue) {
    state = state.copyWith(phase: VoicePhase.idle, partial: '', messageHe: messageFor(issue), issue: issue);
  }

  String messageFor(VoiceIssue issue) => switch (issue) {
        VoiceIssue.permissionDenied => _l10n.voicePermissionDenied,
        VoiceIssue.recognitionUnavailable => _l10n.voiceUnavailable,
        VoiceIssue.hebrewUnsupported => _l10n.voiceHebrewUnsupported,
        VoiceIssue.network => _l10n.voiceNetwork,
        VoiceIssue.noSpeech => _l10n.voiceNoSpeech,
        VoiceIssue.other => _l10n.voiceError,
      };
}

final voiceControllerProvider =
    NotifierProvider.autoDispose.family<VoiceController, VoiceState, RemyScope>(VoiceController.new);
