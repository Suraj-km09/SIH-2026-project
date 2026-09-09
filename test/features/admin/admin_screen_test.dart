import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/features/admin/admin_dashboard_screen.dart';
import 'package:mineintel_ai/features/admin/system_health_screen.dart';
import 'package:mineintel_ai/repositories/admin_repository.dart';
import 'package:mineintel_ai/state/admin_state.dart';

Widget createAdminHarness(Widget child) {
  return ProviderScope(
    overrides: [
      adminRepositoryProvider.overrideWithValue(MockAdminRepository()),
    ],
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('AdminRepository & MockAdminRepository Tests', () {
    final repository = MockAdminRepository();

    test('getStats returns metrics matching Screenshot 5', () async {
      final stats = await repository.getStats();
      expect(stats.totalValidations, equals(9));
      expect(stats.openValidations, equals(3));
      expect(stats.totalUsers, equals(36));
    });

    test('getSystemHealth returns all services online matching Screenshot 2', () async {
      final health = await repository.getSystemHealth();
      expect(health.backend, equals('Online'));
      expect(health.mongoDB, equals('Connected'));
      expect(health.aiProvider, equals('Online'));
      expect(health.vectorDB, equals('Online'));
    });

    test('getUsers returns seeded users list', () async {
      final users = await repository.getUsers();
      expect(users.length, greaterThanOrEqualTo(5));
      expect(users.any((u) => u.role == 'admin'), isTrue);
      expect(users.any((u) => u.role == 'user'), isTrue);
    });

    test('updateUserRole modifies user role successfully', () async {
      final updated = await repository.updateUserRole(userId: 'usr_001', role: 'admin');
      expect(updated.id, equals('usr_001'));
      expect(updated.role, equals('admin'));
    });
  });

  group('AdminDashboardScreen Widget Tests', () {
    testWidgets('Renders KPI cards, User Management count, and seeded users',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createAdminHarness(const AdminDashboardScreen()));
      await tester.pumpAndSettle();

      // Verify KPI Cards matching Platform Overview
      expect(find.text('TOTAL USERS'), findsOneWidget);
      expect(find.text('DOCUMENTS'), findsOneWidget);
      expect(find.text('INDEXED'), findsOneWidget);
      expect(find.text('REPORTS'), findsOneWidget);
      expect(find.text('VALIDATIONS'), findsOneWidget);
      expect(find.text('OPEN ISSUES'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Verify path text is removed from screen
      expect(find.textContaining('/admin/stats'), findsNothing);
      expect(find.textContaining('/admin/users'), findsNothing);
      expect(find.textContaining('Real-time platform activity'), findsOneWidget);

      // Verify User Management header & count
      expect(find.textContaining('User Management'), findsOneWidget);

      // Verify seeded user names from database
      expect(find.text('sih_audit_926871'), findsOneWidget);
      expect(find.text('Reyes'), findsOneWidget);
    });

    testWidgets('Tapping Role Filter opens modal bottom sheet with options',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createAdminHarness(const AdminDashboardScreen()));
      await tester.pumpAndSettle();

      // Tap Role Filter button (initially shows 'All Roles')
      final filterBtn = find.text('All Roles');
      expect(filterBtn, findsOneWidget);
      await tester.ensureVisible(filterBtn);
      await tester.pumpAndSettle();
      await tester.tap(filterBtn);
      await tester.pumpAndSettle();

      // Verify role options in bottom sheet matching Screenshot 5
      expect(find.text('User'), findsOneWidget);
      expect(find.text('Reviewer'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);

      // Select 'Admin' filter
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();

      // Filter button now reflects active selection
      expect(find.text('Admin'), findsOneWidget);
    });
  });

  group('SystemHealthScreen Widget Tests', () {
    testWidgets('Renders System Health header and all 4 infrastructure services',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createAdminHarness(const SystemHealthScreen()));
      await tester.pumpAndSettle();

      // Verify header matching Screenshot 2
      expect(find.text('System Health'), findsOneWidget);
      expect(
        find.text('Monitor critical system dependencies and infrastructure.'),
        findsOneWidget,
      );

      // Verify 4 infrastructure services matching Screenshot 2
      expect(find.textContaining('Backend'), findsOneWidget);
      expect(find.textContaining('MongoDB'), findsOneWidget);
      expect(find.textContaining('AI Provider'), findsOneWidget);
      expect(find.textContaining('Vector DB'), findsOneWidget);

      // Verify status badges
      expect(find.text('Online'), findsAtLeastNWidgets(1));
      expect(find.text('Connected'), findsAtLeastNWidgets(1));
    });
  });
}
