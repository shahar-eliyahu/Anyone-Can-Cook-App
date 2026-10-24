import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/settings_repository.dart';
import '../../l10n/app_localizations.dart';
import 'voice.dart';
import 'wake_phrase.dart';

/// How many of Remy's sheets are open. Hands-free listening steps aside while one is (the
/// sheet owns the microphone, and Remy must not hear himself).
class RemySheetGate extends Notifier<int> {
  @override
  int build() => 0;
  void open() => state++;
  void close() => state = state > 0 ? state - 1 : 0;
}

final remySheetOpenProvider = NotifierProvider<RemySheetGate, int>(RemySheetGate.new);

/// Keeps the screen on while hands-free cooking is active (a window flag on Android, the idle
/// timer on iOS). Silently does nothing where the platform can't.
abstract final class ScreenAwake {
  static const _channel = MethodChannel('anyone_can_cook/screen');

  /// Fire and forget: nothing waits on the platform for this.
  static Future<void> set(bool on) async {
    try {
      await _channel.invokeMethod<void>('setKeepOn', on);
    } on MissingPluginException {
      // Not on a phone (tests, desktop).
    } on PlatformException {
      // The screen just follows the system timeout.
    }
  }
}

enum HandsFreeStatus { off, starting, listening, paused, unavailable }

/// "היי רמי" was heard; [command] is what followed it (may be empty).
class WakeEvent {
  const WakeEvent(this.id, this.command);
  final int id;
  final String command;
}

class HandsFreeState {
  const HandsFreeState({this.enabled = false, this.status = HandsFreeStatus.off, this.messageHe, this.wake});

  /// The cook turned hands-free on (remembered for next time).
  final bool enabled;
  final HandsFreeStatus status;

  /// Why hands-free can't listen right now (permission, no Hebrew, offline…).
  final String? messageHe;
  final WakeEvent? wake;

  HandsFreeState copyWith({bool? enabled, HandsFreeStatus? status, String? messageHe, bool clearMessage = false, WakeEvent? wake}) =>
      HandsFreeState(
        enabled: enabled ?? this.enabled,
        status: status ?? this.status,
        messageHe: clearMessage ? null : messageHe ?? this.messageHe,
        wake: wake ?? this.wake,
      );
}

/// Hands-free cooking (docs/DESIGN.md §13): while the cooking screen is open and the app is
/// in front, listen for "היי רמי" with the phone's own speech recognition, in a loop of
/// patient sessions. A heard call becomes a [WakeEvent]; the cooking screen opens Remy, and
/// this listener pauses until his sheet closes. Off by default; the cook's choice is kept.
class HandsFreeController extends Notifier<HandsFreeState> {
  HandsFreeController(this.sessionId);

  final String sessionId;

  /// After the phrase (and maybe a command) the session ends once the speech settles.
  static const settleAfter = Duration(milliseconds: 1400);
  static const _retryDelay = Duration(seconds: 1);

  /// A breath between sessions, so a recognizer that returns at once never spins.
  static const _gap = Duration(milliseconds: 250);
  static const _maxErrorsInRow = 3;

  bool _foreground = true;
  bool _running = false;
  int _errorsInRow = 0;
  int _wakeIds = 0;
  Timer? _settle;

  /// A call was heard and Remy is about to open: don't start another session meanwhile.
  bool _handingOff = false;
  Timer? _handOffFallback;

  AppLocalizations get _l10n => lookupAppLocalizations(const Locale('he'));
  SpeechRecognizer? get _recognizer => ref.read(speechRecognizerProvider);
  bool get available => _recognizer != null;

  @override
  HandsFreeState build() {
    final recognizer = ref.read(speechRecognizerProvider);
    final lifecycle = AppLifecycleListener(
      onResume: () {
        _foreground = true;
        _kick();
      },
      onHide: _toBackground,
      onPause: _toBackground,
    );
    ref.listen(remySheetOpenProvider, (_, open) {
      if (open > 0) {
        _handingOff = false;
        _handOffFallback?.cancel();
        _suspend();
      } else {
        _kick();
      }
    });
    ref.onDispose(() {
      lifecycle.dispose();
      _settle?.cancel();
      _handOffFallback?.cancel();
      if (_running) recognizer?.cancel();
      ScreenAwake.set(false);
    });
    if (recognizer != null) Future.microtask(_loadChoice);
    return const HandsFreeState();
  }

