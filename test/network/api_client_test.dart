import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/network/api_client.dart';
import 'package:mineintel_ai/network/api_response.dart';

void main() {
  group('ApiClient & ApiResponse Tests', () {
    late ApiClient apiClient;

    setUp(() {
      apiClient = ApiClient();
      apiClient.resetToProduction();
    });

    test('ApiClient initializes with default live Vercel base URL and timeouts', () {
      expect(apiClient.dio.options.baseUrl, equals(EnvConfig.productionBaseUrl));
      expect(apiClient.dio.options.connectTimeout, equals(const Duration(seconds: 15)));
      expect(apiClient.dio.options.receiveTimeout, equals(const Duration(seconds: 30)));
      expect(apiClient.dio.options.headers['Content-Type'], equals('application/json'));
      expect(apiClient.dio.options.headers['Accept'], equals('application/json'));
    });

    test('ApiClient updateBaseUrl updates Dio base URL dynamically', () {
      const customUrl = 'http://127.0.0.1:5000/api/v1';
      apiClient.updateBaseUrl(customUrl);

      expect(apiClient.dio.options.baseUrl, equals(customUrl));
      expect(EnvConfig.baseUrl, equals(customUrl));

      // Reset
      apiClient.resetToProduction();
      expect(apiClient.dio.options.baseUrl, equals(EnvConfig.productionBaseUrl));
    });

    test('ApiResponse parses successful envelope with data and metadata', () {
      final json = {
        'success': true,
        'data': {'id': 'test-123', 'name': 'Iron Ore Survey'},
        'meta': {
          'total': 100,
          'page': 2,
          'limit': 20,
          'pages': 5,
        },
      };

      final response = ApiResponse<Map<String, dynamic>>.fromJson(
        json,
        (data) => data as Map<String, dynamic>,
      );

      expect(response.success, isTrue);
      expect(response.data?['id'], equals('test-123'));
      expect(response.meta?.total, equals(100));
      expect(response.meta?.page, equals(2));
      expect(response.meta?.limit, equals(20));
      expect(response.meta?.pages, equals(5));
    });

    test('ApiResponse parses error envelope with message and error code', () {
      final json = {
        'success': false,
        'error': 'DOCUMENT_NOT_FOUND',
        'message': 'Requested mining lease document does not exist.',
      };

      final response = ApiResponse<dynamic>.fromJson(
        json,
        (_) => null,
      );

      expect(response.success, isFalse);
      expect(response.error, equals('DOCUMENT_NOT_FOUND'));
      expect(response.message, contains('does not exist'));
      expect(response.data, isNull);
    });

    test('PaginationMeta toJson serializes accurately', () {
      const meta = PaginationMeta(total: 50, page: 1, limit: 10, pages: 5);
      final json = meta.toJson();

      expect(json['total'], equals(50));
      expect(json['page'], equals(1));
      expect(json['limit'], equals(10));
      expect(json['pages'], equals(5));
    });
  });
}
