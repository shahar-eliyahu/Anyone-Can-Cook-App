import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/db/database.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../data/session_repository.dart';
import '../../models/recipe.dart';
import '../timers/timer_coordinator.dart';
import 'engine/action_dispatcher.dart';
import 'engine/cooking_engine.dart';
import 'engine/events.dart';

class CookingView {
  const CookingView({
    required this.session,
    required this.recipeRow,
    required this.recipe,
    required this.state,
  });

  final SessionRow session;
  final RecipeRow recipeRow;
  final Recipe recipe;
  final CookingState state;

  bool get isActive => session.status == SessionStatus.inProgress;

  CookingView copyWith({SessionRow? session, CookingState? state}) => CookingView(
        session: session ?? this.session,
        recipeRow: recipeRow,
        recipe: recipe,
        state: state ?? this.state,
      );
}

/// Runs one cooking session: replays its events, restores its notifications,
/// and routes every change through the [ActionDispatcher].
class CookingController extends AsyncNotifier<CookingView> {
  CookingController(this.sessionId);

  final String sessionId;
  late ActionDispatcher _dispatcher;

  @override
  Future<CookingView> build() async {
    final sessions = ref.read(sessionRepositoryProvider);
    final recipes = ref.read(recipeRepositoryProvider);
    final coordinator = ref.read(timerCoordinatorProvider);

    final session = await sessions.getSession(sessionId);
    if (session == null) throw StateError('session not found');
    final recipeRow = await recipes.getRecipe(session.recipeId);
    final planRow = await recipes.getPlan(session.planId);
    if (recipeRow == null || planRow == null) throw StateError('recipe not found');

    final state = CookingEngine.replay(planRow.plan, await sessions.loadEvents(sessionId));
    if (session.status == SessionStatus.inProgress) {
      await coordinator.reconcile(sessionId, state);
    }
    _dispatcher = ActionDispatcher(
      state: state,
      store: sessions.eventStoreFor(sessionId),
      // Notifications are derived from the new state after every event.
      onEffects: (_) => coordinator.sync(sessionId, _dispatcher.state),
      clock: ref.read(clockProvider),
    );
    return CookingView(
      session: session,
      recipeRow: recipeRow,
      recipe: recipeRow.recipe,
      state: state,
    );
  }

  Future<DispatchResult> _run(Future<DispatchResult> Function(ActionDispatcher d) change) async {
    await future;
    final result = await change(_dispatcher);
    final view = state.value;
    if (view != null) state = AsyncData(view.copyWith(state: _dispatcher.state));
    return result;
  }

  Future<DispatchResult> confirmAction(String stepId, String actionId) =>
      _run((d) => d.confirmAction(stepId, actionId, source: ActionSource.ui));

  /// "סיימתי — לשלב הבא" / "מוכן — לשלב הבא".
  Future<DispatchResult> completeStep(String stepId) =>
      _run((d) => d.completeStep(stepId, source: ActionSource.ui));

  /// "חזרה": undo the last tap.
  Future<DispatchResult> undoLast() => _run((d) => d.undoLast());

  Future<DispatchResult> completePrepTask(String id) =>
      _run((d) => d.completePrepTask(id, source: ActionSource.ui));

  Future<DispatchResult> undoPrepTask(String id) => _run((d) => d.undoPrepTask(id));
  Future<DispatchResult> undoStep(String stepId) => _run((d) => d.undoStep(stepId));
  Future<DispatchResult> pauseTimer(String id) => _run((d) => d.pauseTimer(id));
  Future<DispatchResult> resumeTimer(String id) => _run((d) => d.resumeTimer(id));
  Future<DispatchResult> extendTimer(String id) => _run((d) => d.extendTimer(id));
  Future<DispatchResult> dismissTimer(String id) => _run((d) => d.dismissTimer(id));
  Future<DispatchResult> shortenTimer(String id) => _run((d) => d.shortenTimer(id));
  Future<DispatchResult> recheckTimer(String id) => _run((d) => d.recheckTimer(id));

  Future<void> finish({String? notes}) async {
    await ref.read(sessionRepositoryProvider).complete(sessionId, notes: notes);
    await _endSession();
  }

  Future<void> abandon() async {
    await ref.read(sessionRepositoryProvider).abandon(sessionId);
    await _endSession();
  }

  Future<void> _endSession() async {
    await ref.read(timerCoordinatorProvider).clearSession(sessionId);
    final session = await ref.read(sessionRepositoryProvider).getSession(sessionId);
    final view = state.value;
    if (view != null && session != null) state = AsyncData(view.copyWith(session: session));
  }
}

final cookingControllerProvider =
    AsyncNotifierProvider.autoDispose.family<CookingController, CookingView, String>(
  CookingController.new,
);
