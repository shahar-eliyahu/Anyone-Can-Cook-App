import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/app_localizations.dart';

/// Schedules cooking notifications. Faked in tests.
abstract interface class TimerNotifier {
  /// Schedules (or replaces) the notification [key] of a session.
  Future<void> scheduleNotification({
    required String sessionId,
    required String key,
    required DateTime at,
    required String title,
    required String body,
    bool quiet = false,
  });

  Future<void> cancelNotification(String sessionId, String key);

  /// Phase 1 entry point: a "time to check" notification for a timer.
  Future<void> scheduleTimer({
    required String sessionId,
    required String timerId,
    required DateTime endsAt,
    required String labelHe,
  });

  Future<void> cancelTimer(String sessionId, String timerId);

  /// Cancels every pending notification of a session.
  Future<void> cancelSession(String sessionId);
}

/// Hebrew strings for code that runs outside the widget tree.
AppLocalizations get hebrewStrings => lookupAppLocalizations(const Locale('he'));

/// Stable notification id per session key, so rescheduling replaces.
int timerNotificationId(String sessionId, String key) {
  var hash = 0x811c9dc5;
  for (final unit in utf8.encode('$sessionId/$key')) {
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

  static const _timersChannel = 'cooking_timers';
  static const _prepChannel = 'prep_reminders';
  static const _testNotificationId = 1;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Call once at startup. [onOpen] receives the session id of a tapped
  /// cooking notification.
  Future<void> init({required void Function(String sessionId) onOpen}) async {
    tz_data.initializeTimeZones();
    final s = hebrewStrings;
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
    await _android?.createNotificationChannel(AndroidNotificationChannel(
      _timersChannel,
      s.channelTimersName,
      description: s.channelTimersDescription,
      importance: Importance.max,
    ));
    // Quieter: no pop-up, so helpful reminders don't interrupt.
    await _android?.createNotificationChannel(AndroidNotificationChannel(
      _prepChannel,
      s.channelPrepName,
      description: s.channelPrepDescription,
      importance: Importance.defaultImportance,
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

  NotificationDetails _details({required bool quiet, String? groupKey}) {
    final s = hebrewStrings;
    return NotificationDetails(
      android: quiet
          ? AndroidNotificationDetails(
              _prepChannel,
              s.channelPrepName,
              channelDescription: s.channelPrepDescription,
              groupKey: groupKey,
            )
          : AndroidNotificationDetails(
              _timersChannel,
              s.channelTimersName,
              channelDescription: s.channelTimersDescription,
              importance: Importance.max,
              priority: Priority.high,
              category: AndroidNotificationCategory.alarm,
              groupKey: groupKey,
            ),
      iOS: DarwinNotificationDetails(presentSound: !quiet, presentAlert: true, threadIdentifier: groupKey),
    );
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    final exact = await _android?.canScheduleExactNotifications() ?? true;
    return exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  @override
  Future<void> scheduleNotification({
    required String sessionId,
    required String key,
    required DateTime at,
    required String title,
    required String body,
    bool quiet = false,
  }) async {
    if (!_ready) return;
    // Times already passed are shown in the app; nothing to schedule.
    if (!at.isAfter(DateTime.now().add(const Duration(seconds: 1)))) return;
    await _plugin.zonedSchedule(
      id: timerNotificationId(sessionId, key),
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
      notificationDetails: _details(quiet: quiet, groupKey: 'session:$sessionId'),
      androidScheduleMode: await _scheduleMode(),
      payload: jsonEncode({'session_id': sessionId, 'key': key}),
    );
  }

  @override
  Future<void> cancelNotification(String sessionId, String key) async {
    if (!_ready) return;
    await _plugin.cancel(id: timerNotificationId(sessionId, key));
  }

  @override
  Future<void> scheduleTimer({
    required String sessionId,
    required String timerId,
    required DateTime endsAt,
    required String labelHe,
  }) =>
      scheduleNotification(
        sessionId: sessionId,
        key: timerId,
        at: endsAt,
        title: hebrewStrings.notifCheckTitle(labelHe),
        body: hebrewStrings.notifCheckBodyDefault,
      );

  @override
  Future<void> cancelTimer(String sessionId, String timerId) =>
      cancelNotification(sessionId, timerId);

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
      title: hebrewStrings.notifTestTitle,
      body: hebrewStrings.notifTestBody,
      scheduledDate: tz.TZDateTime.from(DateTime.now().toUtc().add(delay), tz.UTC),
      notificationDetails: _details(quiet: false),
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
