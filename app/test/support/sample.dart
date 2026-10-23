import 'dart:io';

import 'package:anyone_can_cook/features/cooking/engine/action_dispatcher.dart';
import 'package:anyone_can_cook/features/cooking/engine/cooking_engine.dart';
import 'package:anyone_can_cook/features/cooking/engine/events.dart';
import 'package:anyone_can_cook/models/recipe_bundle.dart';

/// `flutter test` runs with the app/ directory as the working directory.
const sharedFixturePath = '../shared/fixtures/sample_recipe.json';
const assetFixturePath = 'assets/recipes/sample_recipe.json';

RecipeBundle loadSampleBundle() =>
    RecipeBundle.decode(File(sharedFixturePath).readAsStringSync());

class FakeClock {
  FakeClock([DateTime? start])
      : now = start ?? DateTime.utc(2026, 10, 24, 18);
  DateTime now;
  void advance(Duration d) => now = now.add(d);
  DateTime call() => now;
}

class MemoryEventStore implements CookingEventStore {
  final events = <CookingEvent>[];
  @override
  Future<void> append(CookingEvent event) async => events.add(event);
}

/// A started session over the sample plan with recorded events and effects.
class EngineHarness {
  EngineHarness({FakeClock? clock}) : clock = clock ?? FakeClock() {
    final plan = loadSampleBundle().plan;
    final started = SessionStarted(this.clock.now);
    store.events.add(started);
    dispatcher = ActionDispatcher(
      state: CookingEngine.reduce(CookingEngine.initial(plan), started).state,
      store: store,
      onEffects: (e) async => effects.addAll(e),
      clock: this.clock.call,
    );
  }

  final FakeClock clock;
  final store = MemoryEventStore();
  final effects = <EngineEffect>[];
  late final ActionDispatcher dispatcher;

  CookingState get state => dispatcher.state;
  DateTime get now => clock.now;

  Future<DispatchResult> confirm(
    String step,
    String action, {
    ActionSource source = ActionSource.ui,
    String? proposalId,
  }) =>
      dispatcher.confirmAction(step, action, source: source, proposalId: proposalId);

  /// Prep both sides and season the chicken: unlocks baking (s3) and rice (s4).
  Future<void> prepThroughSeasoning() async {
    await confirm('s1', 'a1');
    await confirm('s1', 'a2');
    await confirm('s2', 'a1');
  }
}
