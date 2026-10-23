import 'package:anyone_can_cook/features/timers/timer_notifier.dart';

/// Records scheduled timer notifications instead of talking to the OS.
class RecordingTimerNotifier implements TimerNotifier {
  /// Pending notifications: 'sessionId/timerId' → when they fire.
  final scheduled = <String, DateTime>{};
  final log = <String>[];

  @override
  Future<void> scheduleTimer({
    required String sessionId,
    required String timerId,
    required DateTime endsAt,
    required String labelHe,
  }) async {
    scheduled['$sessionId/$timerId'] = endsAt;
    log.add('schedule $timerId');
  }

  @override
  Future<void> cancelTimer(String sessionId, String timerId) async {
    scheduled.remove('$sessionId/$timerId');
    log.add('cancel $timerId');
  }

  @override
  Future<void> cancelSession(String sessionId) async {
    scheduled.removeWhere((key, _) => key.startsWith('$sessionId/'));
    log.add('cancelSession');
  }
}
