import 'dart:typed_data';

import 'package:anyone_can_cook/core/api_client.dart';
import 'package:anyone_can_cook/features/import/image_store.dart';
import 'package:anyone_can_cook/features/prepare/preparation.dart';
import 'package:anyone_can_cook/features/timers/timer_notifier.dart';
import 'package:anyone_can_cook/models/cooking_plan.dart';
import 'package:anyone_can_cook/models/plan_response.dart';
import 'package:anyone_can_cook/models/recipe.dart';
import 'package:anyone_can_cook/models/recipe_analysis.dart';

/// Records scheduled notifications instead of talking to the OS.
class RecordingTimerNotifier implements TimerNotifier {
  /// Pending notifications: 'sessionId/key' → when they fire.
  final scheduled = <String, DateTime>{};

  /// Title and body of each pending notification, by 'sessionId/key'.
  final texts = <String, (String title, String body)>{};
  final quiet = <String>{};
  final log = <String>[];

  @override
  Future<void> scheduleNotification({
    required String sessionId,
    required String key,
    required DateTime at,
    required String title,
    required String body,
    bool quiet = false,
  }) async {
    final id = '$sessionId/$key';
    scheduled[id] = at;
    texts[id] = (title, body);
    if (quiet) {
      this.quiet.add(id);
    } else {
      this.quiet.remove(id);
    }
    log.add('schedule $key');
  }

  @override
  Future<void> cancelNotification(String sessionId, String key) async {
    final id = '$sessionId/$key';
    scheduled.remove(id);
    texts.remove(id);
    quiet.remove(id);
    log.add('cancel $key');
  }

  @override
  Future<void> scheduleTimer({
    required String sessionId,
    required String timerId,
    required DateTime endsAt,
    required String labelHe,
  }) async {
    scheduled['$sessionId/$timerId'] = endsAt;
    log.add('schedule $timerId');
  }

  @override
  Future<void> cancelTimer(String sessionId, String timerId) async {
    scheduled.remove('$sessionId/$timerId');
    log.add('cancel $timerId');
  }

  @override
  Future<void> cancelSession(String sessionId) async {
    scheduled.removeWhere((key, _) => key.startsWith('$sessionId/'));
    texts.removeWhere((key, _) => key.startsWith('$sessionId/'));
    log.add('cancelSession');
  }
}

/// In-memory photo store: records what was saved and deleted.
class FakeImageStore implements ImageStore {
  final saved = <String>{};
  final deleted = <String>[];

  @override
  Future<(String, Uint8List)> saveCompressed(String pickedPath) async {
    final path = '/images/${saved.length + 1}.jpg';
    saved.add(path);
    return (path, Uint8List.fromList([0xff, 0xd8, 0xff, saved.length]));
  }

  @override
  Future<void> delete(String? path) async {
    if (path == null) return;
    saved.remove(path);
    deleted.add(path);
  }

  @override
  Future<void> deleteAllExcept(Set<String> keep) async {
    for (final p in saved.where((p) => !keep.contains(p)).toList()) {
      await delete(p);
    }
  }
}

/// API client double: queued responses, counted calls, and a switch that makes
/// any call fail the test (to prove that reopening a recipe never calls the API).
class FakeApi extends ApiClient {
  FakeApi() : super('http://fake.invalid');

  final analyses = <Object>[];
  final plans = <Object>[];
  final substitutions = <Object>[];
  final turns = <Object>[];
  final calls = <String>[];
  bool forbidCalls = false;

  T _next<T>(List<Object> queue, String name) {
    calls.add(name);
    if (forbidCalls) throw StateError('unexpected API call: $name');
    final item = queue.length > 1 ? queue.removeAt(0) : queue.first;
    if (item is Exception) throw item;
    return item as T;
  }

  @override
  Future<RecipeAnalysis> analyzeText(String text) async => _next(analyses, 'analyzeText');
  @override
  Future<RecipeAnalysis> analyzeUrl(String url) async => _next(analyses, 'analyzeUrl');
  @override
  Future<RecipeAnalysis> analyzeImage(Uint8List jpeg) async => _next(analyses, 'analyzeImage');
  @override
  Future<PlanResponse> plan(RecipeAnalysis analysis) async {
    lastPlanRequest = analysis;
    return _next(plans, 'plan');
  }

  RecipeAnalysis? lastPlanRequest;

  @override
  Future<SubstitutionProposal> substitute({
    required Recipe recipe,
    required CookingPlan plan,
    required ItemKind kind,
    required String targetId,
    String? noteHe,
  }) async {
    lastSubstituteNote = noteHe;
    return _next(substitutions, 'substitute');
  }

  String? lastSubstituteNote;

  @override
  Future<AssistantTurnResult> assistantTurn({
    required String messageHe,
    required String modality,
    required Recipe recipe,
    required CookingPlan plan,
    required Map<String, Object?> snapshot,
    required List<Map<String, String>> history,
  }) async {
    lastTurn = (message: messageHe, modality: modality, snapshot: snapshot, history: history);
    return _next(turns, 'assistantTurn');
  }

  ({String message, String modality, Map<String, Object?> snapshot, List<Map<String, String>> history})? lastTurn;
}
