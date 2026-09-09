import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/core/errors/exceptions.dart';
import 'package:mineintel_ai/network/auth_interceptor.dart';

void main() {
  group('AuthInterceptor Error Mapping Tests', () {
    late AuthInterceptor interceptor;

    setUp(() {
      interceptor = AuthInterceptor(dio: Dio());
    });

    test('Maps timeout DioException types to TimeoutException', () {
      final reqOpts = RequestOptions(path: '/test');

      final connectTimeout = DioException(
        requestOptions: reqOpts,
        type: DioExceptionType.connectionTimeout,
      );
      expect(interceptor.mapDioException(connectTimeout), isA<TimeoutException>());

      final receiveTimeout = DioException(
        requestOptions: reqOpts,
        type: DioExceptionType.receiveTimeout,
      );
      expect(interceptor.mapDioException(receiveTimeout), isA<TimeoutException>());

      final sendTimeout = DioException(
        requestOptions: reqOpts,
        type: DioExceptionType.sendTimeout,
      );
      expect(interceptor.mapDioException(sendTimeout), isA<TimeoutException>());
    });

    test('Maps connectionError to NetworkException', () {
      final reqOpts = RequestOptions(path: '/test');
      final connErr = DioException(
        requestOptions: reqOpts,
        type: DioExceptionType.connectionError,
      );
      expect(interceptor.mapDioException(connErr), isA<NetworkException>());
    });

    test('Maps 400 bad request to ValidationException', () {
      final reqOpts = RequestOptions(path: '/test');
      final res = Response(
        requestOptions: reqOpts,
        statusCode: 400,
        data: {'error': 'VALIDATION_ERROR', 'message': 'Password too short'},
      );
      final err = DioException(requestOptions: reqOpts, response: res);

      final appEx = interceptor.mapDioException(err);
      expect(appEx, isA<ValidationException>());
      expect(appEx.message, equals('Password too short'));
    });

    test('Maps 401 TOKEN_EXPIRED to TokenExpiredException', () {
      final reqOpts = RequestOptions(path: '/test');
      final res = Response(
        requestOptions: reqOpts,
        statusCode: 401,
        data: {'error': 'TOKEN_EXPIRED', 'message': 'Token expired'},
      );
      final err = DioException(requestOptions: reqOpts, response: res);

      final appEx = interceptor.mapDioException(err);
      expect(appEx, isA<TokenExpiredException>());
    });

    test('Maps 401 generic to AuthException', () {
      final reqOpts = RequestOptions(path: '/test');
      final res = Response(
        requestOptions: reqOpts,
        statusCode: 401,
        data: {'error': 'INVALID_CREDENTIALS', 'message': 'Invalid username or password'},
      );
      final err = DioException(requestOptions: reqOpts, response: res);

      final appEx = interceptor.mapDioException(err);
      expect(appEx, isA<AuthException>());
      expect(appEx.message, equals('Invalid username or password'));
      expect((appEx as AuthException).isIncorrectPassword, isTrue);
    });

    test('Maps 400 Mongoose Validation Error with multiple field statements', () {
      final reqOpts = RequestOptions(path: '/api/v1/auth/login');
      final res = Response(
        requestOptions: reqOpts,
        statusCode: 400,
        data: {
          'success': false,
          'message': 'Validation failed: Field "username" is required and must be a string; Field "password" is required and must be at least 6 characters',
          'error': 'Field "username" is required and must be a string; Field "password" is required and must be at least 6 characters',
        },
      );
      final err = DioException(requestOptions: reqOpts, response: res);

      final appEx = interceptor.mapDioException(err);
      expect(appEx, isA<ValidationException>());
      final valEx = appEx as ValidationException;
      expect(valEx.fieldErrors, isNotNull);
      expect(valEx.fieldErrors!['username'], contains('required'));
      expect(valEx.fieldErrors!['password'], contains('required'));
    });

    test('Maps 403 ACCOUNT_INACTIVE to PermissionException with isAccountInactive flag', () {
      final reqOpts = RequestOptions(path: '/api/v1/auth/login');
      final res = Response(
        requestOptions: reqOpts,
        statusCode: 403,
        data: {
          'success': false,
          'message': 'Account is suspended or inactive',
          'error': 'ACCOUNT_INACTIVE',
        },
      );
      final err = DioException(requestOptions: reqOpts, response: res);

      final appEx = interceptor.mapDioException(err);
      expect(appEx, isA<PermissionException>());
      final permEx = appEx as PermissionException;
      expect(permEx.isAccountInactive, isTrue);
    });

    test('Maps 403 to PermissionException', () {
      final reqOpts = RequestOptions(path: '/test');
      final res = Response(
        requestOptions: reqOpts,
        statusCode: 403,
        data: {'message': 'Insufficient role permissions for admin route'},
      );
      final err = DioException(requestOptions: reqOpts, response: res);

      final appEx = interceptor.mapDioException(err);
      expect(appEx, isA<PermissionException>());
      expect(appEx.message, contains('Insufficient role'));
    });

    test('Maps 404 to NotFoundException', () {
      final reqOpts = RequestOptions(path: '/test');
      final res = Response(
        requestOptions: reqOpts,
        statusCode: 404,
        data: {'message': 'Document not found'},
      );
      final err = DioException(requestOptions: reqOpts, response: res);

      final appEx = interceptor.mapDioException(err);
      expect(appEx, isA<NotFoundException>());
    });

    test('Maps 409 to ConflictException (Duplicate & Agent Concurrency)', () {
      final reqOpts = RequestOptions(path: '/test');
      final resDup = Response(
        requestOptions: reqOpts,
        statusCode: 409,
        data: {'error': 'DUPLICATE_DOCUMENT', 'message': 'Document already uploaded'},
      );
      final errDup = DioException(requestOptions: reqOpts, response: resDup);
      final appExDup = interceptor.mapDioException(errDup);
      expect(appExDup, isA<ConflictException>());
      expect((appExDup as ConflictException).isDuplicateDocument, isTrue);

      final resAgent = Response(
        requestOptions: reqOpts,
        statusCode: 409,
        data: {'error': 'CONCURRENCY_CONFLICT', 'message': 'Document is currently being processed by another agent.'},
      );
      final errAgent = DioException(requestOptions: reqOpts, response: resAgent);
      final appExAgent = interceptor.mapDioException(errAgent);
      expect(appExAgent, isA<ConflictException>());
      expect((appExAgent as ConflictException).isAgentConcurrency, isTrue);
    });

    test('Maps 503 to ServiceUnavailableException', () {
      final reqOpts = RequestOptions(path: '/test');
      final res = Response(
        requestOptions: reqOpts,
        statusCode: 503,
        data: {'message': 'Database connecting, retry shortly'},
      );
      final err = DioException(requestOptions: reqOpts, response: res);

      final appEx = interceptor.mapDioException(err);
      expect(appEx, isA<ServiceUnavailableException>());
    });

    test('Maps 500 to ServerException', () {
      final reqOpts = RequestOptions(path: '/test');
      final res = Response(
        requestOptions: reqOpts,
        statusCode: 500,
        data: {'message': 'Internal database failure'},
      );
      final err = DioException(requestOptions: reqOpts, response: res);

      final appEx = interceptor.mapDioException(err);
      expect(appEx, isA<ServerException>());
    });
  });
}
