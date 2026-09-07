import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/features/analytics/widgets/trends_chart_card.dart';
import 'package:mineintel_ai/features/auth/login_screen.dart';
import 'package:mineintel_ai/features/dashboard/dashboard_screen.dart';
import 'package:mineintel_ai/features/shell/main_shell.dart';
import 'package:mineintel_ai/features/validation/widgets/issue_resolution_dialog.dart';
import 'package:mineintel_ai/features/validation/widgets/review_decision_dialog.dart';
import 'package:mineintel_ai/models/analytics_model.dart';
import 'package:mineintel_ai/models/user_model.dart';
import 'package:mineintel_ai/models/validation_issue_model.dart';
import 'package:mineintel_ai/repositories/analytics_repository.dart';
import 'package:mineintel_ai/repositories/auth_repository.dart';
import 'package:mineintel_ai/repositories/dashboard_repository.dart';
import 'package:mineintel_ai/services/secure_storage_service.dart';
import 'package:mineintel_ai/state/analytics_state.dart';
import 'package:mineintel_ai/state/app_state.dart';
import 'package:mineintel_ai/state/auth_state.dart';
import 'package:mineintel_ai/state/dashboard_state.dart';

class FakeResponsiveAuditStorage implements SecureStorageService {
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<String?> getToken() async => 'mock_token';
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

class TestAuthRoleNotifier extends AuthNotifier {
  final UserModel _user;
  TestAuthRoleNotifier(this._user);

  @override
  AuthState build() => AuthState.authenticated(_user);
}

void main() {
  const testAdmin = UserModel(
    id: 'usr-admin-01',
    username: 'admin',
    email: 'admin@coalindia.gov.in',
    role: 'admin',
    department: 'Mining Operations',
    status: 'active',
  );

  Widget createHarness(
    Widget child, {
    UserModel? user,
    Size? size,
  }) {
    final activeUser = user ?? testAdmin;
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        dashboardRepositoryProvider.overrideWithValue(const MockDashboardRepository()),
        analyticsRepositoryProvider.overrideWithValue(const MockAnalyticsRepository()),
        secureStorageProvider.overrideWithValue(FakeResponsiveAuditStorage()),
        authNotifierProvider.overrideWith(() => TestAuthRoleNotifier(activeUser)),
      ],
      child: MaterialApp(
        home: size != null
            ? MediaQuery(
                data: MediaQueryData(size: size),
                child: child,
              )
            : child,
      ),
    );
  }

  group('PHASE 12 Responsive UI Audit Across Form Factors', () {
    // -------------------------------------------------------------------------
    // 1. Small Android Phone (320x640, 360x780)
    // -------------------------------------------------------------------------
    testWidgets('1. Small Android Phone (320x640): Dashboard renders without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHarness(const DashboardScreen(), size: const Size(320, 640)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Executive Dashboard'), findsAtLeastNWidgets(1));
      expect(find.text('Total Documents'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1b. Small Android Phone (320x640): MainShell shows bottom nav and compact actions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHarness(const MainShell(), size: const Size(320, 640)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // In mobile view (< 600dp), Material 3 NavigationBar is used
      expect(find.byType(NavigationBar), findsOneWidget);
      // Compact popup menu button is rendered in the app bar
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1c. Small Android Phone (360x780): LoginScreen renders with responsive padding',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHarness(const LoginScreen(), size: const Size(360, 780)));
      await tester.pump();

      expect(find.text('Welcome to MineIntel AI'), findsOneWidget);
      expect(find.text('Sign In to Workspace'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Reviewer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // -------------------------------------------------------------------------
    // 2. Large Android / iPhone (393x852, 412x915)
    // -------------------------------------------------------------------------
    testWidgets('2. Large Phone (412x915): AnalyticsTrendsChartCard wraps legend cleanly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final dummyTrends = [
        TrendItemModel(period: 'Jan', production: 12000, dispatch: 11000),
        TrendItemModel(period: 'Feb', production: 14000, dispatch: 13500),
        TrendItemModel(period: 'Mar', production: 15500, dispatch: 15000),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(412, 915)),
            child: Scaffold(
              body: AnalyticsTrendsChartCard(trends: dummyTrends),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Production vs Dispatch Trends'), findsOneWidget);
      expect(find.text('Production'), findsOneWidget);
      expect(find.text('Dispatch'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // -------------------------------------------------------------------------
    // 3. Tablet (768x1024)
    // -------------------------------------------------------------------------
    testWidgets('3. Tablet (768x1024): MainShell displays NavigationRail and More sheet',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHarness(const MainShell(), size: const Size(768, 1024)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tablet view (600 <= width < 1024) renders NavigationRail
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);

      // Tap "More" item (index 4 on rail) to open sheet
      await tester.tap(find.text('More'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify bottom sheet opened with operations
      expect(find.text('More Operations & Governance'), findsOneWidget);
      expect(find.text('Data Extraction'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // -------------------------------------------------------------------------
    // 4. Windows Desktop (1280x800, 1920x1080)
    // -------------------------------------------------------------------------
    testWidgets('4. Windows Desktop (1280x800): MainShell displays full Desktop Sidebar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHarness(const MainShell(), size: const Size(1280, 800)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Desktop view (>= 1024) renders sidebar without NavigationRail or BottomNavigationBar
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('MineIntel AI'), findsOneWidget);
      expect(find.text('OPERATIONS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // -------------------------------------------------------------------------
    // 5. Landscape Layout (800x360)
    // -------------------------------------------------------------------------
    testWidgets('5. Phone Landscape (800x360): Responsive scaffold and dialogs fit smoothly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHarness(const DashboardScreen(), size: const Size(800, 360)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Executive Dashboard'), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    });

    // -------------------------------------------------------------------------
    // 6. Dialogs Responsiveness & Sizing
    // -------------------------------------------------------------------------
    testWidgets('6a. IssueResolutionDialog renders with scrollable content and wrapped actions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final dummyIssue = ValidationIssueModel(
        id: 'ISS-001',
        documentId: 'doc_001',
        type: 'math_error',
        severity: 'high',
        field: 'total_production',
        message: 'Sum of coal blocks exceeds declared total',
        currentValue: '12500',
        suggestedValue: '12400',
        status: 'open',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => IssueResolutionDialog.show(
                  context,
                  issue: dummyIssue,
                  onSave: (req) async => true,
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Resolve Validation Issue'), findsOneWidget);
      expect(find.text('Save Resolution'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('6b. ReviewDecisionDialog renders with scrollable options and wrapped actions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ReviewDecisionDialog.show(
                  context,
                  documentId: 'DOC-DGMS-001',
                  onSubmit: (req) async => true,
                ),
                child: const Text('Open Review Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Review Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Submit Review Decision'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Submit Decision'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
