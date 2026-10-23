import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'core/router.dart';
import 'features/timers/session_restorer.dart';
import 'features/timers/timer_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  late final GoRouter router;
  final notifier = LocalTimerNotifier();
  await notifier.init(onOpen: (sessionId) => router.go('/cook/$sessionId'));
  final launchedSession = await notifier.launchSessionId();

  final container = ProviderContainer(
    overrides: [timerNotifierProvider.overrideWithValue(notifier)],
    retry: (retryCount, error) => null,
  );
  await bootstrap(container);

  router = createRouter(
    initialLocation: launchedSession == null ? '/' : '/cook/$launchedSession',
  );
  runApp(UncontrolledProviderScope(
    container: container,
    child: TimerRestoreOnResume(child: App(router: router)),
  ));
}
