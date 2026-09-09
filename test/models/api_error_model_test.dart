import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/models/api_error_model.dart';

void main() {
  group('ApiErrorModel Tests', () {
    test('Parses standard JSON map with success, message, and error code', () {
      final json = {
        'success': false,
        'message': 'Invalid username or password',
        'error': 'INVALID_CREDENTIALS',
      };

      final model = ApiErrorModel.fromJson(json, statusCode: 401);

      expect(model.success, isFalse);
      expect(model.message, equals('Invalid username or password'));
      expect(model.error, equals('INVALID_CREDENTIALS'));
      expect(model.code, equals('INVALID_CREDENTIALS'));
      expect(model.statusCode, equals(401));
      expect(model.isIncorrectPassword, isTrue);
      expect(model.errorTitle, equals('Incorrect Password'));
    });

    test('Parses Mongoose validation format with multiple fields', () {
      final raw = '{"success":false,"message":"Validation failed: Field \\"username\\" is required and must be a string; Field \\"password\\" is required and must be at least 6 characters","error":"Field \\"username\\" is required and must be a string; Field \\"password\\" is required and must be at least 6 characters"}';

      final model = ApiErrorModel.tryParse(raw, statusCode: 400);

      expect(model.isValidationError, isTrue);
      expect(model.fieldErrors.containsKey('username'), isTrue);
      expect(model.fieldErrors.containsKey('password'), isTrue);
      expect(model.fieldErrors['username'], contains('required'));
      expect(model.fieldErrors['password'], contains('required'));
      expect(model.errorTitle, equals('Validation Error'));
    });

    test('Identifies account inactive / suspended error', () {
      final json = {
        'success': false,
        'message': 'Account is suspended or inactive',
        'error': 'ACCOUNT_INACTIVE',
      };

      final model = ApiErrorModel.fromJson(json, statusCode: 403);

      expect(model.isAccountInactive, isTrue);
      expect(model.errorTitle, equals('Account Suspended'));
    });

    test('Handles null and fallback cases cleanly', () {
      final model = ApiErrorModel.tryParse(null, statusCode: 500);

      expect(model.success, isFalse);
      expect(model.message, equals('An unexpected error occurred.'));
      expect(model.errorTitle, equals('Server Error'));
    });
  });
}
