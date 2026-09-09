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

    test('AnalyticsOverviewModel parses live backend payload with periods correctly', () {
      final liveOverview = {
        'totalDocuments': 11,
        'totalRecords': 78,
        'totalProduction': 203635.6,
        'totalDispatch': 163915.6,
        'totalTarget': 71067.4,
        'productionDispatchGap': 39720,
        'achievementRate': 286.54,
        'averageValidationScore': '97%',
        'openIssues': 48,
        'periods': [
          {
            'period': '2021',
            'production': 20.4,
            'dispatch': 19.6,
            'target': 20,
            'gap': 0.8,
            'unit': 'MT'
          },
          {
            'period': 'Q1 FY2026',
            'production': 24000,
            'dispatch': 15400,
            'target': 20000,
            'gap': 8600,
            'unit': 'MT'
          }
        ]
      };

      final model = AnalyticsOverviewModel.fromJson(liveOverview);
      expect(model.totalProduction, 203635.6);
      expect(model.totalDispatch, 163915.6);
      expect(model.netGap, 39720.0);
      expect(model.productionTargetAchievement, 286.54);
      expect(model.periods.length, 2);
      expect(model.periods[0].period, '2021');
      expect(model.periods[0].production, 20.4);
      expect(model.periods[0].dispatch, 19.6);
      expect(model.periods[1].period, 'Q1 FY2026');
      expect(model.periods[1].production, 24000.0);
    });

    test('AnalyticsKpisModel parses live API string metrics correctly', () {
      final liveKpis = {
        'totalDocuments': 11,
        'totalRecords': 78,
        'totalProduction': '203635.6 MT',
        'totalDispatch': '163915.6 MT',
        'totalTarget': '71067.4 MT',
        'productionDispatchGap': '39720 MT',
        'achievementRate': '286.54%',
        'averageValidationScore': '97%',
        'openIssues': 48
      };

      final kpis = AnalyticsKpisModel.fromJson(liveKpis);
      expect(kpis.totalRecords, 78);
      expect(kpis.totalDocuments, 11);
      expect(kpis.openIssues, 48);
      expect(kpis.targetAchievementPct, 286.54);
      expect(kpis.averageValidationScore, '97%');
      expect(kpis.averageConfidence, 0.97);
      expect(kpis.verifiedRecords, 30); // 78 - 48
    });

    test('VarianceItemModel parses live backend payload correctly', () {
      final liveVariance = {
        'period': 'Q1 FY2026',
        'actualProduction': 24000,
        'targetProduction': 20000,
        'variance': 4000,
        'achievementRate': 120,
        'dispatch': 15400,
        'dispatchGap': 8600,
        'unit': 'MT',
        'status': 'TARGET_EXCEEDED'
      };

      final item = VarianceItemModel.fromJson(liveVariance);
      expect(item.period, 'Q1 FY2026');
      expect(item.actual, 24000.0);
      expect(item.target, 20000.0);
      expect(item.variance, 4000.0);
      expect(item.variancePct, 120.0);
      expect(item.isPositive, isTrue);
      expect(item.status, 'TARGET_EXCEEDED');
      expect(item.unit, 'MT');
    });

    test('AnomalyItemModel parses live statistical outliers with Z-score', () {
      final liveAnomaly = {
        'type': 'STATISTICAL_OUTLIER',
        'recordId': '6a9f09bc83d8283507035820',
        'documentName': 'MineIntel_AI_Test_Document.pdf',
        'parameter': 'Raw Coal Production',
        'value': 128450,
        'unit': 'tonnes',
        'period': 'April 2026',
        'mean': 8695.53,
        'deviation': 119754.47,
        'zScore': 4.67,
        'reason': 'Value 128450 deviates significantly from mean 8695.5 (Z-score: 4.7)'
      };

      final model = AnomalyItemModel.fromJson(liveAnomaly);
      expect(model.type, 'STATISTICAL_OUTLIER');
      expect(model.parameter, 'Raw Coal Production');
      expect(model.documentName, 'MineIntel_AI_Test_Document.pdf');
      expect(model.zScore, 4.67);
      expect(model.isCritical, isTrue);
      expect(model.details, contains('Z-score: 4.7'));
    });

    test('TrendItemModel parses string value numbers safely', () {
      final trendJson = {
        'period': '2021',
        'parameter': 'Coal Production',
        'value': '10.2',
        'unit': 'MT'
      };

      final trend = TrendItemModel.fromJson(trendJson);
      expect(trend.period, '2021');
      expect(trend.production, 10.2);
      expect(trend.parameter, 'Coal Production');
    });
  });
}
