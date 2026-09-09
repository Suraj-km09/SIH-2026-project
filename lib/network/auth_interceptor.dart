import 'package:dio/dio.dart';
import '../config/env_config.dart';
import '../core/constants/api_endpoints.dart';
import '../core/errors/exceptions.dart';
import '../models/api_error_model.dart';
import '../services/secure_storage_service.dart';

/// Dio Interceptor managing Bearer token injection, transparent token refresh,
/// and standardized backend error envelope parsing.
class AuthInterceptor extends QueuedInterceptor {
  final Dio dio;
  final SecureStorageService _storage = SecureStorageService();

  AuthInterceptor({required this.dio});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Inject Bearer token if present
    final token = await _storage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Default JSON headers
    options.headers['Accept'] = 'application/json';
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final statusCode = response?.statusCode;
    final data = response?.data;

    // Handle 401 and attempt automatic token refresh
    if (statusCode == 401) {
      final errorCode = data is Map ? data['error'] : null;
      if (errorCode == 'TOKEN_EXPIRED') {
        final newToken = await _attemptTokenRefresh();
        if (newToken != null) {
          // Retry the failed request with the new token
          final requestOptions = err.requestOptions;
          requestOptions.headers['Authorization'] = 'Bearer $newToken';

          try {
            final clonedResponse = await dio.request(
              requestOptions.path,
              options: Options(
                method: requestOptions.method,
                headers: requestOptions.headers,
                contentType: requestOptions.contentType,
              ),
              data: requestOptions.data,
              queryParameters: requestOptions.queryParameters,
            );
            return handler.resolve(clonedResponse);
          } on DioException catch (retryErr) {
            return handler.next(retryErr);
          }
        }
      }
    }

    // Transform DioException into user-friendly domain AppException
    final domainException = mapDioException(err);
    return handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: domainException,
        message: domainException.message,
      ),
    );
  }

  Future<String?> _attemptTokenRefresh() async {
    try {
      final oldToken = await _storage.getToken();
      if (oldToken == null) return null;

      // Standalone Dio instance to avoid interceptor recursion
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: EnvConfig.baseUrl,
          connectTimeout: EnvConfig.connectTimeout,
          receiveTimeout: EnvConfig.receiveTimeout,
        ),
      );

      final response = await refreshDio.post(
        ApiEndpoints.authRefresh,
        data: {'token': oldToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final newToken = response.data['data']['token'] as String;
        await _storage.saveToken(newToken);
        return newToken;
      }
    } catch (_) {
      // Clear token on failed refresh
      await _storage.deleteToken();
    }
    return null;
  }

  AppException mapDioException(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return const TimeoutException();
    }

    if (err.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    final res = err.response;
    if (res == null) {
      return NetworkException(err.message ?? 'Network connection failure.');
    }

    final apiError = ApiErrorModel.fromResponse(res.data, statusCode: res.statusCode);
    final message = apiError.message;
    final errorCode = apiError.code ?? apiError.error;

    switch (res.statusCode) {
      case 400:
      case 422:
        return ValidationException(
          message,
          errors: apiError.fieldErrors.isNotEmpty ? apiError.fieldErrors : null,
          validationMessage: apiError.validationMessage,
          fieldErrors: apiError.fieldErrors.isNotEmpty ? apiError.fieldErrors : null,
          code: errorCode ?? 'VALIDATION_ERROR',
          statusCode: res.statusCode,
          apiError: apiError,
        );
      case 401:
        if (apiError.isTokenExpired) {
          return const TokenExpiredException();
        }
        return AuthException(
          message,
          isIncorrectPassword: apiError.isIncorrectPassword,
          isInvalidPassword: apiError.isInvalidPassword,
          code: errorCode ?? 'AUTH_ERROR',
          statusCode: 401,
          apiError: apiError,
        );
      case 403:
        return PermissionException(
          message,
          isAccountInactive: apiError.isAccountInactive,
          code: errorCode ?? 'FORBIDDEN',
          statusCode: 403,
          apiError: apiError,
        );
      case 404:
        return NotFoundException(message);
      case 409:
        final isDup = apiError.isUserExists ||
            errorCode == 'DUPLICATE_DOCUMENT' ||
            message.toLowerCase().contains('duplicate') ||
            message.toLowerCase().contains('already exists');
        final isAgent = message.toLowerCase().contains('currently being processed');
        return ConflictException(
          message,
          isDuplicateDocument: isDup,
          isAgentConcurrency: isAgent,
          code: errorCode ?? 'CONFLICT',
          statusCode: 409,
          apiError: apiError,
        );
      case 503:
        return ServiceUnavailableException(message);
      case 500:
      default:
        if (apiError.isValidationError) {
          return ValidationException(
            message,
            validationMessage: apiError.validationMessage,
            fieldErrors: apiError.fieldErrors.isNotEmpty ? apiError.fieldErrors : null,
            code: errorCode ?? 'VALIDATION_ERROR',
            statusCode: res.statusCode,
            apiError: apiError,
          );
        }
        return ServerException(message);
    }
  }
}
