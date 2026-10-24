import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Phase 3D seams for voice. Speech recognition turns speech into text that enters the
/// same pipeline as typed input (`AssistantInput(text, modality: voice)`); replies carry
/// `speechHe` for text-to-speech. The platform implementations need speech packages, which
/// are added only with the user's approval (docs/PLAN.md, Phase 3D); until then the
/// defaults below keep everything working with text alone.

/// Converts the cook's speech to text (one utterance per [listen] result).
abstract interface class SpeechRecognizer {
  Future<bool> get isAvailable;

  /// Recognized utterances (final results only), in Hebrew.
  Stream<String> listen();
  Future<void> stop();
}

/// Reads Remy's replies aloud.
abstract interface class SpeechSynthesizer {
  Future<void> speak(String textHe);
  Future<void> stop();
}

/// No voice output (the default until a text-to-speech engine is approved and added).
class SilentSpeechSynthesizer implements SpeechSynthesizer {
  const SilentSpeechSynthesizer();
  @override
  Future<void> speak(String textHe) async {}
  @override
  Future<void> stop() async {}
}

final speechSynthesizerProvider = Provider<SpeechSynthesizer>((ref) => const SilentSpeechSynthesizer());

/// Null until a speech recognizer is approved and added; the UI hides the microphone then.
final speechRecognizerProvider = Provider<SpeechRecognizer?>((ref) => null);
