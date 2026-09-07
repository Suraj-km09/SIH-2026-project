import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/repositories/auth_repository.dart';
import 'package:mineintel_ai/services/secure_storage_service.dart';
import 'package:mineintel_ai/state/app_state.dart';
import 'package:mineintel_ai/state/auth_state.dart';

/// Test-specific in-memory storage to prevent platform-channel dependency during unit tests.
class FakeSecureStorageService implements SecureStorageService {
  final Map<String, String> _memory = {};

  @override
  Future<void> saveToken(String token) async {
    _memory['jwt_token'] = token;
  }

  @override
  Future<String?> getToken() async => _memory['jwt_token'];

  @override
  Future<void> deleteToken() async {
    _memory.remove('jwt_token');
  }

  @override
  Future<void> saveUserSession({
    required String id,
    required String username,
    required String role,
  }) async {
    _memory['user_id'] = id;
    _memory['username'] = username;
    _memory['user_role'] = role;
  }

  @override
  Future<Map<String, String?>> getUserSession() async {
    return {
      'id': _memory['user_id'],
      'username': _memory['username'],
      'role': _memory['user_role'],
    };
  }

  @override
  Future<void> clearUserSession() async {
    _memory.clear();
  }

  @override
  Future<void> saveBaseUrlOverride(String url) async {
    _memory['custom_base_url'] = url;
  }

  @override
  Future<String?> getBaseUrlOverride() async => _memory['custom_base_url'];

  @override
  Future<void> saveMockDataToggle(bool enabled) async {
    _memory['use_mock_data'] = enabled.toString();
  }

  @override
  Future<bool> getMockDataToggle() async => _memory['use_mock_data'] == 'true';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('AuthNotifier & AuthState Tests', () {
    late FakeSecureStorageService fakeStorage;
    late MockAuthRepository mockAuthRepo;
    late ProviderContainer container;

    setUp(() {
      EnvConfig.useMockData = true;
      fakeStorage = FakeSecureStorageService();
      mockAuthRepo = MockAuthRepository();

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          secureStorageProvider.overrideWithValue(fakeStorage),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      EnvConfig.useMockData = false;
    });

    test('Initial state is AuthStatus.initial', () {
      final state = container.read(authNotifierProvider);
      expect(state.status, equals(AuthStatus.initial));
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
    });

    test('restoreSession with no stored token sets AuthStatus.unauthenticated', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.restoreSession();

      final state = container.read(authNotifierProvider);
      expect(state.status, equals(AuthStatus.unauthenticated));
      expect(state.isAuthenticated, isFalse);
    });

    test('restoreSession with stored token restores authenticated session', () async {
      await fakeStorage.saveToken('stored_valid_jwt_token');

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.restoreSession();

      final state = container.read(authNotifierProvider);
      expect(state.status, equals(AuthStatus.authenticated));
      expect(state.isAuthenticated, isTrue);
      expect(state.user, isNotNull);
      expect(state.user!.username, equals('mining_engineer'));
    });

    test('login with valid credentials stores token and authenticates user', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      final success = await notifier.login('admin', 'adminPassword123');

      expect(success, isTrue);
      final state = container.read(authNotifierProvider);
      expect(state.status, equals(AuthStatus.authenticated));
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.role, equals('admin'));
      expect(state.isAdmin, isTrue);

      final storedToken = await fakeStorage.getToken();
      expect(storedToken, equals('mock_jwt_token_login'));
    });

    test('register creates new account and authenticates', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      final success = await notifier.register('geologist_1', 'password123', 'geo@mine.com');

      expect(success, isTrue);
      final state = container.read(authNotifierProvider);
      expect(state.status, equals(AuthStatus.authenticated));
      expect(state.user?.username, equals('geologist_1'));
      expect(state.user?.email, equals('geo@mine.com'));
    });

    test('updateProfile updates user state without losing authentication', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.login('field_user', 'password123');

      final updated = await notifier.updateProfile(
        email: 'field_updated@mineintel.ai',
        department: 'Survey Team Alpha',
      );

      expect(updated, isTrue);
      final state = container.read(authNotifierProvider);
      expect(state.user?.email, equals('field_updated@mineintel.ai'));
      expect(state.user?.department, equals('Survey Team Alpha'));
    });

    test('logout purges stored token, session, and marks unauthenticated', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.login('mining_user', 'password123');

      expect(await fakeStorage.getToken(), isNotNull);

      await notifier.logout();

      final state = container.read(authNotifierProvider);
      expect(state.status, equals(AuthStatus.unauthenticated));
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);

      final tokenAfterLogout = await fakeStorage.getToken();
      expect(tokenAfterLogout, isNull);
    });
  });
}
