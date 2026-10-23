import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class ApiClient {
  ApiClient(String baseUrl)
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            // Render Free can take up to ~1 minute to wake from sleep.
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 90),
          ),
        );

  final Dio _dio;

  Future<HealthStatus> getHealth() async {
    final response = await _dio.get<Map<String, dynamic>>('/health');
    return HealthStatus.fromJson(response.data!);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(apiBaseUrl));
