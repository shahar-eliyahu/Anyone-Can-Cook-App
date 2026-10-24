import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'assistant_controller.dart';
import 'voice.dart';

enum VoicePhase { idle, preparing, listening, processing, speaking }

class VoiceState {
  const VoiceState({
    this.phase = VoicePhase.idle,
    this.partial = '',
    this.messageHe,
    this.continuous = false,
    this.hebrewVoice,
  });

  final VoicePhase phase;

  /// What has been heard so far in this utterance.
  final String partial;

  /// A friendly note when voice can't be used (permission, no Hebrew, offline…).
  final String? messageHe;

  /// "שיחה רציפה": listen again after Remy answers (hands-free cooking).
  final bool continuous;

  /// Null until checked; false when the phone has no Hebrew voice (replies stay text).
  final bool? hebrewVoice;

  VoiceState copyWith({VoicePhase? phase, String? partial, String? messageHe, bool clearMessage = false, bool? continuous, bool? hebrewVoice}) =>
      VoiceState(
        phase: phase ?? this.phase,
        partial: partial ?? this.partial,
        messageHe: clearMessage ? null : messageHe ?? this.messageHe,
        continuous: continuous ?? this.continuous,
        hebrewVoice: hebrewVoice ?? this.hebrewVoice,
      );
}

/// Talking with Remy (Phase 3D): listen → the same Remy pipeline as typed text → read the
/// reply aloud. Uses the phone's own speech services; every problem becomes a friendly
/// message and typing keeps working.
class VoiceController extends Notifier<VoiceState> {
  VoiceController(this.sessionId);

  final String sessionId;

  /// Continuous mode stops after this many silent turns in a row.
  static const maxSilentTurns = 2;
  int _silentTurns = 0;

  @override
  VoiceState build() {
    // Closing the sheet ends the conversation (no listening in the background).
    final recognizer = ref.read(speechRecognizerProvider);
    final tts = ref.read(speechSynthesizerProvider);
    ref.onDispose(() {
      recognizer?.cancel();
      tts.stop();
    });
    return const VoiceState();
  }

  AppLocalizations get _l10n => lookupAppLocalizations(const Locale('he'));
  SpeechRecognizer? get _recognizer => ref.read(speechRecognizerProvider);
  SpeechSynthesizer get _tts => ref.read(speechSynthesizerProvider);

  bool get available => _recognizer != null;

  void setContinuous(bool on) {
    _silentTurns = 0;
    state = state.copyWith(continuous: on);
  }

  /// The microphone button: start listening, or stop what is happening now.
  Future<void> toggle() async {
    switch (state.phase) {
      case VoicePhase.idle:
        await listen();
      case VoicePhase.listening:
        await _recognizer?.stop(); // what was heard becomes the utterance
      case VoicePhase.speaking:
        state = state.copyWith(phase: VoicePhase.idle, continuous: false);
        await _tts.stop();
      case VoicePhase.preparing || VoicePhase.processing:
        break;
    }
  }

  /// Switching to typing (or closing the sheet): drop the utterance and stop speaking.
  Future<void> cancel() async {
    if (state.phase == VoicePhase.idle) return;
    state = state.copyWith(phase: VoicePhase.idle, partial: '', continuous: false);
    await _recognizer?.cancel();
    await _tts.stop();
  }

  Future<void> listen() async {
    final recognizer = _recognizer;
    if (recognizer == null || state.phase != VoicePhase.idle) return;
    state = state.copyWith(phase: VoicePhase.preparing, partial: '', clearMessage: true);
    try {
      await recognizer.prepare();
      final voice = await _tts.prepare();
      if (!_active) return;
      state = state.copyWith(phase: VoicePhase.listening, hebrewVoice: voice);
      final text = (await recognizer.listenOnce(onPartial: (p) {
        if (_active) state = state.copyWith(partial: p);
      }))
          .trim();
      if (!_active) return; // cancelled while listening
      if (text.isEmpty) {
        _silentTurns++;
        _stop(message: _l10n.voiceNoSpeech, keepContinuous: _silentTurns < maxSilentTurns);
        if (state.continuous) await listen(); // give the cook another chance
        return;
      }
      _silentTurns = 0;
      state = state.copyWith(phase: VoicePhase.processing, partial: text, clearMessage: true);
      final reply = await ref.read(assistantControllerProvider(sessionId).notifier).sendSpoken(text);
      if (!_active) return;
      if (reply != null && voice) {
        state = state.copyWith(phase: VoicePhase.speaking);
        await _tts.speak(reply.speechHe);
        if (!_active) return; // stopped while speaking
      }
      state = state.copyWith(phase: VoicePhase.idle, partial: '');
      if (state.continuous) await listen();
    } on VoiceException catch (e) {
      if (ref.mounted) _stop(message: messageFor(e.issue), keepContinuous: false);
    }
  }

  /// Still mounted and not stopped/cancelled meanwhile.
  bool get _active => ref.mounted && state.phase != VoicePhase.idle;

  void _stop({required String message, required bool keepContinuous}) {
    state = state.copyWith(phase: VoicePhase.idle, partial: '', messageHe: message, continuous: keepContinuous && state.continuous);
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
    NotifierProvider.autoDispose.family<VoiceController, VoiceState, String>(VoiceController.new);
