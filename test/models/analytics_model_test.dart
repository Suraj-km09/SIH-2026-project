import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/models/analytics_model.dart';

void main() {
  group('Analytics Models JSON Serialization Tests', () {
    test('AnalyticsOverviewModel parses correctly', () {
      final json = {
        'totalProduction': 14250.8,
        'totalDispatch': 13890.2,
        'netGap': 360.6,
        'productionTargetAchievement': 98.4,
        'topProducingMines': [
          {'mine': 'Rajmahal OCP', 'production': 4850.5},
        ],
      };

      final model = AnalyticsOverviewModel.fromJson(json);

      expect(model.totalProduction, 14250.8);
      expect(model.totalDispatch, 13890.2);
      expect(model.netGap, 360.6);
      expect(model.productionTargetAchievement, 98.4);
      expect(model.topProducingMines.length, 1);
      expect(model.topProducingMines.first.mine, 'Rajmahal OCP');
      expect(model.topProducingMines.first.production, 4850.5);

      final encoded = model.toJson();
      expect(encoded['totalProduction'], 14250.8);
      expect((encoded['topProducingMines'] as List).length, 1);
    });

    test('AnalyticsKpisModel parses correctly', () {
      final json = {
        'totalRecords': 142,
        'averageConfidence': 0.94,
        'verifiedRecords': 135,
        'targetAchievementPct': 98.4,
      };

      final kpis = AnalyticsKpisModel.fromJson(json);

      expect(kpis.totalRecords, 142);
      expect(kpis.averageConfidence, 0.94);
      expect(kpis.verifiedRecords, 135);
      expect(kpis.targetAchievementPct, 98.4);
    });

    test('ProductionAnalyticsModel & DispatchAnalyticsModel parse correctly', () {
      final prodJson = {
        'byMine': [
          {'mine': 'Rajmahal OCP', 'production': 4850.5}
        ],
        'bySubsidiary': [
          {'subsidiary': 'ECL', 'production': 7830.8}
        ],
        'byPeriod': [
          {'period': 'August 2026', 'production': 14250.8}
        ],
      };

      final prod = ProductionAnalyticsModel.fromJson(prodJson);
      expect(prod.byMine.first.mine, 'Rajmahal OCP');
      expect(prod.bySubsidiary.first.subsidiary, 'ECL');
      expect(prod.byPeriod.first.period, 'August 2026');

      final dispJson = {
        'byMine': [
          {'mine': 'Rajmahal OCP', 'dispatch': 4680.0}
        ],
        'bySubsidiary': [
          {'subsidiary': 'ECL', 'dispatch': 7570.2}
        ],
        'byPeriod': [
          {'period': 'August 2026', 'dispatch': 13890.2}
        ],
      };

      final disp = DispatchAnalyticsModel.fromJson(dispJson);
      expect(disp.byMine.first.mine, 'Rajmahal OCP');
      expect(disp.bySubsidiary.first.subsidiary, 'ECL');
      expect(disp.byPeriod.first.period, 'August 2026');
    });

    test('TrendItemModel parses correctly', () {
      final json = {
        'period': '2026-08',
        'production': 14250.8,
        'dispatch': 13890.2,
      };

      final trend = TrendItemModel.fromJson(json);
      expect(trend.period, '2026-08');
      expect(trend.production, 14250.8);
      expect(trend.dispatch, 13890.2);
    });

    test('VarianceItemModel computes isPositive correctly', () {
      final pos = VarianceItemModel.fromJson({
        'mine': 'Rajmahal',
        'parameter': 'Raw Coal',
        'target': 1400.0,
        'actual': 1420.5,
        'variance': 20.5,
        'variancePct': 1.46,
      });

      final neg = VarianceItemModel.fromJson({
        'mine': 'Sonepur',
        'parameter': 'Overburden',
        'target': 3800.0,
        'actual': 3620.0,
        'variance': -180.0,
        'variancePct': -4.74,
      });

      expect(pos.isPositive, isTrue);
      expect(neg.isPositive, isFalse);
    });

    test('AnomalyItemModel parses and evaluates severity flags', () {
      final model = AnomalyItemModel.fromJson({
        'type': 'STATISTICAL_OUTLIER_3SIGMA',
        'mine': 'Sonepur Bazari',
        'details': 'Overburden variance exceeded 3.2 sigma.',
        'severity': 'critical',
      });

      expect(model.type, 'STATISTICAL_OUTLIER_3SIGMA');
      expect(model.mine, 'Sonepur Bazari');
      expect(model.isCritical, isTrue);
      expect(model.isWarning, isFalse);
    });

    test('AnalyticsFilter generates query parameters correctly', () {
      const filter = AnalyticsFilter(
        subsidiary: 'ECL',
        mine: 'Rajmahal',
      );

      final params = filter.toQueryParams();
      expect(params['subsidiary'], 'ECL');
      expect(params['mine'], 'Rajmahal');
      expect(params.containsKey('period'), isFalse);
    });
  });
}
