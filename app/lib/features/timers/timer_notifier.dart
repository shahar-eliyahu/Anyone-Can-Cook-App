import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the "timer finished" notifications. Faked in tests.
abstract interface class TimerNotifier {
  Future<void> scheduleTimer({
    required String sessionId,
    required String timerId,
    required DateTime endsAt,
    required String labelHe,
  });

  Future<void> cancelTimer(String sessionId, String timerId);

  /// Cancels every pending timer notification of a session.
  Future<void> cancelSession(String sessionId);
}

/// Stable notification id per session timer, so rescheduling replaces.
int timerNotificationId(String sessionId, String timerId) {
  var hash = 0x811c9dc5;
  for (final unit in utf8.encode('$sessionId/$timerId')) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return (hash & 0x7fffffff) | 0x100; // keep clear of the test notification id
}

class NotificationPermissions {
  const NotificationPermissions({
    required this.notificationsEnabled,
    required this.exactAlarmsAllowed,
  });
  final bool notificationsEnabled;
  final bool exactAlarmsAllowed;
}

/// Real implementation over flutter_local_notifications (Android and iOS).
class LocalTimerNotifier implements TimerNotifier {
  LocalTimerNotifier();

  static const _channelId = 'cooking_timers';
  static const _testNotificationId = 1;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Call once at startup. [onOpen] receives the session id of a tapped
  /// timer notification.
  Future<void> init({required void Function(String sessionId) onOpen}) async {
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final id = sessionIdFromPayload(response.payload);
        if (id != null) onOpen(id);
      },
    );
    await _android?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      'טיימרים לבישול',
      description: 'התראה כשטיימר בישול מסתיים',
      importance: Importance.max,
    ));
    _ready = true;
  }

  /// Session id of the notification that launched the app, if any.
  Future<String?> launchSessionId() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return sessionIdFromPayload(details.notificationResponse?.payload);
  }

  static String? sessionIdFromPayload(String? payload) {
    if (payload == null) return null;
    try {
      return (jsonDecode(payload) as Map<String, dynamic>)['session_id'] as String?;
    } on FormatException {
      return null;
    }
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'טיימרים לבישול',
      channelDescription: 'התראה כשטיימר בישול מסתיים',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
    ),
    iOS: DarwinNotificationDetails(presentSound: true, presentAlert: true),
  );

  Future<AndroidScheduleMode> _scheduleMode() async {
    final exact = await _android?.canScheduleExactNotifications() ?? true;
    return exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  @override
  Future<void> scheduleTimer({
    required String sessionId,
    required String timerId,
    required DateTime endsAt,
    required String labelHe,
  }) async {
    if (!_ready) return;
    // A timer that already ended is shown in the app; nothing to schedule.
    if (!endsAt.isAfter(DateTime.now().add(const Duration(seconds: 1)))) return;
    await _plugin.zonedSchedule(
      id: timerNotificationId(sessionId, timerId),
      title: '⏰ $labelHe: הזמן נגמר',
      body: 'לבשל כל אחד יכול · לחצו כדי לחזור לבישול',
      scheduledDate: tz.TZDateTime.from(endsAt.toUtc(), tz.UTC),
      notificationDetails: _details,
      androidScheduleMode: await _scheduleMode(),
      payload: jsonEncode({'session_id': sessionId, 'timer_id': timerId}),
    );
  }

  @override
  Future<void> cancelTimer(String sessionId, String timerId) async {
    if (!_ready) return;
    await _plugin.cancel(id: timerNotificationId(sessionId, timerId));
  }

  @override
  Future<void> cancelSession(String sessionId) async {
    if (!_ready) return;
    for (final p in await _plugin.pendingNotificationRequests()) {
      if (sessionIdFromPayload(p.payload) == sessionId) {
        await _plugin.cancel(id: p.id);
      }
    }
  }

  Future<NotificationPermissions> permissions() async {
    final android = _android;
    if (android == null) {
      return const NotificationPermissions(
        notificationsEnabled: true,
        exactAlarmsAllowed: true,
      );
    }
    return NotificationPermissions(
      notificationsEnabled: await android.areNotificationsEnabled() ?? false,
      exactAlarmsAllowed: await android.canScheduleExactNotifications() ?? false,
    );
  }

  Future<void> requestNotifications() async {
    await _android?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, sound: true);
  }

  Future<void> requestExactAlarms() async => _android?.requestExactAlarmsPermission();

  /// Schedules a test notification through the same path as cooking timers.
  Future<void> scheduleTest(Duration delay) async {
    if (!_ready) return;
    await _plugin.zonedSchedule(
      id: _testNotificationId,
      title: '⏰ התראת בדיקה',
      body: 'לבשל כל אחד יכול · ההתראות של הטיימרים עובדות',
      scheduledDate: tz.TZDateTime.from(DateTime.now().toUtc().add(delay), tz.UTC),
      notificationDetails: _details,
      androidScheduleMode: await _scheduleMode(),
    );
  }
}

/// Overridden in tests with a fake.
final timerNotifierProvider = Provider<TimerNotifier>((ref) {
  throw UnimplementedError('timerNotifierProvider must be overridden in main()');
});

/// Device-specific helpers (permissions, test notification); null in tests.
final localTimerNotifierProvider = Provider<LocalTimerNotifier?>((ref) {
  final notifier = ref.watch(timerNotifierProvider);
  return notifier is LocalTimerNotifier ? notifier : null;
});
