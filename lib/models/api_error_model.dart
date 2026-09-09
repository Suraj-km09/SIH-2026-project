import 'dart:convert';

/// Standard API Error Model matching MineIntel AI backend response format.
///
/// Backend Specification (from openapi.yaml & API_DOCUMENTATION.md):
/// ```json
/// {
///   "success": false,
///   "message": "Validation failed: Field \"password\" is required and must be at least 6 characters",
///   "error": "Field \"password\" is required and must be at least 6 characters",
///   "code": "MONGOOSE_VALIDATION_ERROR"
/// }
/// ```
class ApiErrorModel {
  final bool success;
  final String message;
  final String? error;
  final String? code;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  const ApiErrorModel({
    this.success = false,
    required this.message,
    this.error,
    this.code,
    this.statusCode,
    this.fieldErrors = const {},
  });

  /// Parse error response from backend Map or JSON string.
  factory ApiErrorModel.fromResponse(dynamic data, {int? statusCode}) {
    return ApiErrorModel._parse(data, statusCode: statusCode);
  }

  factory ApiErrorModel.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    return ApiErrorModel._parse(json, statusCode: statusCode);
  }

  factory ApiErrorModel.tryParse(dynamic data, {int? statusCode}) {
    return ApiErrorModel._parse(data, statusCode: statusCode);
  }

  static ApiErrorModel _parse(dynamic data, {int? statusCode}) {
    if (data == null) {
      return ApiErrorModel(
        message: statusCode == 401
            ? 'Invalid username or password.'
            : (statusCode == 403
                ? 'Access denied. You do not have permission for this action.'
                : 'An unexpected error occurred.'),
        statusCode: statusCode,
      );
    }

    dynamic parsed = data;
    if (parsed is String) {
      try {
        parsed = jsonDecode(parsed);
      } catch (_) {
        // Plain string message from server
        return ApiErrorModel(
          message: parsed.trim().isNotEmpty ? parsed.trim() : 'Server returned an error.',
          statusCode: statusCode,
        );
      }
    }

    if (parsed is Map) {
      final json = Map<String, dynamic>.from(parsed);
      final rawMsg = json['message']?.toString() ?? json['error']?.toString() ?? 'Operation failed';
      final rawErr = json['error']?.toString();
      final rawCode = json['code']?.toString() ?? json['errorCode']?.toString();
      final fields = <String, String>{};

      // 1. Parse structured 'errors' object or array if present
      if (json['errors'] is Map) {
        (json['errors'] as Map).forEach((k, v) {
          if (v != null) fields[k.toString().toLowerCase()] = v.toString();
        });
      } else if (json['errors'] is List) {
        for (final item in json['errors'] as List) {
          if (item is Map) {
            final f = item['field']?.toString() ?? item['param']?.toString() ?? item['path']?.toString();
            final m = item['message']?.toString() ?? item['msg']?.toString() ?? item['error']?.toString();
            if (f != null && m != null) {
              fields[f.toLowerCase()] = m;
            }
          } else if (item is String) {
            final parts = item.split(':');
            if (parts.length > 1) {
              fields[parts[0].trim().toLowerCase()] = parts.sublist(1).join(':').trim();
            }
          }
        }
      }

      // 2. Parse Mongoose / Express validation text:
      // e.g. "Validation failed: Field \"username\" is required; Field \"password\" is required"
      final msgLower = rawMsg.toLowerCase();
      if (msgLower.contains('validation failed') ||
          msgLower.contains('validation error') ||
          rawCode == 'MONGOOSE_VALIDATION_ERROR' ||
          rawCode == 'VALIDATION_ERROR') {
        final clean = rawMsg.replaceFirst(RegExp(r'^Validation (?:failed|error):\s*', caseSensitive: false), '');
        final statements = clean.split(';');
        for (final stmt in statements) {
          final trimmed = stmt.trim();
          final match = RegExp(r'Field\s+["\x27]?([a-zA-Z0-9_]+)["\x27]?\s+(.*)', caseSensitive: false).firstMatch(trimmed);
          if (match != null) {
            final fName = match.group(1)!.toLowerCase();
            final fDesc = match.group(2)!;
            fields[fName] = '${fName[0].toUpperCase()}${fName.substring(1)} $fDesc';
          }
        }
      }

      return ApiErrorModel(
        success: json['success'] as bool? ?? false,
        message: rawMsg,
        error: rawErr,
        code: rawCode ?? (rawErr != null && RegExp(r'^[A-Z0-9_]+$').hasMatch(rawErr) ? rawErr : null),
        statusCode: statusCode,
        fieldErrors: fields,
      );
    }

    return ApiErrorModel(
      message: parsed.toString(),
      statusCode: statusCode,
    );
  }

  /// Whether this is a validation failure (HTTP 400, 422, Mongoose validation error).
  bool get isValidationError {
    if (statusCode == 400 || statusCode == 422) return true;
    final c = (code ?? '').toUpperCase();
    if (c == 'MONGOOSE_VALIDATION_ERROR' || c == 'VALIDATION_ERROR' || c == 'VALIDATION_FAILED') return true;
    final m = message.toLowerCase();
    if (m.contains('validation failed') || m.contains('validation error') || m.contains('required')) return true;
    return false;
  }

  /// Whether the error represents incorrect password or bad credentials.
  bool get isIncorrectPassword {
    if (statusCode == 401) {
      final c = (code ?? error ?? '').toUpperCase();
      if (c == 'INVALID_CREDENTIALS' || c == 'AUTH_ERROR' || c.contains('PASSWORD')) return true;
      final m = message.toLowerCase();
      if (m.contains('password') || m.contains('credentials')) return true;
    }
    return false;
  }

  /// Whether the password format/length is invalid (e.g. 400 validation error).
  bool get isInvalidPassword {
    if (statusCode == 401) return false;
    if (fieldErrors.containsKey('password')) return true;
    final m = message.toLowerCase();
    final e = (error ?? '').toLowerCase();
    return (m.contains('password') || e.contains('password')) &&
        (m.contains('least 6') || m.contains('required') || m.contains('characters') || m.contains('too short'));
  }

  /// Whether the user account does not exist.
  bool get isUserNotFound {
    final c = (code ?? error ?? '').toUpperCase();
    final m = message.toLowerCase();
    return c == 'USER_NOT_FOUND' || c == 'NOT_FOUND' || m.contains('user not found') || m.contains('no user');
  }

  /// Whether the user already exists (duplicate on register).
  bool get isUserExists {
    final c = (code ?? error ?? '').toUpperCase();
    final m = message.toLowerCase();
    return c == 'USER_EXISTS' || m.contains('already exists');
  }

  /// Whether the account is suspended or inactive.
  bool get isAccountInactive {
    final c = (code ?? error ?? '').toUpperCase();
    final m = message.toLowerCase();
    return statusCode == 403 || c == 'ACCOUNT_INACTIVE' || m.contains('inactive') || m.contains('suspended');
  }

  /// Whether the session has expired.
  bool get isTokenExpired {
    final c = (code ?? error ?? '').toUpperCase();
    return c == 'TOKEN_EXPIRED';
  }

  /// Descriptive Error Title for UI cards and headers.
  String get errorTitle {
    if (isValidationError || isInvalidPassword) return 'Validation Error';
    if (isIncorrectPassword) return 'Incorrect Password';
    if (isUserNotFound) return 'Account Not Found';
    if (isUserExists) return 'Account Exists';
    if (isAccountInactive) return 'Account Suspended';
    if (isTokenExpired) return 'Session Expired';
    if (statusCode == 401) return 'Authentication Failed';
    if (statusCode == 403) return 'Access Denied';
    if (statusCode == 404) return 'Resource Not Found';
    if (statusCode == 409) return 'Conflict Detected';
    if (statusCode == 500) return 'Server Error';
    if (statusCode == 503) return 'Service Degraded';
    return 'Error';
  }

  /// Extracted clean validation message for user alerts.
  String get validationMessage {
    if (fieldErrors.isNotEmpty) {
      return fieldErrors.values.join('\n');
    }
    if (message.toLowerCase().startsWith('validation failed:')) {
      return message.substring('validation failed:'.length).trim();
    }
    if (message.toLowerCase().startsWith('validation error:')) {
      return message.substring('validation error:'.length).trim();
    }
    return error ?? message;
  }

  /// User-friendly explanation string.
  String get userFriendlyMessage {
    if (isValidationError) {
      return validationMessage;
    }
    if (isIncorrectPassword) {
      return 'The password or username you entered is incorrect. Please verify your credentials and try again.';
    }
    if (isUserNotFound) {
      return 'The requested user account was not found. Please verify your username or register.';
    }
    if (isAccountInactive) {
      return 'Your account is currently suspended or inactive. Contact your Mining Directorate Administrator.';
    }
    if (isTokenExpired) {
      return 'Your session has expired. Please log in again to continue.';
    }
    return message;
  }
}
