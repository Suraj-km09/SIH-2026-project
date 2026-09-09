import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_model.dart';
import '../repositories/dashboard_repository.dart';
import 'app_state.dart';

/// Immutable state for Executive Dashboard.
class DashboardState {
  final ViewStatus status;
  final DashboardOverviewModel? overview;
  final DashboardKpisModel? kpis;
  final String? errorMessage;

  const DashboardState({
    this.status = ViewStatus.initial,
    this.overview,
    this.kpis,
    this.errorMessage,
  });

  bool get isLoading => status == ViewStatus.loading;
  bool get isSuccess => status == ViewStatus.success;
  bool get isError => status == ViewStatus.error;
  bool get isEmpty =>
      isSuccess &&
      (overview == null ||
          (overview!.stats.totalDocuments == 0 &&
              overview!.recentDocuments.isEmpty &&
              overview!.recentActivity.isEmpty));

  DashboardState copyWith({
    ViewStatus? status,
    DashboardOverviewModel? overview,
    DashboardKpisModel? kpis,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      kpis: kpis ?? this.kpis,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory DashboardState.initial() => const DashboardState(status: ViewStatus.initial);
  factory DashboardState.loading({DashboardState? previous}) => DashboardState(
        status: ViewStatus.loading,
        overview: previous?.overview,
        kpis: previous?.kpis,
      );
  factory DashboardState.success({
    required DashboardOverviewModel overview,
    required DashboardKpisModel kpis,
  }) =>
      DashboardState(
        status: ViewStatus.success,
        overview: overview,
        kpis: kpis,
      );
  factory DashboardState.error(String message, {DashboardState? previous}) =>
      DashboardState(
        status: ViewStatus.error,
        overview: previous?.overview,
        kpis: previous?.kpis,
        errorMessage: message,
      );
}

/// Provider for DashboardRepository.
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    mockRepository: MockDashboardRepository(),
  );
});

/// Riverpod Notifier for Dashboard state.
final dashboardNotifierProvider =
    NotifierProvider<DashboardNotifier, DashboardState>(DashboardNotifier.new);

class DashboardNotifier extends Notifier<DashboardState> {
  late final DashboardRepository _repository;

  @override
  DashboardState build() {
    _repository = ref.watch(dashboardRepositoryProvider);
    return DashboardState.initial();
  }

  /// Load both Overview and KPIs concurrently with resilient fallback, including live audit activity.
  Future<void> loadDashboard() async {
    state = DashboardState.loading(previous: state);

    try {
      final results = await Future.wait([
        _repository.getOverview(),
        _repository.getKpis(),
        _repository
            .getActivity(limit: 15)
            .catchError((_) => <DashboardActivityModel>[]),
      ]);

      var overview = results[0] as DashboardOverviewModel;
      final kpis = results[1] as DashboardKpisModel;
      final activities = results[2] as List<DashboardActivityModel>;

      if (activities.isNotEmpty) {
        overview = overview.copyWith(recentActivity: activities);
      }

      state = DashboardState.success(overview: overview, kpis: kpis);
    } catch (e) {
      state = DashboardState.error(
        e.toString(),
        previous: state,
      );
    }
  }

  /// Reload dashboard data.
  Future<void> refresh() async {
    await loadDashboard();
  }
}
