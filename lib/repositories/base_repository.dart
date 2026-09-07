import 'package:dio/dio.dart';
import '../config/env_config.dart';
import '../core/errors/exceptions.dart';
import '../core/errors/failures.dart';

/// Base repository class providing centralized error mapping and mock-mode support.
abstract class BaseRepository {
  /// Execute a network call and map domain exceptions to UI-safe Failures.
  Future<T> execute<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on AppException catch (e) {
      throw _mapExceptionToFailure(e);
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw _mapExceptionToFailure(e.error as AppException);
      }
      throw NetworkFailure(e.message ?? 'Network connection error.');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  /// Whether offline mock data is currently enabled.
  bool get isMockMode => EnvConfig.useMockData;

  Failure _mapExceptionToFailure(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is TimeoutException) return NetworkFailure(e.message);
    if (e is AuthException) return AuthFailure(e.message);
    if (e is TokenExpiredException) return SessionExpiredFailure(e.message);
    if (e is PermissionException) return PermissionFailure(e.message);
    if (e is NotFoundException) return NotFoundFailure(e.message);
    if (e is ConflictException) {
      return ConflictFailure(
        e.message,
        isDuplicateDocument: e.isDuplicateDocument,
        isAgentConcurrency: e.isAgentConcurrency,
      );
    }
    if (e is ValidationException) {
      return ValidationFailure(e.message, errors: e.errors);
    }
    if (e is ServiceUnavailableException) {
      return ServiceUnavailableFailure(e.message);
    }
    return ServerFailure(e.message);
  }
}
