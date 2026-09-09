import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/app.dart';
import 'package:mineintel_ai/features/auth/login_screen.dart';
import 'package:mineintel_ai/features/auth/splash_screen.dart';
import 'package:mineintel_ai/repositories/auth_repository.dart';
import 'package:mineintel_ai/services/secure_storage_service.dart';
import 'package:mineintel_ai/state/app_state.dart';
import 'package:mineintel_ai/state/auth_state.dart';

class TestStorage implements SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> saveToken(String token) async => _data['token'] = token;

  @override
  Future<String?> getToken() async => _data['token'];

  @override
  Future<void> deleteToken() async => _data.remove('token');

  @override
  Future<void> saveUserSession({
    required String id,
    required String username,
    required String role,
  }) async {
    _data['id'] = id;
    _data['username'] = username;
    _data['role'] = role;
  }

  @override
  Future<Map<String, String?>> getUserSession() async => {
        'id': _data['id'],
        'username': _data['username'],
        'role': _data['role'],
      };

  @override
  Future<void> clearUserSession() async => _data.clear();

  @override
  Future<void> saveBaseUrlOverride(String url) async => _data['url'] = url;

  @override
  Future<String?> getBaseUrlOverride() async => _data['url'];

  @override
  Future<void> saveMockDataToggle(bool enabled) async =>
      _data['mock'] = enabled.toString();

  @override
  Future<bool> getMockDataToggle() async => _data['mock'] == 'true';
}

void main() {
  late MockAuthRepository mockRepo;
  late TestStorage testStorage;

  setUp(() {
    mockRepo = MockAuthRepository();
    testStorage = TestStorage();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
        secureStorageProvider.overrideWithValue(testStorage),
      ],
      child: const MaterialApp(
        home: AppGateway(),
      ),
    );
  }

  group('AppGateway Navigation & Screen Persistence Tests', () {
    testWidgets('Initial app launch displays SplashScreen and restores session to LoginScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());

      // On initial build, SplashScreen is rendered
      expect(find.byType(SplashScreen), findsOneWidget);

      // Settle session restoration
      await tester.pumpAndSettle();

      // Transitions to LoginScreen without error
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    });

    testWidgets('LoginScreen stays mounted during login attempt and does NOT flash to SplashScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(); // Settle to LoginScreen

      expect(find.byType(LoginScreen), findsOneWidget);

      // Enter incorrect credentials
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'admin');
      await tester.enterText(textFields.at(1), 'wrongpassword123');
      await tester.pump();

      // Tap Sign In
      await tester.ensureVisible(find.text('Sign In to Workspace'));
      await tester.tap(find.text('Sign In to Workspace'));
      await tester.pump(); // Initiate request

      // CRITICAL ASSERTION: LoginScreen MUST remain mounted, SplashScreen must NOT appear!
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);

      // Button must show the circular loader and "Signing In..."
      expect(find.text('Signing In...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the mock login request
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // LoginScreen remains mounted and displays the clean error message
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.textContaining('Invalid username or password'), findsWidgets);
      expect(find.text('Authentication Failed'), findsNothing);
      expect(find.text('Validation Error'), findsNothing);
    });
  });
}
