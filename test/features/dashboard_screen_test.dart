import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/features/dashboard/dashboard_screen.dart';
import 'package:mineintel_ai/models/dashboard_model.dart';
import 'package:mineintel_ai/repositories/dashboard_repository.dart';
import 'package:mineintel_ai/state/dashboard_state.dart';

class FailingDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardOverviewModel> getOverview() async {
    throw Exception('Simulated network timeout connecting to /dashboard/overview');
  }

  @override
  Future<DashboardKpisModel> getKpis() async {
    throw Exception('Simulated network failure');
  }

  @override
  Future<List<DashboardActivityModel>> getActivity({int limit = 15}) async => [];

  @override
  Future<List<DashboardAlertModel>> getAlerts() async => [];

  @override
  Future<List<DashboardRecentDocumentModel>> getRecentDocuments({int limit = 10}) async => [];
}

void main() {
  Widget buildDashboardTestHarness({DashboardRepository? repository}) {
    return ProviderScope(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(
          repository ?? MockDashboardRepository(),
        ),
      ],
      child: const MaterialApp(
        home: DashboardScreen(),
      ),
    );
  }

  group('DashboardScreen UI & State Tests', () {
    testWidgets('Renders KPI cards, alerts, documents, and recent activity',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildDashboardTestHarness());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Title & Subtitle
      expect(find.text('Executive Dashboard'), findsAtLeastNWidgets(1));
      expect(find.text('Refresh'), findsOneWidget);

      // KPI cards
      expect(find.text('Total Documents'), findsOneWidget);
      expect(find.text('Extraction Accuracy'), findsOneWidget);
      expect(find.text('Average Quality Score'), findsOneWidget);
      expect(find.text('Compliance Rate'), findsOneWidget);

      // Multi-section cards
      expect(find.text('Urgent Alerts & Anomalies'), findsOneWidget);
      expect(find.text('Validation & Processing Highlights'), findsOneWidget);
      expect(find.text('Recent Ingested Documents'), findsOneWidget);
      expect(find.text('Recent Audit Activity'), findsOneWidget);

      // Specific data from mock
      expect(find.text('Production Target Deficit'), findsOneWidget);
      expect(find.text('Rajmahal_OCP_Production_Report_August_2026.pdf'), findsOneWidget);
      expect(find.text('UPLOAD DOCUMENT'), findsOneWidget);
    });

    testWidgets('Displays ErrorStateWidget with retry on network failure',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildDashboardTestHarness(
        repository: FailingDashboardRepository(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Unable to Load Dashboard'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });
  });
}
