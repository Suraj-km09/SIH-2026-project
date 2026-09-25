import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/network/api_client.dart';
import 'package:mineintel_ai/network/api_response.dart';
import 'package:mineintel_ai/models/report_model.dart';
import 'package:mineintel_ai/network/report_remote_data_source.dart';
import 'package:mineintel_ai/network/review_remote_data_source.dart';

void main() {
  group('Report mutation transport', () {
    late ApiClient client;
    late List<Interceptor> originalInterceptors;
    late List<RequestOptions> requests;

    setUp(() {
      client = ApiClient();
      originalInterceptors = client.dio.interceptors.toList();
      requests = [];
      client.dio.interceptors.clear();
    });

    tearDown(() {
      client.dio.interceptors.clear();
      client.dio.interceptors.addAll(originalInterceptors);
    });

    test('all report and review mutations send exact viewed revisions', () async {
      client.dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        requests.add(options);
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {'data': {'_id': 'report-1', '__v': (options.data['expectedVersion'] as int) + 1, 'version': 99}},
        ));
      }));
      final reports = ReportRemoteDataSource(apiClient: client);
      final reviews = ReviewRemoteDataSource(apiClient: client);
      for (final revision in [0, 7]) {
        final updated = await reports.updateReport('report-1', ReportUpdateRequest(expectedVersion: revision, title: 'Draft'));
        expect(updated.revision, revision + 1);
        await reports.submitForReview('report-1', expectedVersion: revision);
        await reports.approveReport('report-1', expectedVersion: revision);
        await reports.rejectReport('report-1', 'Source mismatch', expectedVersion: revision);
        await reviews.approveReview('report-1', expectedVersion: revision);
        await reviews.rejectReview('report-1', 'Source mismatch', expectedVersion: revision);
        final batch = requests.sublist(requests.length - 6);
        expect(batch.map((request) => request.method), ['PUT', 'POST', 'POST', 'POST', 'POST', 'POST']);
        expect(batch.map((request) => request.path), [
          '/reports/report-1', '/reports/report-1/submit-review',
          '/reports/report-1/approve', '/reports/report-1/reject',
          '/reviews/report-1/approve', '/reviews/report-1/reject',
        ]);
        expect(batch.map((request) => request.data), [
          {'expectedVersion': revision, 'title': 'Draft'},
          {'expectedVersion': revision}, {'expectedVersion': revision},
          {'reason': 'Source mismatch', 'expectedVersion': revision},
          {'expectedVersion': revision},
          {'reason': 'Source mismatch', 'expectedVersion': revision},
        ]);
      }
    });

    test('conflicts propagate without fetching or replaying mutations', () async {
      client.dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        requests.add(options);
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: 409,
            data: {'success': false, 'error': 'REPORT_CONFLICT', 'message': 'Reload report'}),
        ));
      }));
      final reports = ReportRemoteDataSource(apiClient: client);
      final reviews = ReviewRemoteDataSource(apiClient: client);
      final actions = <Future<ReportModel> Function()>[
        () => reports.updateReport('report-1', const ReportUpdateRequest(expectedVersion: 0, title: 'Draft')),
        () => reports.submitForReview('report-1', expectedVersion: 0),
        () => reports.approveReport('report-1', expectedVersion: 0),
        () => reports.rejectReport('report-1', 'Reason', expectedVersion: 0),
        () => reviews.approveReview('report-1', expectedVersion: 0),
        () => reviews.rejectReview('report-1', 'Reason', expectedVersion: 0),
      ];
      for (final action in actions) {
        await expectLater(action(), throwsA(isA<DioException>().having((error) => error.response?.statusCode, 'status', 409)));
      }
      expect(requests.length, actions.length);
      expect(requests.every((request) => request.data['expectedVersion'] == 0), isTrue);
      expect(requests.any((request) => request.method == 'GET'), isFalse);
    });
  });

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
