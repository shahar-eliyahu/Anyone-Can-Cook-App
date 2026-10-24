import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';

/// A quiet health request when the home screen opens. It wakes the server early
/// (Render Free sleeps when idle), so a recipe import later starts faster. Its
/// result is never shown: the cook only hears about the server when an import
/// actually needs it (docs/DECISIONS.md #39).
final healthProvider = FutureProvider<HealthStatus>(
  (ref) => ref.watch(apiClientProvider).getHealth(),
  retry: (retryCount, error) => null,
);
