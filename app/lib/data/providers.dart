import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import '../core/db/database.dart';
import 'recipe_repository.dart';
import 'session_repository.dart';
import 'settings_repository.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>(
  (ref) => RecipeRepository(ref.watch(databaseProvider), ref.watch(clockProvider)),
);

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(ref.watch(databaseProvider), ref.watch(clockProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider), ref.watch(clockProvider)),
);

final activeSessionProvider = StreamProvider<SessionRow?>(
  (ref) => ref.watch(sessionRepositoryProvider).watchActiveSession(),
);

final historyProvider = StreamProvider<List<HistoryEntry>>(
  (ref) => ref.watch(sessionRepositoryProvider).watchHistory(),
);

final recipeProvider = StreamProvider.family<RecipeRow?, String>(
  (ref, id) => ref.watch(recipeRepositoryProvider).watchRecipe(id),
);
