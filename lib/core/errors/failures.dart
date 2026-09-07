/// User-facing Failure objects mapped from domain exceptions.
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Unable to connect to MineIntel AI server. Check your connection.'])
      : super(code: 'NETWORK_FAILURE');
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed. Please verify your credentials.'])
      : super(code: 'AUTH_FAILURE');
}

class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([super.message = 'Your session has expired. Please sign in again.'])
      : super(code: 'SESSION_EXPIRED');
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Access denied. You do not have permissions for this action.'])
      : super(code: 'PERMISSION_DENIED');
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'The requested document or report was not found.'])
      : super(code: 'NOT_FOUND');
}

class ConflictFailure extends Failure {
  final bool isDuplicateDocument;
  final bool isAgentConcurrency;

  const ConflictFailure(
    super.message, {
    this.isDuplicateDocument = false,
    this.isAgentConcurrency = false,
  }) : super(code: 'CONFLICT');
}

class ValidationFailure extends Failure {
  final Map<String, dynamic>? errors;

  const ValidationFailure(super.message, {this.errors})
      : super(code: 'VALIDATION_FAILED');
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Internal server error. Please try again later.'])
      : super(code: 'SERVER_ERROR');
}

class ServiceUnavailableFailure extends Failure {
  const ServiceUnavailableFailure([super.message = 'MineIntel AI backend is initializing or degraded.'])
      : super(code: 'SERVICE_DEGRADED');
}
