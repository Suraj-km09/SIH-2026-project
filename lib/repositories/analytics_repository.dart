import '../models/analytics_model.dart';
import '../network/analytics_remote_data_source.dart';
import 'base_repository.dart';

/// Abstract contract for Analytics operations.
abstract class AnalyticsRepository {
  Future<AnalyticsOverviewModel> getOverview({AnalyticsFilter? filter});
  Future<AnalyticsKpisModel> getKpis({AnalyticsFilter? filter});
  Future<ProductionAnalyticsModel> getProduction({AnalyticsFilter? filter});
  Future<DispatchAnalyticsModel> getDispatch({AnalyticsFilter? filter});
  Future<List<TrendItemModel>> getTrends({AnalyticsFilter? filter});
  Future<List<VarianceItemModel>> getVariance({AnalyticsFilter? filter});
  Future<List<AnomalyItemModel>> getAnomalies({AnalyticsFilter? filter});
}

/// Concrete implementation delegating to AnalyticsRemoteDataSource or Mock.
class AnalyticsRepositoryImpl extends BaseRepository implements AnalyticsRepository {
  final AnalyticsRemoteDataSource _remoteDataSource;
  final AnalyticsRepository? mockRepository;

  AnalyticsRepositoryImpl({
    AnalyticsRemoteDataSource? remoteDataSource,
    this.mockRepository,
  }) : _remoteDataSource = remoteDataSource ?? AnalyticsRemoteDataSourceImpl();

  @override
  Future<AnalyticsOverviewModel> getOverview({AnalyticsFilter? filter}) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getOverview(filter: filter);
    }
    try {
      final overview = await execute(() => _remoteDataSource.getOverview(filter: filter));
      if (overview.totalProduction == 0 && overview.totalDispatch == 0 && mockRepository != null) {
        return await mockRepository!.getOverview(filter: filter);
      }
      return overview;
    } catch (_) {
      if (mockRepository != null) return mockRepository!.getOverview(filter: filter);
      rethrow;
    }
  }

  @override
  Future<AnalyticsKpisModel> getKpis({AnalyticsFilter? filter}) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getKpis(filter: filter);
    }
    try {
      final kpis = await execute(() => _remoteDataSource.getKpis(filter: filter));
      if (kpis.totalRecords == 0 && mockRepository != null) {
        return await mockRepository!.getKpis(filter: filter);
      }
      return kpis;
    } catch (_) {
      if (mockRepository != null) return mockRepository!.getKpis(filter: filter);
      rethrow;
    }
  }

  @override
  Future<ProductionAnalyticsModel> getProduction({AnalyticsFilter? filter}) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getProduction(filter: filter);
    }
    try {
      final prod = await execute(() => _remoteDataSource.getProduction(filter: filter));
      if (prod.byMine.isEmpty && prod.byPeriod.isEmpty && mockRepository != null) {
        return await mockRepository!.getProduction(filter: filter);
      }
      return prod;
    } catch (_) {
      if (mockRepository != null) return mockRepository!.getProduction(filter: filter);
      rethrow;
    }
  }

  @override
  Future<DispatchAnalyticsModel> getDispatch({AnalyticsFilter? filter}) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getDispatch(filter: filter);
    }
    try {
      final disp = await execute(() => _remoteDataSource.getDispatch(filter: filter));
      if (disp.byMine.isEmpty && disp.byPeriod.isEmpty && mockRepository != null) {
        return await mockRepository!.getDispatch(filter: filter);
      }
      return disp;
    } catch (_) {
      if (mockRepository != null) return mockRepository!.getDispatch(filter: filter);
      rethrow;
    }
  }

  @override
  Future<List<TrendItemModel>> getTrends({AnalyticsFilter? filter}) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getTrends(filter: filter);
    }
    try {
      final trends = await execute(() => _remoteDataSource.getTrends(filter: filter));
      if (trends.isEmpty && mockRepository != null) {
        return await mockRepository!.getTrends(filter: filter);
      }
      return trends;
    } catch (_) {
      if (mockRepository != null) return mockRepository!.getTrends(filter: filter);
      rethrow;
    }
  }

  @override
  Future<List<VarianceItemModel>> getVariance({AnalyticsFilter? filter}) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getVariance(filter: filter);
    }
    try {
      final variance = await execute(() => _remoteDataSource.getVariance(filter: filter));
      if (variance.isEmpty && mockRepository != null) {
        return await mockRepository!.getVariance(filter: filter);
      }
      return variance;
    } catch (_) {
      if (mockRepository != null) return mockRepository!.getVariance(filter: filter);
      rethrow;
    }
  }

  @override
  Future<List<AnomalyItemModel>> getAnomalies({AnalyticsFilter? filter}) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getAnomalies(filter: filter);
    }
    try {
      return await execute(() => _remoteDataSource.getAnomalies(filter: filter));
    } catch (_) {
      if (mockRepository != null) return mockRepository!.getAnomalies(filter: filter);
      rethrow;
    }
  }
}

/// Realistic offline mock repository for Mining Analytics.
class MockAnalyticsRepository implements AnalyticsRepository {
  final Duration delay;

  const MockAnalyticsRepository({this.delay = Duration.zero});

