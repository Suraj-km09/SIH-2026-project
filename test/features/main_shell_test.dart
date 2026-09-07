import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/features/shell/main_shell.dart';
import 'package:mineintel_ai/models/user_model.dart';
import 'package:mineintel_ai/repositories/analytics_repository.dart';
import 'package:mineintel_ai/repositories/auth_repository.dart';
import 'package:mineintel_ai/repositories/dashboard_repository.dart';
import 'package:mineintel_ai/services/secure_storage_service.dart';
import 'package:mineintel_ai/state/analytics_state.dart';
import 'package:mineintel_ai/state/app_state.dart';
import 'package:mineintel_ai/state/auth_state.dart';
import 'package:mineintel_ai/state/dashboard_state.dart';

class FakeMainShellStorage implements SecureStorageService {
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<String?> getToken() async => 'valid_token';
  @override
  Future<void> deleteToken() async {}
  @override
  Future<void> saveUserSession({required String id, required String username, required String role}) async {}
  @override
  Future<Map<String, String?>> getUserSession() async => {};
  @override
  Future<void> clearUserSession() async {}
  @override
  Future<void> saveBaseUrlOverride(String url) async {}
  @override
  Future<String?> getBaseUrlOverride() async => null;
  @override
  Future<void> saveMockDataToggle(bool enabled) async {}
  @override
  Future<bool> getMockDataToggle() async => false;
}

class TestRoleNotifier extends AuthNotifier {
  final UserModel _user;
  TestRoleNotifier(this._user);

  @override
  AuthState build() => AuthState.authenticated(_user);
}

void main() {
  Widget createShellForUser(UserModel user, {Size size = const Size(1440, 1080)}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        dashboardRepositoryProvider.overrideWithValue(const MockDashboardRepository()),
        analyticsRepositoryProvider.overrideWithValue(const MockAnalyticsRepository()),
        secureStorageProvider.overrideWithValue(FakeMainShellStorage()),
        authNotifierProvider.overrideWith(() => TestRoleNotifier(user)),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: const MainShell(),
        ),
      ),
    );
  }

  group('MainShell Navigation & RBAC Tests', () {
    testWidgets('Desktop layout renders persistent sidebar with sections and branding',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const user = UserModel(
        id: 'u1',
        username: 'mining_eng',
        email: 'eng@mine.com',
        role: 'user',
        department: 'Operations',
        status: 'active',
      );

      await tester.pumpWidget(createShellForUser(user));
      await tester.pump();

      expect(find.text('MineIntel AI'), findsOneWidget);
      expect(find.text('Mining Intelligence Platform'), findsOneWidget);
      expect(find.text('OPERATIONS'), findsOneWidget);
      expect(find.text('INTELLIGENCE & AI'), findsOneWidget);
      expect(find.text('GOVERNANCE'), findsOneWidget);
      expect(find.text('SYSTEM'), findsOneWidget);

      // Verify standard operations modules
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Command Centre'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Data Extraction'), findsOneWidget);
      expect(find.text('Validation'), findsOneWidget);

      // For standard user: Review Queue and Admin Console MUST NOT be exposed
      expect(find.text('Review Queue'), findsNothing);
      expect(find.text('Admin Console'), findsNothing);
    });

    testWidgets('Reviewer role exposes Review Queue but hides Admin Console',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const reviewer = UserModel(
        id: 'r1',
        username: 'chief_reviewer',
        email: 'reviewer@mine.com',
        role: 'reviewer',
        department: 'Statutory Directorate',
        status: 'active',
      );

      await tester.pumpWidget(createShellForUser(reviewer));
      await tester.pump();

      // Review Queue visible for reviewer
      expect(find.text('Review Queue'), findsOneWidget);
      // Admin Console hidden for reviewer
      expect(find.text('Admin Console'), findsNothing);
    });

    testWidgets('Admin role exposes both Review Queue and Admin Console',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const admin = UserModel(
        id: 'a1',
        username: 'director_general',
        email: 'dg@mine.com',
        role: 'admin',
        department: 'Ministry of Mines',
        status: 'active',
      );

      await tester.pumpWidget(createShellForUser(admin));
      await tester.pump();

      // Both governance items visible for admin
      expect(find.text('Review Queue'), findsOneWidget);
      expect(find.text('Admin Console'), findsOneWidget);
    });

    testWidgets('Tapping sidebar item updates active module placeholder',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const user = UserModel(
        id: 'u1',
        username: 'mining_eng',
        email: 'eng@mine.com',
        role: 'user',
        department: 'Operations',
        status: 'active',
      );

      await tester.pumpWidget(createShellForUser(user));
      await tester.pump();

      // Initially on Dashboard
      expect(find.text('Executive Dashboard'), findsAtLeastNWidgets(1));

      // Tap Command Centre
      await tester.tap(find.text('Command Centre'));
      await tester.pump();

      expect(find.text('Command Centre'), findsAtLeastNWidgets(1));
      expect(
        find.textContaining('Real-time ingestion pipeline telemetry'),
        findsOneWidget,
      );
    });

    testWidgets('Mobile viewport renders BottomNavigationBar and top AppBar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const user = UserModel(
        id: 'u1',
        username: 'mobile_user',
        email: 'm@mine.com',
        role: 'user',
        department: 'Field Work',
        status: 'active',
      );

      await tester.pumpWidget(createShellForUser(user, size: const Size(400, 800)));
      await tester.pump();

      // Mobile bottom bar destinations
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Assistant'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });
  });
}
