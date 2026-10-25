import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/prepare/preparation.dart';
import '../models/cooking_plan.dart';
import '../models/plan_response.dart';
import '../models/recipe.dart';
import '../models/recipe_analysis.dart';
import 'config.dart';

class HealthStatus {
  const HealthStatus({
    required this.status,
    required this.version,
    required this.aiProvider,
  });

  factory HealthStatus.fromJson(Map<String, dynamic> json) => HealthStatus(
        status: json['status'] as String,
        version: json['version'] as String,
        aiProvider: json['ai_provider'] as String,
      );

  final String status;
  final String version;
  final String aiProvider;

  bool get isOk => status == 'ok';
}

/// A backend error, or `offline` / `timeout` when the server could not be reached.
class ApiFailure implements Exception {
  const ApiFailure(this.code, {this.retryAfterSeconds, this.site, this.resolvedUrl});

  final String code;
  final int? retryAfterSeconds;

  /// For a link import: the site the link led to, and its full address when the cook's link
  /// was a shared/short one (the server followed it).
  final String? site;
  final String? resolvedUrl;

  @override
  String toString() => 'ApiFailure($code)';
}

class ApiClient {
  ApiClient(String baseUrl, {String appToken = '', HttpClientAdapter? adapter})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            // Render Free can take up to ~1 minute to wake from sleep, and an
            // analysis is one or two AI calls.
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 120),
            sendTimeout: const Duration(seconds: 60),
            headers: {if (appToken.isNotEmpty) 'X-App-Token': appToken},
          ),
        ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
  }

  final Dio _dio;

  Future<HealthStatus> getHealth() async {
    final response = await _dio.get<Map<String, dynamic>>('/health');
    return HealthStatus.fromJson(response.data!);
  }

  Future<RecipeAnalysis> analyzeText(String text) =>
      _analysis('/v1/recipes/analyze', {'type': 'text', 'content': text});

  Future<RecipeAnalysis> analyzeUrl(String url) =>
      _analysis('/v1/recipes/analyze', {'type': 'url', 'content': url});

  Future<RecipeAnalysis> analyzeImage(Uint8List jpeg) =>
      _analysis('/v1/recipes/analyze-image', {'image_base64': base64Encode(jpeg)});

  Future<PlanResponse> plan(RecipeAnalysis analysis) async {
    final data = await _post('/v1/recipes/plan', {'analysis': analysis.toJson()});
    return PlanResponse.fromJson(data);
  }

  /// A recipe-specific substitute for a missing item (one AI call on the server).
  Future<SubstitutionProposal> substitute({
    required Recipe recipe,
    required CookingPlan plan,
    required ItemKind kind,
    required String targetId,
    String? noteHe,
  }) async {
    final data = await _post('/v1/recipes/substitute', {
      'recipe': recipe.toJson(),
      'plan': plan.toJson(),
      'target': {'kind': kind.name, 'id': targetId},
      if (noteHe != null && noteHe.trim().isNotEmpty) 'user_note_he': noteHe.trim(),
    });
    return SubstitutionProposal.fromJson(data, SubstitutionSource.ai);
  }

  /// Remy answers a question and may propose one change (the app validates and executes it).
  Future<AssistantTurnResult> assistantTurn({
    required String messageHe,
    required String modality,
    required Recipe recipe,
    required CookingPlan plan,
    required Map<String, Object?> snapshot,
    required List<Map<String, String>> history,
  }) async {
    final data = await _post('/v1/assistant/turn', {
      'message_he': messageHe,
      'modality': modality,
      'recipe': recipe.toJson(),
      'plan': plan.toJson(),
      'snapshot': snapshot,
      'history': history,
    });
    return AssistantTurnResult.fromJson(data);
  }

  /// Remy creating a recipe with the cook (stage recipe_creation): one call per message.
  Future<RecipeCreationResult> createRecipeTurn({
    required String messageHe,
    required String modality,
    required Map<String, Object?> preferences,
    required List<Map<String, String>> history,
    Map<String, Object?>? currentRecipe,
  }) async {
    final data = await _post('/v1/assistant/create', {
      'stage': 'recipe_creation',
      'message_he': messageHe,
      'modality': modality,
      'preferences': preferences,
      'history': history,
      'current_recipe': ?currentRecipe,
    });
    return RecipeCreationResult.fromJson(data);
  }

  Future<RecipeAnalysis> _analysis(String path, Map<String, Object?> body) async =>
      RecipeAnalysis.fromJson(await _post(path, body));

  Future<Map<String, dynamic>> _post(String path, Map<String, Object?> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: jsonEncode(body),
          options: Options(contentType: Headers.jsonContentType));
      return response.data!;
    } on DioException catch (e) {
      throw _failure(e);
    }
  }

  static ApiFailure _failure(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiFailure('timeout');
      case DioExceptionType.connectionError:
        return const ApiFailure('offline');
      default:
        final data = e.response?.data;
        final code = data is Map && data['error_code'] is String ? data['error_code'] as String : 'server_error';
        final retry = int.tryParse(e.response?.headers.value('retry-after') ?? '');
        String? text(String key) => data is Map && data[key] is String && (data[key] as String).isNotEmpty ? data[key] as String : null;
        return ApiFailure(code, retryAfterSeconds: retry, site: text('site'), resolvedUrl: text('resolved_url'));
    }
  }
}

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(apiBaseUrl, appToken: appClientToken),
);

