import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef Clock = DateTime Function();

/// Injectable clock so cooking logic can be tested with a fake time source.
final clockProvider = Provider<Clock>((ref) => DateTime.now);

/// Ticks every second while watched, for live timer countdowns.
final tickerProvider = StreamProvider.autoDispose<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  return Stream.periodic(const Duration(seconds: 1), (_) => clock());
});
