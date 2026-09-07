import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/features/notifications/notification_center_screen.dart';
import 'package:mineintel_ai/repositories/notification_repository.dart';

void main() {
  Widget buildNotificationCenterTestHarness({
    NotificationRepository? repository,
  }) {
    return ProviderScope(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(
          repository ?? MockNotificationRepository(),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: NotificationCenterScreen(),
        ),
      ),
    );
  }

  group('Phase 11 NotificationCenterScreen Widget Tests', () {
    setUp(() {
      EnvConfig.useMockData = true;
    });

    testWidgets('Renders header, unread badge, filter chips, and notification cards',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildNotificationCenterTestHarness());
      await tester.pumpAndSettle();

      expect(find.text('Notification Center'), findsOneWidget);
      expect(find.textContaining('unread'), findsWidgets);
      expect(find.text('All Alerts'), findsOneWidget);
      expect(find.text('Approvals'), findsOneWidget);
      expect(find.text('Critical Alerts'), findsOneWidget);

      expect(find.textContaining('Quarterly Coal Production Compliance'), findsOneWidget);
      expect(find.textContaining('Critical validation error'), findsOneWidget);
    });

    testWidgets('Tapping Mark All Read marks all alerts as read',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = MockNotificationRepository();
      await tester.pumpWidget(
        buildNotificationCenterTestHarness(repository: repo),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mark All Read'), findsOneWidget);
      await tester.tap(find.text('Mark All Read'));
      await tester.pumpAndSettle();

      expect(find.text('All caught up'), findsOneWidget);
    });

    testWidgets('Tapping category filter chip filters notifications list',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildNotificationCenterTestHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Approvals'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Quarterly Coal Production Compliance'), findsOneWidget);
      expect(find.textContaining('DGMS Safety Inspection directive'), findsNothing);
    });
  });
}
