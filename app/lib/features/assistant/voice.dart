import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'voice_platform.dart';

/// Remy's voice (Phase 3D), using the phone's own speech services. Speech recognition
/// turns speech into text that enters the same pipeline as typed input
/// (`AssistantInput(text, modality: voice)`); replies carry `speechHe` for text-to-speech.

/// Why voice can't be used right now; each has a friendly Hebrew message.
enum VoiceIssue { permissionDenied, recognitionUnavailable, hebrewUnsupported, network, noSpeech, other }

class VoiceException implements Exception {
  const VoiceException(this.issue);
  final VoiceIssue issue;
  @override
  String toString() => 'VoiceException($issue)';
}

/// Converts the cook's speech to Hebrew text, one utterance at a time.
abstract interface class SpeechRecognizer {
  /// Prepares recognition (asks for the microphone permission the first time). Throws
  /// [VoiceException] when it can't be used (no permission, no service, no Hebrew).
  Future<void> prepare();

  /// Listens to one utterance: partial text as it is heard, then the final text (empty
  /// when nothing was said). Throws [VoiceException] on recognition errors.
  Future<String> listenOnce({required void Function(String partial) onPartial});

  /// Finish now (the last heard text becomes final).
  Future<void> stop();

  /// Abandon the utterance.
  Future<void> cancel();
}

/// Reads Remy's replies aloud.
abstract interface class SpeechSynthesizer {
  /// True when a Hebrew voice is available (otherwise replies stay text only).
  Future<bool> prepare();

  /// Completes when the text has been spoken (or immediately without a voice).
  Future<void> speak(String textHe);
  Future<void> stop();
}

/// No voice output (unsupported platforms and tests).
class SilentSpeechSynthesizer implements SpeechSynthesizer {
  const SilentSpeechSynthesizer();
  @override
  Future<bool> prepare() async => false;
  @override
  Future<void> speak(String textHe) async {}
  @override
  Future<void> stop() async {}
}

bool get _mobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

final speechSynthesizerProvider = Provider<SpeechSynthesizer>(
  (ref) => _mobile ? PlatformSpeechSynthesizer() : const SilentSpeechSynthesizer(),
);

/// Null where the phone's speech recognition can't be used (the microphone is hidden).
final speechRecognizerProvider = Provider<SpeechRecognizer?>((ref) => _mobile ? PlatformSpeechRecognizer() : null);
