import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/features/analytics/analytics_screen.dart';
import 'package:mineintel_ai/models/analytics_model.dart';
import 'package:mineintel_ai/repositories/analytics_repository.dart';
import 'package:mineintel_ai/state/analytics_state.dart';

class FailingAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<AnalyticsOverviewModel> getOverview({AnalyticsFilter? filter}) async {
    throw Exception('Simulated network timeout connecting to /analytics/overview');
  }

  @override
  Future<AnalyticsKpisModel> getKpis({AnalyticsFilter? filter}) async {
    throw Exception('Simulated failure');
  }

  @override
  Future<ProductionAnalyticsModel> getProduction({AnalyticsFilter? filter}) async {
    throw Exception('Simulated failure');
  }

  @override
  Future<DispatchAnalyticsModel> getDispatch({AnalyticsFilter? filter}) async {
    throw Exception('Simulated failure');
  }

  @override
  Future<List<TrendItemModel>> getTrends({AnalyticsFilter? filter}) async => [];

  @override
  Future<List<VarianceItemModel>> getVariance({AnalyticsFilter? filter}) async => [];

  @override
  Future<List<AnomalyItemModel>> getAnomalies({AnalyticsFilter? filter}) async => [];
}

void main() {
  Widget buildAnalyticsTestHarness({AnalyticsRepository? repository}) {
    return ProviderScope(
      overrides: [
        analyticsRepositoryProvider.overrideWithValue(
          repository ?? MockAnalyticsRepository(),
        ),
      ],
      child: const MaterialApp(
        home: AnalyticsScreen(),
      ),
    );
  }

  group('AnalyticsScreen UI & State Tests', () {
    testWidgets('Renders KPI cards, trends chart, breakdowns, variance, and anomalies',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildAnalyticsTestHarness());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Title & Header
      expect(find.text('Mining Analytics & Production'), findsAtLeastNWidgets(1));
      expect(find.text('Refresh'), findsOneWidget);

      // Filter Bar
      expect(find.text('Filter By Subsidiary:'), findsOneWidget);
      expect(find.text('All Subsidiaries'), findsOneWidget);
      expect(find.text('ECL'), findsAtLeastNWidgets(1));

      // KPI cards
      expect(find.text('Total Production'), findsOneWidget);
      expect(find.text('Total Dispatch'), findsOneWidget);
      expect(find.text('Net Inventory Gap'), findsOneWidget);
      expect(find.text('Verified Extraction Records'), findsOneWidget);

      // Trends chart
      expect(find.text('Production vs Dispatch Trends'), findsOneWidget);
      expect(find.text('Production'), findsOneWidget);
      expect(find.text('Dispatch'), findsOneWidget);

      // Breakdowns
      expect(find.text('Production by Mine & Subsidiary'), findsOneWidget);
      expect(find.text('Dispatch & Evacuation Breakdown'), findsOneWidget);

      // Variance Table
      expect(find.text('Target vs Actual Variance'), findsOneWidget);

      // Anomalies
      expect(find.text('Statistical Anomalies & Outliers'), findsOneWidget);
      expect(find.text('PRODUCTION DISPATCH GAP'), findsOneWidget);
    });

    testWidgets('Displays ErrorStateWidget with retry on network failure',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildAnalyticsTestHarness(
        repository: FailingAnalyticsRepository(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Unable to Load Analytics'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });
  });
}
