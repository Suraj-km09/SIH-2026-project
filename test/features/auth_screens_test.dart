import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/features/auth/login_screen.dart';
import 'package:mineintel_ai/features/auth/profile_screen.dart';
import 'package:mineintel_ai/features/auth/register_screen.dart';
import 'package:mineintel_ai/features/auth/splash_screen.dart';
import 'package:mineintel_ai/models/user_model.dart';
import 'package:mineintel_ai/repositories/auth_repository.dart';
import 'package:mineintel_ai/services/secure_storage_service.dart';
import 'package:mineintel_ai/state/app_state.dart';
import 'package:mineintel_ai/state/auth_state.dart';

class FakeTestStorage implements SecureStorageService {
  final Map<String, String> _mem = {};

  @override
  Future<void> saveToken(String token) async => _mem['token'] = token;

  @override
  Future<String?> getToken() async => _mem['token'];

  @override
  Future<void> deleteToken() async => _mem.remove('token');

  @override
  Future<void> saveUserSession({
    required String id,
    required String username,
    required String role,
  }) async {
    _mem['id'] = id;
    _mem['username'] = username;
    _mem['role'] = role;
  }

  @override
  Future<Map<String, String?>> getUserSession() async => {
        'id': _mem['id'],
        'username': _mem['username'],
        'role': _mem['role'],
      };

  @override
  Future<void> clearUserSession() async => _mem.clear();

  @override
  Future<void> saveBaseUrlOverride(String url) async => _mem['url'] = url;

  @override
  Future<String?> getBaseUrlOverride() async => _mem['url'];

  @override
  Future<void> saveMockDataToggle(bool enabled) async =>
      _mem['mock'] = enabled.toString();

  @override
  Future<bool> getMockDataToggle() async => _mem['mock'] == 'true';
}

class TestAuthNotifier extends AuthNotifier {
  final UserModel? _customUser;
  TestAuthNotifier([this._customUser]);

  @override
  AuthState build() {
    if (_customUser != null) {
      return AuthState.authenticated(_customUser);
    }
    return super.build();
  }
}