  @override
  Future<AnalyticsOverviewModel> getOverview({AnalyticsFilter? filter}) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    return const AnalyticsOverviewModel(
      totalProduction: 14250.8,
      totalDispatch: 13890.2,
      netGap: 360.6,
      productionTargetAchievement: 98.4,
      topProducingMines: [
        MineProductionModel(mine: 'Rajmahal OCP', production: 4850.5),
        MineProductionModel(mine: 'Sonepur Bazari', production: 3620.0),
        MineProductionModel(mine: 'Jhanjra Underground', production: 2980.3),
        MineProductionModel(mine: 'Mugma Area', production: 2800.0),
      ],
    );
  }

  @override
  Future<AnalyticsKpisModel> getKpis({AnalyticsFilter? filter}) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    return const AnalyticsKpisModel(
      totalRecords: 142,
      averageConfidence: 0.94,
      verifiedRecords: 135,
      targetAchievementPct: 98.4,
    );
  }

  @override
  Future<ProductionAnalyticsModel> getProduction({AnalyticsFilter? filter}) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    return const ProductionAnalyticsModel(
      byMine: [
        MineProductionModel(mine: 'Rajmahal OCP', production: 4850.5),
        MineProductionModel(mine: 'Sonepur Bazari', production: 3620.0),
        MineProductionModel(mine: 'Jhanjra Area', production: 2980.3),
        MineProductionModel(mine: 'Mugma Area', production: 2800.0),
      ],
      bySubsidiary: [
        SubsidiaryProductionModel(subsidiary: 'ECL', production: 7830.8),
        SubsidiaryProductionModel(subsidiary: 'BCCL', production: 3420.0),
        SubsidiaryProductionModel(subsidiary: 'CCL', production: 3000.0),
      ],
      byPeriod: [
        PeriodProductionModel(period: 'June 2026', production: 13800.0),
        PeriodProductionModel(period: 'July 2026', production: 14100.0),
        PeriodProductionModel(period: 'August 2026', production: 14250.8),
      ],
    );
  }

  @override
  Future<DispatchAnalyticsModel> getDispatch({AnalyticsFilter? filter}) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    return const DispatchAnalyticsModel(
      byMine: [
        MineDispatchModel(mine: 'Rajmahal OCP', dispatch: 4680.0),
        MineDispatchModel(mine: 'Sonepur Bazari', dispatch: 3550.2),
        MineDispatchModel(mine: 'Jhanjra Area', dispatch: 2890.0),
        MineDispatchModel(mine: 'Mugma Area', dispatch: 2770.0),
      ],
      bySubsidiary: [
        SubsidiaryDispatchModel(subsidiary: 'ECL', dispatch: 7570.2),
        SubsidiaryDispatchModel(subsidiary: 'BCCL', dispatch: 3340.0),
        SubsidiaryDispatchModel(subsidiary: 'CCL', dispatch: 2980.0),
      ],
      byPeriod: [
        PeriodDispatchModel(period: 'June 2026', dispatch: 13200.0),
        PeriodDispatchModel(period: 'July 2026', dispatch: 13600.0),
        PeriodDispatchModel(period: 'August 2026', dispatch: 13890.2),
      ],
    );
  }

  @override
  Future<List<TrendItemModel>> getTrends({AnalyticsFilter? filter}) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    return const [
      TrendItemModel(period: '2026-03', production: 13200.0, dispatch: 12800.0),
      TrendItemModel(period: '2026-04', production: 13500.0, dispatch: 13050.0),
      TrendItemModel(period: '2026-05', production: 13750.0, dispatch: 13300.0),
      TrendItemModel(period: '2026-06', production: 13800.0, dispatch: 13200.0),
      TrendItemModel(period: '2026-07', production: 14100.0, dispatch: 13600.0),
      TrendItemModel(period: '2026-08', production: 14250.8, dispatch: 13890.2),
    ];
  }

  @override
  Future<List<VarianceItemModel>> getVariance({AnalyticsFilter? filter}) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    return const [
      VarianceItemModel(
        mine: 'Rajmahal OCP',
        parameter: 'Raw Coal Production (Tonnes)',
        target: 4800.0,
        actual: 4850.5,
        variance: 50.5,
        variancePct: 1.05,
      ),
      VarianceItemModel(
        mine: 'Sonepur Bazari',
        parameter: 'Overburden Removal (Cu.M)',
        target: 3800.0,
        actual: 3620.0,
        variance: -180.0,
        variancePct: -4.74,
      ),
      VarianceItemModel(
        mine: 'Jhanjra Area',
        parameter: 'Continuous Miner Extraction',
        target: 2900.0,
        actual: 2980.3,
        variance: 80.3,
        variancePct: 2.77,
      ),
      VarianceItemModel(
        mine: 'Mugma Area',
        parameter: 'Offtake by Indian Railways',
        target: 3200.0,
        actual: 2800.0,
        variance: -400.0,
        variancePct: -12.50,
      ),
    ];
  }

  @override
  Future<List<AnomalyItemModel>> getAnomalies({AnalyticsFilter? filter}) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    return const [
      AnomalyItemModel(
        type: 'PRODUCTION_DISPATCH_GAP',
        mine: 'Mugma Area',
        details: 'Dispatch exceeds production by 42.1% indicating rapid stockyard depletion.',
        severity: 'warning',
      ),
      AnomalyItemModel(
        type: 'STATISTICAL_OUTLIER_3SIGMA',
        mine: 'Sonepur Bazari',
        details: 'Daily overburden removal variance exceeded 3.2 sigma on August 24, 2026.',
        severity: 'critical',
      ),
      AnomalyItemModel(
        type: 'STRIPPING_RATIO_DEVIATION',
        mine: 'Rajmahal OCP',
        details: 'Observed stripping ratio is 1.85 vs planned 2.10 (favorable variance).',
        severity: 'info',
      ),
    ];
  }
}
