import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics_model.dart';
import '../repositories/analytics_repository.dart';
import 'app_state.dart';

/// Immutable state for Mining Analytics & Production module.
class AnalyticsState {
  final ViewStatus status;
  final AnalyticsOverviewModel? overview;
  final AnalyticsKpisModel? kpis;
  final ProductionAnalyticsModel? production;
  final DispatchAnalyticsModel? dispatch;
  final List<TrendItemModel> trends;
  final List<VarianceItemModel> variance;
  final List<AnomalyItemModel> anomalies;
  final AnalyticsFilter activeFilter;
  final String? errorMessage;

  const AnalyticsState({
    this.status = ViewStatus.initial,
    this.overview,
    this.kpis,
    this.production,
    this.dispatch,
    this.trends = const [],
    this.variance = const [],
    this.anomalies = const [],
    this.activeFilter = const AnalyticsFilter(),
    this.errorMessage,
  });

  bool get isLoading => status == ViewStatus.loading;
  bool get isSuccess => status == ViewStatus.success;
  bool get isError => status == ViewStatus.error;
  bool get isEmpty =>
      isSuccess &&
      (overview == null ||
          (overview!.totalProduction == 0 &&
              overview!.totalDispatch == 0 &&
              trends.isEmpty &&
              variance.isEmpty));

  AnalyticsState copyWith({
    ViewStatus? status,
    AnalyticsOverviewModel? overview,
    AnalyticsKpisModel? kpis,
    ProductionAnalyticsModel? production,
    DispatchAnalyticsModel? dispatch,
    List<TrendItemModel>? trends,
    List<VarianceItemModel>? variance,
    List<AnomalyItemModel>? anomalies,
    AnalyticsFilter? activeFilter,
    String? errorMessage,
  }) {
    return AnalyticsState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      kpis: kpis ?? this.kpis,
      production: production ?? this.production,
      dispatch: dispatch ?? this.dispatch,
      trends: trends ?? this.trends,
      variance: variance ?? this.variance,
      anomalies: anomalies ?? this.anomalies,
      activeFilter: activeFilter ?? this.activeFilter,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory AnalyticsState.initial() => const AnalyticsState(status: ViewStatus.initial);

  factory AnalyticsState.loading({AnalyticsState? previous, AnalyticsFilter? filter}) =>
      AnalyticsState(
        status: ViewStatus.loading,
        overview: previous?.overview,
        kpis: previous?.kpis,
        production: previous?.production,
        dispatch: previous?.dispatch,
        trends: previous?.trends ?? const [],
        variance: previous?.variance ?? const [],
        anomalies: previous?.anomalies ?? const [],
        activeFilter: filter ?? previous?.activeFilter ?? const AnalyticsFilter(),
      );

  factory AnalyticsState.error(String message,
          {AnalyticsState? previous, AnalyticsFilter? filter}) =>
      AnalyticsState(
        status: ViewStatus.error,
        overview: previous?.overview,
        kpis: previous?.kpis,
        production: previous?.production,
        dispatch: previous?.dispatch,
        trends: previous?.trends ?? const [],
        variance: previous?.variance ?? const [],
        anomalies: previous?.anomalies ?? const [],
        activeFilter: filter ?? previous?.activeFilter ?? const AnalyticsFilter(),
        errorMessage: message,
      );
}

/// Provider for AnalyticsRepository.
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl(
    mockRepository: MockAnalyticsRepository(),
  );
});

/// Riverpod Notifier for Analytics module.
final analyticsNotifierProvider =
    NotifierProvider<AnalyticsNotifier, AnalyticsState>(AnalyticsNotifier.new);

class AnalyticsNotifier extends Notifier<AnalyticsState> {
  late final AnalyticsRepository _repository;

  @override
  AnalyticsState build() {
    _repository = ref.watch(analyticsRepositoryProvider);
    return AnalyticsState.initial();
  }

  /// Load all analytics payloads concurrently with resilient fallback.
  Future<void> loadAnalytics({AnalyticsFilter? filter}) async {
    final activeFilter = filter ?? state.activeFilter;
    state = AnalyticsState.loading(previous: state, filter: activeFilter);

    try {
      final results = await Future.wait([
        _repository.getOverview(filter: activeFilter),
        _repository.getKpis(filter: activeFilter),
        _repository.getProduction(filter: activeFilter),
        _repository.getDispatch(filter: activeFilter),
        _repository.getTrends(filter: activeFilter),
        _repository.getVariance(filter: activeFilter),
        _repository.getAnomalies(filter: activeFilter),
      ]);

      state = AnalyticsState(
        status: ViewStatus.success,
        overview: results[0] as AnalyticsOverviewModel,
        kpis: results[1] as AnalyticsKpisModel,
        production: results[2] as ProductionAnalyticsModel,
        dispatch: results[3] as DispatchAnalyticsModel,
        trends: results[4] as List<TrendItemModel>,
        variance: results[5] as List<VarianceItemModel>,
        anomalies: results[6] as List<AnomalyItemModel>,
        activeFilter: activeFilter,
      );
    } catch (e) {
      state = AnalyticsState.error(
        e.toString(),
        previous: state,
        filter: activeFilter,
      );
    }
  }

  /// Update active filter and reload.
  Future<void> updateFilter(AnalyticsFilter newFilter) async {
    await loadAnalytics(filter: newFilter);
  }

  /// Refresh current view.
  Future<void> refresh() async {
    await loadAnalytics(filter: state.activeFilter);
  }
}
