import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/repositories/auth_repository.dart';

void main() {
  group('AuthRepository & MockAuthRepository Tests', () {
    late MockAuthRepository mockRepo;
    late AuthRepositoryImpl authRepo;

    setUp(() {
      mockRepo = MockAuthRepository();
      authRepo = AuthRepositoryImpl(mockRepository: mockRepo);
      EnvConfig.useMockData = true; // Test mock path deterministically
    });

    tearDown(() {
      EnvConfig.useMockData = false;
    });

    test('register returns AuthResultModel with user and token', () async {
      final result = await authRepo.register(
        username: 'new_geologist',
        password: 'SecurePassword123!',
        email: 'geologist@mineintel.ai',
      );

      expect(result.token, isNotEmpty);
      expect(result.user.username, equals('new_geologist'));
      expect(result.user.email, equals('geologist@mineintel.ai'));
      expect(result.user.role, equals('user'));
    });

    test('login with user, reviewer, and admin sets correct roles', () async {
      final userResult = await authRepo.login(
        username: 'john_doe',
        password: 'password123',
      );
      expect(userResult.user.role, equals('user'));

      final reviewerResult = await authRepo.login(
        username: 'reviewer',
        password: 'password123',
      );
      expect(reviewerResult.user.role, equals('reviewer'));
      expect(reviewerResult.user.isReviewer, isTrue);

      final adminResult = await authRepo.login(
        username: 'admin',
        password: 'adminPassword123',
      );
      expect(adminResult.user.role, equals('admin'));
      expect(adminResult.user.isAdmin, isTrue);
    });

    test('getMe returns current profile', () async {
      final me = await authRepo.getMe();
      expect(me.id, isNotEmpty);
      expect(me.username, isNotEmpty);
    });

    test('updateProfile updates email and department', () async {
      final updated = await authRepo.updateProfile(
        email: 'updated_email@mineintel.ai',
        department: 'Safety & Environmental',
      );

      expect(updated.email, equals('updated_email@mineintel.ai'));
      expect(updated.department, equals('Safety & Environmental'));
    });

    test('changePassword completes without error', () async {
      expect(
        authRepo.changePassword(
          currentPassword: 'oldPassword',
          newPassword: 'newPassword123',
        ),
        completes,
      );
    });

    test('refresh returns new token and user profile', () async {
      final refreshed = await authRepo.refresh('old_token');
      expect(refreshed.token, isNotEmpty);
      expect(refreshed.user, isNotNull);
    });

    test('logout completes successfully', () async {
      expect(authRepo.logout(), completes);
    });
  });
}
