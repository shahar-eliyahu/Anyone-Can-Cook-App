import 'dart:async';
import 'dart:io';

import 'package:anyone_can_cook/app.dart';
import 'package:anyone_can_cook/core/api_client.dart';
import 'package:anyone_can_cook/core/clock.dart';
import 'package:anyone_can_cook/core/db/database.dart';
import 'package:anyone_can_cook/core/router.dart';
import 'package:anyone_can_cook/data/recipe_repository.dart';
import 'package:anyone_can_cook/data/sample_seeder.dart';
import 'package:anyone_can_cook/data/session_repository.dart';
import 'package:anyone_can_cook/data/settings_repository.dart';
import 'package:anyone_can_cook/features/kitchen/backend_status.dart';
import 'package:anyone_can_cook/features/timers/timer_notifier.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'sample.dart';

/// Everything a widget test needs: an in-memory database, a fake clock with a
/// ticker the test controls, a recording notifier and an offline-safe backend.
class AppHarness {
  AppHarness({AppDatabase? db, FakeClock? clock})
      : db = db ?? AppDatabase(NativeDatabase.memory()),
        clock = clock ?? FakeClock();

  final AppDatabase db;
  final FakeClock clock;
  final notifier = RecordingTimerNotifier();
  final _ticks = StreamController<DateTime>.broadcast();

  RecipeRepository get recipes => RecipeRepository(db, clock.call);
  SessionRepository get sessions => SessionRepository(db, clock.call);

  Future<String> seedSample() async => (await seedSampleRecipe(
        recipes: recipes,
        settings: SettingsRepository(db, clock.call),
        // Sync read: real async I/O never completes inside testWidgets' fake time.
        loadAsset: (path) async => File(path).readAsStringSync(),
      ))!;

  Widget build({
    String initialLocation = '/',
    Future<HealthStatus> Function()? health,
  }) =>
      ProviderScope(
        retry: (retryCount, error) => null,
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock.call),
          tickerProvider.overrideWith((ref) => _ticks.stream),
          timerNotifierProvider.overrideWithValue(notifier),
          healthProvider.overrideWith(
            (ref) => (health ??
                () async => const HealthStatus(status: 'ok', version: '0.1.0', aiProvider: 'mock'))(),
          ),
        ],
        child: App(router: createRouter(initialLocation: initialLocation)),
      );

  /// Moves the fake clock and re-renders countdowns.
  Future<void> advance(WidgetTester tester, Duration d) async {
    clock.advance(d);
    _ticks.add(clock.now);
    await tester.pumpAndSettle();
  }

  /// Unmounts the app and flushes the zero-delay timers drift schedules when
  /// stream queries are cancelled, then closes the database.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await _ticks.close();
    await db.close();
    await tester.pump(const Duration(seconds: 1));
  }
}

/// A widget test with a fresh [AppHarness] that is always cleaned up.
void testApp(String description, Future<void> Function(WidgetTester tester, AppHarness h) body) {
  testWidgets(description, (tester) async {
    final h = AppHarness();
    try {
      await body(tester, h);
    } finally {
      await h.unmount(tester);
    }
  });
}