void main() {
  late MockAuthRepository mockRepo;
  late FakeTestStorage fakeStorage;

  setUp(() {
    mockRepo = MockAuthRepository();
    fakeStorage = FakeTestStorage();
  });

  Widget wrapWithScope(Widget child, {UserModel? user}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
        secureStorageProvider.overrideWithValue(fakeStorage),
        if (user != null)
          authNotifierProvider.overrideWith(() => TestAuthNotifier(user)),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Authentication Screens UI Tests', () {
    testWidgets('SplashScreen renders branding, status, and initiates session restoration',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithScope(const SplashScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('MineIntel AI'), findsOneWidget);
      expect(find.text('Mining Intelligence & Statutory Compliance Platform'), findsOneWidget);
    });

    testWidgets('LoginScreen renders inputs, buttons, and demo chips',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithScope(const LoginScreen()));
      await tester.pump();

      expect(find.text('Welcome to MineIntel AI'), findsOneWidget);
      expect(find.text('Username / User ID'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In to Workspace'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Register Now'), findsOneWidget);

      // Quick role chips
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Reviewer'), findsOneWidget);
      expect(find.text('User'), findsOneWidget);
    });

    testWidgets('LoginScreen validates empty inputs when submitted',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithScope(const LoginScreen()));
      await tester.pump();

      // Ensure button visible and tap Sign In without filling form
      await tester.ensureVisible(find.text('Sign In to Workspace'));
      await tester.tap(find.text('Sign In to Workspace'));
      await tester.pump();

      expect(find.text('Username is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('LoginScreen validates password shorter than 6 characters',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithScope(const LoginScreen()));
      await tester.pump();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'admin');
      await tester.enterText(textFields.at(1), '123'); // < 6 chars
      await tester.pump();

      await tester.ensureVisible(find.text('Sign In to Workspace'));
      await tester.tap(find.text('Sign In to Workspace'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('LoginScreen displays user-friendly error message on incorrect credentials without technical headers',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithScope(const LoginScreen()));
      await tester.pump();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'admin');
      await tester.enterText(textFields.at(1), 'wrongpassword123');
      await tester.pump();

      await tester.ensureVisible(find.text('Sign In to Workspace'));
      await tester.tap(find.text('Sign In to Workspace'));
      await tester.pump(); // Start request

      // Verify button switches to loading state with spinner
      expect(find.text('Signing In...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300)); // Complete mock delayed login
      await tester.pumpAndSettle();

      // Verify loader stops and button resets
      expect(find.text('Sign In to Workspace'), findsOneWidget);

      // Verify user-friendly error message is displayed and technical error types are NOT shown
      expect(find.text('Authentication Failed'), findsNothing);
      expect(find.text('Validation Error'), findsNothing);
      expect(find.text('DioException'), findsNothing);
      expect(find.textContaining('Invalid username or password'), findsWidgets);
    });

    testWidgets('LoginScreen ignores repeated button taps while authentication is in progress',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithScope(const LoginScreen()));
      await tester.pump();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'admin');
      await tester.enterText(textFields.at(1), 'admin123');
      await tester.pump();

      // Tap once
      await tester.tap(find.text('Sign In to Workspace'));
      await tester.pump();

      // Verify loading state
      expect(find.text('Signing In...'), findsOneWidget);

      // Attempt rapid second and third taps while loading
      await tester.tap(find.text('Signing In...'), warnIfMissed: false);
      await tester.tap(find.text('Signing In...'), warnIfMissed: false);
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify successful sign-in
      expect(find.textContaining('Signed in successfully'), findsOneWidget);
    });

    testWidgets('RegisterScreen renders all documented fields and validates password mismatch',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithScope(const RegisterScreen()));
      await tester.pump();

      expect(find.text('Create MineIntel Account'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Email (Optional)'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);

      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(4));

      // Fill mismatched passwords
      await tester.enterText(textFields.at(0), 'geologist_alex');
      await tester.enterText(textFields.at(2), 'password123');
      await tester.enterText(textFields.at(3), 'mismatchedPass');
      await tester.pump();

      await tester.ensureVisible(find.text('Create Account'));
      await tester.tap(find.text('Create Account'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('RegisterScreen shows loader and ignores repeated button taps during registration',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithScope(const RegisterScreen()));
      await tester.pump();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'geologist_alex');
      await tester.enterText(textFields.at(1), 'alex@mineintel.ai');
      await tester.enterText(textFields.at(2), 'password123');
      await tester.enterText(textFields.at(3), 'password123');
      await tester.pump();

      await tester.ensureVisible(find.text('Create Account'));
      await tester.tap(find.text('Create Account'));
      await tester.pump(); // Start submission

      // Verify button switches to loading state
      expect(find.text('Creating Account...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Attempt repeated tap while loading
      await tester.tap(find.text('Creating Account...'), warnIfMissed: false);
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify success and that technical error headers are NOT shown
      expect(find.textContaining('Account created successfully'), findsOneWidget);
      expect(find.text('Registration Error'), findsNothing);
      expect(find.text('Validation Error'), findsNothing);
    });

    testWidgets('ProfileScreen renders user details, role badge, and update forms',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const testUser = UserModel(
        id: 'usr_test_1',
        username: 'mining_specialist',
        email: 'specialist@mineintel.ai',
        role: 'reviewer',
        department: 'Statutory Directorate',
        status: 'active',
      );

      await tester.pumpWidget(
        wrapWithScope(
          const Scaffold(body: ProfileScreen()),
          user: testUser,
        ),
      );
      await tester.pump();

      expect(find.text('mining_specialist'), findsOneWidget);
      expect(find.text('specialist@mineintel.ai'), findsAtLeastNWidgets(1));
      expect(find.text('Department: Statutory Directorate'), findsOneWidget);
      expect(find.text('Profile Information'), findsOneWidget);
      expect(find.text('Security & Password'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
    });
  });
}
