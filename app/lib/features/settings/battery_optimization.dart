import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android battery-optimization status (see MainActivity.kt). Other platforms
/// report "not restricted".
class BatteryOptimization {
  static const _channel = MethodChannel('anyone_can_cook/battery');

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<bool> isRestricted() async {
    if (!_supported) return false;
    final ignoring =
        await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
    return !(ignoring ?? false);
  }

  static Future<void> openSettings() async {
    if (_supported) await _channel.invokeMethod<void>('openBatteryOptimizationSettings');
  }
}
