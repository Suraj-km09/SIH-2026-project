import 'package:dio/dio.dart';
import '../config/env_config.dart';
import 'auth_interceptor.dart';

/// Centralized HTTP client configured for MineIntel AI REST v1.
/// Automatically updates base URL when environment or custom URL changes.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.baseUrl,
        connectTimeout: EnvConfig.connectTimeout,
        receiveTimeout: EnvConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Mount Auth & Error Interceptor
    dio.interceptors.add(AuthInterceptor(dio: dio));
  }

  /// Update the base URL dynamically at runtime without changing service code
  void updateBaseUrl(String newBaseUrl) {
    EnvConfig.setCustomUrl(newBaseUrl);
    dio.options.baseUrl = newBaseUrl;
  }

  /// Reset to live production Vercel deployment
  void resetToProduction() {
    EnvConfig.resetToProduction();
    dio.options.baseUrl = EnvConfig.productionBaseUrl;
  }
}
