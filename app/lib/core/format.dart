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

String formatTime(DateTime t) {
  final l = t.toLocal();
  return '${_two(l.hour)}:${_two(l.minute)}';
}
