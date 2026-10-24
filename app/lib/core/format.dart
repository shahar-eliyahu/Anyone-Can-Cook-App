import '../l10n/app_localizations.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// 45:00, or 1:05:00 for an hour or more.
String formatDuration(Duration d) {
  final total = d.inSeconds < 0 ? 0 : d.inSeconds;
  final h = total ~/ 3600, m = (total % 3600) ~/ 60, s = total % 60;
  return h > 0 ? '$h:${_two(m)}:${_two(s)}' : '${_two(m)}:${_two(s)}';
}

String formatSeconds(int seconds) => formatDuration(Duration(seconds: seconds));

/// 24.10.2026 18:05 in local time.
String formatDateTime(DateTime t) {
  final l = t.toLocal();
  return '${l.day}.${l.month}.${l.year} ${_two(l.hour)}:${_two(l.minute)}';
}

/// "18:40", "מחר ב-07:30", or "26.10 ב-07:30" relative to [now] (local time).
String formatWhen(DateTime at, DateTime now, AppLocalizations l10n) {
  final a = at.toLocal(), n = now.toLocal();
  final days = DateTime(a.year, a.month, a.day).difference(DateTime(n.year, n.month, n.day)).inDays;
  final time = formatTime(at);
  return switch (days) {
    0 => time,
    1 => l10n.tomorrowAt(time),
    _ => l10n.dateAt('${a.day}.${a.month}', time),
  };
}

String formatTime(DateTime t) {
  final l = t.toLocal();
  return '${_two(l.hour)}:${_two(l.minute)}';
}

/// "כ-25 דק'", "כשעה", "כשעה ו-20 דק'", "כ-2½ שעות" — for estimates, never exact.
String formatApproxDuration(int minutes, AppLocalizations l10n) {
  if (minutes < 55) return l10n.durationMinutes(((minutes / 5).round() * 5).clamp(5, 50));
  if (minutes < 70) return l10n.durationHour;
  if (minutes < 90) return l10n.durationHourMinutes(((minutes - 60) / 5).round() * 5);
  final halfHours = (minutes / 30).round();
  final hours = halfHours ~/ 2;
  return l10n.durationHours(halfHours.isOdd ? '$hours½' : '$hours');
}
