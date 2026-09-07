import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/features/audit/audit_trail_screen.dart';
import 'package:mineintel_ai/models/user_model.dart';
import 'package:mineintel_ai/repositories/audit_repository.dart';
import 'package:mineintel_ai/state/auth_state.dart';

class _FakeAuthNotifier extends AuthNotifier {
  final UserModel _user;
  _FakeAuthNotifier(this._user);

  @override
  AuthState build() {
    return AuthState(status: AuthStatus.authenticated, user: _user);
  }
}

void main() {
  Widget buildAuditTestHarness({
    AuditRepository? repository,
    UserModel? user,
  }) {
    final effectiveUser = user ??
        const UserModel(
          id: 'usr-admin-01',
          username: 'admin',
          role: 'admin',
        );

    return ProviderScope(
      overrides: [
        auditRepositoryProvider.overrideWithValue(
          repository ?? MockAuditRepository(),
        ),
        authNotifierProvider.overrideWith(() => _FakeAuthNotifier(effectiveUser)),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: AuditTrailScreen(),
        ),
      ),
    );
  }

  group('Phase 11 AuditTrailScreen Widget Tests', () {
    setUp(() {
      EnvConfig.useMockData = true;
    });

    testWidgets('Renders role scope, stats cards, and audit event items for admin',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const adminUser = UserModel(
        id: 'usr-admin-01',
        username: 'admin',
        role: 'admin',
      );

      await tester.pumpWidget(buildAuditTestHarness(user: adminUser));
      await tester.pumpAndSettle();

      expect(find.text('Audit Trail & Provenance'), findsOneWidget);
      expect(find.text('ADMINISTRATOR SCOPE'), findsOneWidget);
      expect(find.text('Total Events'), findsOneWidget);
      expect(find.text('Successful'), findsOneWidget);
      expect(find.text('Failed Actions'), findsOneWidget);
      expect(find.text('Active Users'), findsOneWidget);

      expect(find.textContaining('APPROVE_REPORT'), findsWidgets);
    });

    testWidgets('Tapping Inspect button opens Audit Provenance Detail modal',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildAuditTestHarness());
      await tester.pumpAndSettle();

      expect(find.text('Inspect'), findsWidgets);
      await tester.tap(find.text('Inspect').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Audit Provenance Detail:'), findsOneWidget);
      expect(find.text('Event Payload (Details):'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('Tapping Export Logs opens statutory export dialog',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildAuditTestHarness());
      await tester.pumpAndSettle();

      expect(find.text('Export Logs'), findsOneWidget);
      await tester.tap(find.text('Export Logs'));
      await tester.pumpAndSettle();

      expect(find.text('Export Statutory Audit Trail'), findsOneWidget);
      expect(find.text('Export CSV'), findsOneWidget);
      expect(find.text('Export JSON'), findsOneWidget);
    });
  });
}