  Future<void> _loadChoice() async {
    final on = await ref.read(settingsRepositoryProvider).get(SettingKeys.handsFree) == 'on';
    if (!ref.mounted || !on) return;
    state = state.copyWith(enabled: true, status: HandsFreeStatus.starting);
    _kick();
  }

  /// The switch on the cooking screen. Turning it on asks for the microphone the first time.
  Future<void> setEnabled(bool on) async {
    if (!available) return;
    await ref.read(settingsRepositoryProvider).set(SettingKeys.handsFree, on ? 'on' : 'off');
    if (!ref.mounted) return;
    _errorsInRow = 0;
    if (on) {
      state = state.copyWith(enabled: true, status: HandsFreeStatus.starting, clearMessage: true);
      _kick();
    } else {
      state = state.copyWith(enabled: false, status: HandsFreeStatus.off, clearMessage: true);
      _settle?.cancel();
      if (_running) await _recognizer?.cancel();
      unawaited(ScreenAwake.set(false));
    }
  }

  bool get _canListen =>
      ref.mounted &&
      state.enabled &&
      !_handingOff &&
      _foreground &&
      state.status != HandsFreeStatus.unavailable &&
      ref.read(remySheetOpenProvider) == 0;

  void _toBackground() {
    _foreground = false;
    _suspend();
  }

  void _suspend() {
    _settle?.cancel();
    if (_running) _recognizer?.cancel();
    if (ref.mounted && state.enabled && state.status != HandsFreeStatus.unavailable) {
      state = state.copyWith(status: HandsFreeStatus.paused);
    }
  }

  void _kick() {
    if (_running || !_canListen || _recognizer == null) return;
    _running = true;
    unawaited(_loop());
  }

  Future<void> _loop() async {
    final recognizer = _recognizer!;
    try {
      await recognizer.prepare();
    } on VoiceException catch (e) {
      _running = false;
      _fail(e.issue);
      return;
    }
    if (_canListen) {
      state = state.copyWith(status: HandsFreeStatus.listening, clearMessage: true);
      unawaited(ScreenAwake.set(true));
    }
    while (_canListen) {
      final String heard;
      try {
        heard = await recognizer.listenOnce(onPartial: _onPartial, forWakePhrase: true);
        _errorsInRow = 0;
      } on VoiceException catch (e) {
        _settle?.cancel();
        if (e.issue == VoiceIssue.noSpeech) {
          await Future<void>.delayed(_gap); // a quiet kitchen: just listen again
          continue;
        }
        if (e.issue == VoiceIssue.other && ++_errorsInRow < _maxErrorsInRow) {
          await Future<void>.delayed(_retryDelay);
          continue;
        }
        _fail(e.issue);
        break;
      }
      _settle?.cancel();
      if (!_canListen) break;
      final wake = detectWake(heard);
      if (wake != null) {
        // The cooking screen opens Remy; his sheet pauses and later resumes us. Should nobody
        // open him, listening resumes on its own.
        _handingOff = true;
        _handOffFallback = Timer(const Duration(seconds: 3), () {
          _handingOff = false;
          _kick();
        });
        state = state.copyWith(wake: WakeEvent(++_wakeIds, wake.command));
        break;
      }
      await Future<void>.delayed(_gap);
    }
    _running = false;
    if (ref.mounted && !state.enabled) unawaited(ScreenAwake.set(false));
    if (_canListen) _kick(); // conditions changed back while the last session was ending
  }

  /// Ends the session soon after the phrase (and the command after it) stop changing,
  /// instead of waiting out the long silence a wake session allows.
  void _onPartial(String partial) {
    if (detectWake(partial) == null) return;
    _settle?.cancel();
    _settle = Timer(settleAfter, () => _recognizer?.stop());
  }

  void _fail(VoiceIssue issue) {
    if (!ref.mounted) return;
    state = state.copyWith(status: HandsFreeStatus.unavailable, messageHe: messageFor(issue));
    ScreenAwake.set(false);
  }

  String messageFor(VoiceIssue issue) => switch (issue) {
        VoiceIssue.permissionDenied => _l10n.voicePermissionDenied,
        VoiceIssue.recognitionUnavailable => _l10n.voiceUnavailable,
        VoiceIssue.hebrewUnsupported => _l10n.voiceHebrewUnsupported,
        VoiceIssue.network => _l10n.handsFreeNetwork,
        _ => _l10n.handsFreeError,
      };
}

final handsFreeControllerProvider =
    NotifierProvider.autoDispose.family<HandsFreeController, HandsFreeState, String>(HandsFreeController.new);
