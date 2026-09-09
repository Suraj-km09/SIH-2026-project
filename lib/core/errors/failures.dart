/// User-facing Failure objects mapped from domain exceptions.
abstract class Failure {
  final String message;
  final String? code;
  final String? errorTitle;

  const Failure(this.message, {this.code, this.errorTitle});

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Unable to connect to MineIntel AI server. Check your connection.'])
      : super(code: 'NETWORK_FAILURE', errorTitle: 'Connection Error');
}

class AuthFailure extends Failure {
  final bool isIncorrectPassword;
  final bool isInvalidPassword;

  const AuthFailure(
    super.message, {
    this.isIncorrectPassword = false,
    this.isInvalidPassword = false,
    super.code = 'AUTH_FAILURE',
    super.errorTitle,
  });
}

class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([super.message = 'Your session has expired. Please sign in again.'])
      : super(code: 'SESSION_EXPIRED', errorTitle: 'Session Expired');
}

class PermissionFailure extends Failure {
  final bool isAccountInactive;

  const PermissionFailure(
    super.message, {
    this.isAccountInactive = false,
    super.code = 'PERMISSION_DENIED',
    super.errorTitle = 'Access Denied',
  });
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'The requested document or report was not found.'])
      : super(code: 'NOT_FOUND', errorTitle: 'Not Found');
}

class ConflictFailure extends Failure {
  final bool isDuplicateDocument;
  final bool isAgentConcurrency;

  const ConflictFailure(
    super.message, {
    this.isDuplicateDocument = false,
    this.isAgentConcurrency = false,
    super.code = 'CONFLICT',
    super.errorTitle = 'Conflict',
  });
}

class ValidationFailure extends Failure {
  final Map<String, dynamic>? errors;
  final String? validationMessage;
  final Map<String, String>? fieldErrors;

  const ValidationFailure(
    super.message, {
    this.errors,
    this.validationMessage,
    this.fieldErrors,
    super.code = 'VALIDATION_FAILED',
    super.errorTitle = 'Validation Error',
  });
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Internal server error. Please try again later.'])
      : super(code: 'SERVER_ERROR');
}

class ServiceUnavailableFailure extends Failure {
  const ServiceUnavailableFailure([super.message = 'MineIntel AI backend is initializing or degraded.'])
      : super(code: 'SERVICE_DEGRADED');
}
