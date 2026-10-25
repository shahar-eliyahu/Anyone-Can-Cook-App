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

/// The cook's choice: "היי רמי" during cooking, yes or no (kept across sessions). Shared by
/// the preparation screen, settings and the cooking screen, so they always agree.
class HandsFreePreference extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => await ref.read(settingsRepositoryProvider).get(SettingKeys.handsFree) == 'on';

  Future<void> set(bool on) async {
    await ref.read(settingsRepositoryProvider).set(SettingKeys.handsFree, on ? 'on' : 'off');
    state = AsyncData(on);
  }
}

final handsFreePreferenceProvider = AsyncNotifierProvider<HandsFreePreference, bool>(HandsFreePreference.new);

/// Why hands-free can't listen, in words the cook can act on.
String handsFreeMessage(VoiceIssue issue) {
  final l10n = lookupAppLocalizations(const Locale('he'));
  return switch (issue) {
    VoiceIssue.permissionDenied => l10n.voicePermissionDenied,
    VoiceIssue.recognitionUnavailable => l10n.voiceUnavailable,
    VoiceIssue.hebrewUnsupported => l10n.voiceHebrewUnsupported,
    VoiceIssue.network => l10n.handsFreeNetwork,
    _ => l10n.handsFreeError,
  };
}

/// Turning hands-free on (preparation or settings): asks for the microphone first, so the cook
/// decides about it calmly before cooking. Returns why it couldn't be turned on, or null.
Future<String?> turnOnHandsFree(WidgetRef ref) async {
  final recognizer = ref.read(speechRecognizerProvider);
  if (recognizer == null) return handsFreeMessage(VoiceIssue.recognitionUnavailable);
  try {
    await recognizer.prepare();
  } on VoiceException catch (e) {
    return handsFreeMessage(e.issue);
  }
  await ref.read(handsFreePreferenceProvider.notifier).set(true);
  return null;
}

/// `stopped`: the cook stopped listening for this cooking session (the saved choice stays).
enum HandsFreeStatus { off, starting, listening, paused, stopped, unavailable }

/// "היי רמי" was heard; [command] is what followed it (may be empty).
class WakeEvent {
  const WakeEvent(this.id, this.command);
  final int id;
  final String command;
}

class HandsFreeState {
  const HandsFreeState({this.enabled = false, this.status = HandsFreeStatus.off, this.messageHe, this.wake});

  /// The cook's saved choice is on.
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
/// this listener pauses until his sheet closes. Follows [handsFreePreferenceProvider] (off by
/// default); the cook can stop it for the current session from the cooking screen.
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
    if (recognizer != null) {
      // The saved choice (settings or preparation) turns listening on and off, live.
      ref.listen(handsFreePreferenceProvider, (_, next) {
        final on = next.value ?? false;
        if (on != state.enabled) on ? _start() : _stop();
      });
      Future.microtask(() async {
        final on = await ref.read(handsFreePreferenceProvider.future);
        if (ref.mounted && on && !state.enabled) _start();
      });
    }
    return const HandsFreeState();
  }

  void _start() {
    _errorsInRow = 0;
    state = state.copyWith(enabled: true, status: HandsFreeStatus.starting, clearMessage: true);
    _kick();
  }

  void _stop({HandsFreeStatus status = HandsFreeStatus.off}) {
    state = state.copyWith(enabled: status != HandsFreeStatus.off, status: status, clearMessage: true);
    _settle?.cancel();
    if (_running) _recognizer?.cancel();
    unawaited(ScreenAwake.set(false));
  }

  /// The "מקשיב" indicator: stop listening for this cooking session. The saved choice stays,
  /// so the next cooking session listens again.
  void stopForNow() {
    if (state.enabled) _stop(status: HandsFreeStatus.stopped);
  }

  /// Listen again after [stopForNow], or try again after a problem.
  void resume() {
    if (state.enabled) _start();
  }

  bool get _canListen =>
      ref.mounted &&
      state.enabled &&
      !_handingOff &&
      _foreground &&
      state.status != HandsFreeStatus.unavailable &&
      state.status != HandsFreeStatus.stopped &&
      ref.read(remySheetOpenProvider) == 0;

  void _toBackground() {
    _foreground = false;
    _suspend();
  }

  void _suspend() {
    _settle?.cancel();
    if (_running) _recognizer?.cancel();
    if (ref.mounted &&
        state.enabled &&
        state.status != HandsFreeStatus.unavailable &&
        state.status != HandsFreeStatus.stopped) {
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

  String messageFor(VoiceIssue issue) => handsFreeMessage(issue);
}

final handsFreeControllerProvider =
    NotifierProvider.autoDispose.family<HandsFreeController, HandsFreeState, String>(HandsFreeController.new);
