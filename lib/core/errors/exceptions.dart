/// Base domain exception for MineIntel AI.
class AppException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const AppException(this.message, {this.code, this.statusCode});

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
  const AuthException([super.message = 'Invalid username or password.'])
      : super(code: 'AUTH_ERROR', statusCode: 401);
}

class TokenExpiredException extends AppException {
  const TokenExpiredException([super.message = 'Session expired. Please log in again.'])
      : super(code: 'TOKEN_EXPIRED', statusCode: 401);
}

class PermissionException extends AppException {
  const PermissionException([super.message = 'You do not have permission to perform this action.'])
      : super(code: 'FORBIDDEN', statusCode: 403);
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
  }) : super(code: 'CONFLICT', statusCode: 409);
}

class ValidationException extends AppException {
  final Map<String, dynamic>? errors;

  const ValidationException(super.message, {this.errors})
      : super(code: 'VALIDATION_ERROR', statusCode: 400);
}

class ServerException extends AppException {
  const ServerException([super.message = 'An unexpected internal server error occurred.'])
      : super(code: 'SERVER_ERROR', statusCode: 500);
}

class ServiceUnavailableException extends AppException {
  const ServiceUnavailableException([super.message = 'MineIntel AI backend is currently initializing or degraded.'])
      : super(code: 'SERVICE_UNAVAILABLE', statusCode: 503);
}
