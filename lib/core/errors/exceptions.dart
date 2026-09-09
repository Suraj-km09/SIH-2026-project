import '../../models/api_error_model.dart';

/// Base domain exception for MineIntel AI.
class AppException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final ApiErrorModel? apiError;

  const AppException(
    this.message, {
    this.code,
    this.statusCode,
    this.apiError,
  });

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Unable to reach the server. Please check your network connection.'])
      : super(code: 'NETWORK_ERROR');
}

class TimeoutException extends AppException {
  const TimeoutException([super.message = 'Request timed out. The server may be busy.'])
      : super(code: 'TIMEOUT_ERROR');
}

class AuthException extends AppException {
  final bool isIncorrectPassword;
  final bool isInvalidPassword;

  const AuthException(
    super.message, {
    this.isIncorrectPassword = false,
    this.isInvalidPassword = false,
    super.code = 'AUTH_ERROR',
    super.statusCode = 401,
    super.apiError,
  });
}

class TokenExpiredException extends AppException {
  const TokenExpiredException([super.message = 'Session expired. Please log in again.'])
      : super(code: 'TOKEN_EXPIRED', statusCode: 401);
}

class PermissionException extends AppException {
  final bool isAccountInactive;

  const PermissionException(
    super.message, {
    this.isAccountInactive = false,
    super.code = 'FORBIDDEN',
    super.statusCode = 403,
    super.apiError,
  });
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'The requested resource was not found.'])
      : super(code: 'NOT_FOUND', statusCode: 404);
}

class ConflictException extends AppException {
  final bool isDuplicateDocument;
  final bool isAgentConcurrency;

  const ConflictException(
    super.message, {
    this.isDuplicateDocument = false,
    this.isAgentConcurrency = false,
    super.code = 'CONFLICT',
    super.statusCode = 409,
    super.apiError,
  });
}

class ValidationException extends AppException {
  final Map<String, dynamic>? errors;
  final String? validationMessage;
  final Map<String, String>? fieldErrors;

  const ValidationException(
    super.message, {
    this.errors,
    this.validationMessage,
    this.fieldErrors,
    super.code = 'VALIDATION_ERROR',
    super.statusCode = 400,
    super.apiError,
  });
}

class ServerException extends AppException {
  const ServerException([super.message = 'An unexpected internal server error occurred.'])
      : super(code: 'SERVER_ERROR', statusCode: 500);
}

class ServiceUnavailableException extends AppException {
  const ServiceUnavailableException([super.message = 'MineIntel AI backend is currently initializing or degraded.'])
      : super(code: 'SERVICE_UNAVAILABLE', statusCode: 503);
}