/// Response of POST /v1/assistant/create. [analysis] is checked again on the device before it
/// becomes a draft; anything that doesn't parse is treated as no recipe at all.
class RecipeCreationResult {
  const RecipeCreationResult({
    required this.kind,
    required this.answerHe,
    required this.speechHe,
    this.options = const [],
    this.preferences = const {},
    this.analysis,
    this.totalMinutes,
    this.tipsHe = const [],
  });

  factory RecipeCreationResult.fromJson(Map<String, dynamic> j) {
    RecipeAnalysis? analysis;
    try {
      final a = j['analysis'];
      analysis = a is Map<String, dynamic> ? RecipeAnalysis.fromJson(a) : null;
    } on Object {
      analysis = null; // malformed: no recipe
    }
    return RecipeCreationResult(
      kind: j['kind'] as String,
      answerHe: j['answer_he'] as String,
      speechHe: j['speech_he'] as String? ?? j['answer_he'] as String,
      options: [for (final o in j['options_he'] as List? ?? const []) if (o is String && o.trim().isNotEmpty) o.trim()],
      preferences: Map<String, Object?>.from(j['preferences'] as Map? ?? const {}),
      analysis: analysis,
      totalMinutes: j['total_minutes'] as int?,
      tipsHe: [for (final t in j['tips_he'] as List? ?? const []) if (t is String) t],
    );
  }

  final String kind; // answer | options | recipe
  final String answerHe;
  final String speechHe;
  final List<String> options;
  final Map<String, Object?> preferences;
  final RecipeAnalysis? analysis;
  final int? totalMinutes;
  final List<String> tipsHe;
}

/// Response of POST /v1/assistant/turn.
class AssistantTurnResult {
  const AssistantTurnResult({required this.answerHe, required this.speechHe, this.proposal, this.command});

  factory AssistantTurnResult.fromJson(Map<String, dynamic> j) {
    final p = j['proposal'] as Map<String, dynamic>?;
    final c = j['command'] as Map<String, dynamic>?;
    return AssistantTurnResult(
      command: c == null
          ? null
          : AssistantCommandData(
              action: c['action'] as String,
              stepId: c['step_id'] as String?,
              actionId: c['action_id'] as String?,
              timerId: c['timer_id'] as String?,
              seconds: c['seconds'] as int?,
              lowConfidence: c['confidence'] == 'low',
              userUncertain: c['user_uncertain'] as bool? ?? false,
            ),
      answerHe: j['answer_he'] as String,
      speechHe: j['speech_he'] as String? ?? j['answer_he'] as String,
      proposal: p == null
          ? null
          : AssistantProposalData(
              kind: p['kind'] as String,
              summaryHe: p['summary_he'] as String,
              timerId: p['timer_id'] as String?,
              seconds: p['seconds'] as int?,
              ops: [for (final o in p['ops'] as List? ?? const []) Map<String, dynamic>.from(o as Map)],
            ),
    );
  }

  final String answerHe;
  final String speechHe;
  final AssistantProposalData? proposal;

  /// The message interpreted as one supported command (Gemini as a fallback interpreter).
  final AssistantCommandData? command;
}

class AssistantCommandData {
  const AssistantCommandData({
    required this.action,
    this.stepId,
    this.actionId,
    this.timerId,
    this.seconds,
    this.lowConfidence = false,
    this.userUncertain = false,
  });
  final String action;
  final String? stepId;
  final String? actionId;
  final String? timerId;
  final int? seconds;
  final bool lowConfidence;
  final bool userUncertain;
}

class AssistantProposalData {
  const AssistantProposalData({required this.kind, required this.summaryHe, this.timerId, this.seconds, this.ops = const []});
  final String kind; // extend_timer | patch
  final String summaryHe;
  final String? timerId;
  final int? seconds;
  final List<Map<String, dynamic>> ops;
}

