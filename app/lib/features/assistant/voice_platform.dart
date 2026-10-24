import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'voice.dart';

/// Speech recognition through the phone's own service (`speech_to_text`), in Hebrew.
class PlatformSpeechRecognizer implements SpeechRecognizer {
  final _stt = SpeechToText();
  String? _localeId;
  bool _ready = false;
  Completer<String>? _current;
  String _lastPartial = '';

  @override
  Future<void> prepare() async {
    if (_ready) return;
    final bool ok;
    try {
      ok = await _stt.initialize(onError: _onError, onStatus: _onStatus);
    } on PlatformException {
      throw const VoiceException(VoiceIssue.recognitionUnavailable);
    } on MissingPluginException {
      throw const VoiceException(VoiceIssue.recognitionUnavailable);
    }
    if (!ok) {
      final permitted = await _stt.hasPermission;
      throw VoiceException(permitted ? VoiceIssue.recognitionUnavailable : VoiceIssue.permissionDenied);
    }
    final locales = await _stt.locales();
    // Hebrew is "he" or (older Android) "iw". The list may name only on-device languages
    // while the online service still understands Hebrew, so an unlisted Hebrew is tried
    // anyway; the service's language error then says Hebrew isn't available.
    final hebrew = locales.where((l) {
      final id = l.localeId.toLowerCase();
      return id.startsWith('he') || id.startsWith('iw');
    });
    _localeId = hebrew.isEmpty ? 'he_IL' : hebrew.first.localeId;
    _ready = true;
  }

  @override
  Future<String> listenOnce({required void Function(String partial) onPartial, bool forWakePhrase = false}) async {
    await prepare();
    final done = Completer<String>();
    _current = done;
    _lastPartial = '';
    await _stt.listen(
      onResult: (r) {
        _lastPartial = r.recognizedWords;
        onPartial(r.recognizedWords);
        if (r.finalResult && !done.isCompleted) done.complete(r.recognizedWords);
      },
      listenOptions: SpeechListenOptions(
        localeId: _localeId,
        partialResults: true,
        cancelOnError: true,
        // Hands-free waits patiently for "היי רמי"; a request after a tap ends at a short pause.
        listenMode: forWakePhrase ? ListenMode.dictation : ListenMode.confirmation,
        listenFor: Duration(seconds: forWakePhrase ? 60 : 20),
        pauseFor: Duration(seconds: forWakePhrase ? 30 : 3),
      ),
    );
    return done.future;
  }

  void _onStatus(String status) {
    // Stopped without a final result: what was heard so far is the utterance.
    if ((status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) &&
        !(_current?.isCompleted ?? true)) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!(_current?.isCompleted ?? true)) _current!.complete(_lastPartial);
      });
    }
  }

  void _onError(SpeechRecognitionError e) {
    final c = _current;
    if (c == null || c.isCompleted) return;
    c.completeError(VoiceException(issueFor(e.errorMsg)));
  }

  /// Android/iOS error names → what the cook can do about it.
  static VoiceIssue issueFor(String error) => switch (error) {
        'error_network' || 'error_network_timeout' || 'error_server' || 'error_server_disconnected' => VoiceIssue.network,
        'error_no_match' || 'error_speech_timeout' => VoiceIssue.noSpeech,
        'error_permission' || 'error_insufficient_permissions' => VoiceIssue.permissionDenied,
        'error_language_not_supported' || 'error_language_unavailable' => VoiceIssue.hebrewUnsupported,
        _ => VoiceIssue.other,
      };

  @override
  Future<void> stop() => _stt.stop();

  @override
  Future<void> cancel() async {
    await _stt.cancel();
    final c = _current;
    if (c != null && !c.isCompleted) c.complete('');
  }
}

/// Text-to-speech through the phone's own engine (`flutter_tts`), with a Hebrew voice.
class PlatformSpeechSynthesizer implements SpeechSynthesizer {
  final _tts = FlutterTts();
  bool? _hebrew;

  @override
  Future<bool> prepare() async {
    if (_hebrew != null) return _hebrew!;
    try {
      for (final lang in ['he-IL', 'iw-IL']) {
        if (await _tts.isLanguageAvailable(lang) == true) {
          await _tts.setLanguage(lang);
          await _tts.awaitSpeakCompletion(true);
          return _hebrew = true;
        }
      }
    } on PlatformException {
      // No engine, or it can't answer: replies stay text only.
    } on MissingPluginException {
      // Not on a phone.
    }
    return _hebrew = false;
  }

  @override
  Future<void> speak(String textHe) async {
    if (textHe.trim().isEmpty || !await prepare()) return;
    try {
      await _tts.speak(textHe);
    } on PlatformException {
      // Speaking failed; the reply is on screen anyway.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } on PlatformException {
      // Nothing was playing.
    }
  }
}
