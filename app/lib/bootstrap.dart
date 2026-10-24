import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/providers.dart';
import 'data/sample_seeder.dart';
import 'features/import/import_service.dart';
import 'features/timers/session_restorer.dart';
import 'features/timers/timer_coordinator.dart';

/// Startup work that needs no network: seed the sample recipe once and make
/// the active session's timer notifications match its saved state.
Future<void> bootstrap(ProviderContainer container) async {
  try {
    await seedSampleRecipe(
      recipes: container.read(recipeRepositoryProvider),
      settings: container.read(settingsRepositoryProvider),
      loadAsset: rootBundle.loadString,
    );
  } catch (e, st) {
    debugPrint('sample seeding failed: $e\n$st');
  }
  try {
    // Expired import drafts and temporary photos nothing refers to any more.
    await container.read(importServiceProvider).cleanup();
  } catch (e, st) {
    debugPrint('import cleanup failed: $e\n$st');
  }
  await restoreActiveSessionTimers(
    sessions: container.read(sessionRepositoryProvider),
    recipes: container.read(recipeRepositoryProvider),
    coordinator: container.read(timerCoordinatorProvider),
  );
}
