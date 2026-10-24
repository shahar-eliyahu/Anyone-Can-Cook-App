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
  const ApiFailure(this.code, {this.retryAfterSeconds});

  final String code;
  final int? retryAfterSeconds;

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
        return ApiFailure(code, retryAfterSeconds: retry);
    }
  }
}

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(apiBaseUrl, appToken: appClientToken),
);

/// Response of POST /v1/assistant/turn.
class AssistantTurnResult {
  const AssistantTurnResult({required this.answerHe, required this.speechHe, this.proposal});

  factory AssistantTurnResult.fromJson(Map<String, dynamic> j) {
    final p = j['proposal'] as Map<String, dynamic>?;
    return AssistantTurnResult(
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
}

class AssistantProposalData {
  const AssistantProposalData({required this.kind, required this.summaryHe, this.timerId, this.seconds, this.ops = const []});
  final String kind; // extend_timer | patch
  final String summaryHe;
  final String? timerId;
  final int? seconds;
  final List<Map<String, dynamic>> ops;
}

