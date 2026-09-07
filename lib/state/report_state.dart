import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_model.dart';
import '../repositories/report_repository.dart';
import 'app_state.dart';

/// Provider for ReportRepository.
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(
    mockRepository: MockReportRepository(),
  );
});

// ============================================================================
// 1. REPORT LIST STATE & NOTIFIER
// ============================================================================

class ReportListState {
  final ViewStatus status;
  final List<ReportModel> reports;
  final ReportPaginationMeta meta;
  final ReportFilter filter;
  final String? errorMessage;
  final String? actionMessage;
  final bool isActionLoading;

  const ReportListState({
    this.status = ViewStatus.initial,
    this.reports = const [],
    this.meta = const ReportPaginationMeta(total: 0, page: 1, limit: 20, pages: 1),
    this.filter = const ReportFilter(),
    this.errorMessage,
    this.actionMessage,
    this.isActionLoading = false,
  });

  bool get isLoading => status == ViewStatus.loading;
  bool get isSuccess => status == ViewStatus.success;
  bool get isError => status == ViewStatus.error;
  bool get isEmpty => isSuccess && reports.isEmpty;

  ReportListState copyWith({
    ViewStatus? status,
    List<ReportModel>? reports,
    ReportPaginationMeta? meta,
    ReportFilter? filter,
    String? errorMessage,
    String? actionMessage,
    bool? isActionLoading,
  }) {
    return ReportListState(
      status: status ?? this.status,
      reports: reports ?? this.reports,
      meta: meta ?? this.meta,
      filter: filter ?? this.filter,
      errorMessage: errorMessage ?? this.errorMessage,
      actionMessage: actionMessage ?? this.actionMessage,
      isActionLoading: isActionLoading ?? this.isActionLoading,
    );
  }
}

final reportListNotifierProvider =
    NotifierProvider<ReportListNotifier, ReportListState>(ReportListNotifier.new);

class ReportListNotifier extends Notifier<ReportListState> {
  late final ReportRepository _repository;

  @override
  ReportListState build() {
    _repository = ref.watch(reportRepositoryProvider);
    return const ReportListState();
  }

  Future<void> loadReports({bool resetPage = false}) async {
    final currentFilter = resetPage ? state.filter.copyWith(page: 1) : state.filter;
    state = state.copyWith(
      status: ViewStatus.loading,
      filter: currentFilter,
      errorMessage: null,
    );

    try {
      final response = await _repository.getReports(currentFilter);
      if (!ref.mounted) return;
      state = state.copyWith(
        status: ViewStatus.success,
        reports: response.reports,
        meta: response.meta,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: ViewStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void setFilter(ReportFilter filter) {
    state = state.copyWith(filter: filter);
    loadReports(resetPage: true);
  }

  Future<ReportModel?> generateReport(ReportGenerateRequest request) async {
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    try {
      final report = await _repository.generateReport(request);
      final updatedList = [report, ...state.reports];
      state = state.copyWith(
        reports: updatedList,
        isActionLoading: false,
        actionMessage: 'Report "${report.title}" generated successfully.',
      );
      return report;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  Future<bool> deleteReport(String id) async {
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    try {
      await _repository.deleteReport(id);
      final updatedList = state.reports.where((r) => r.id != id).toList();
      state = state.copyWith(
        reports: updatedList,
        isActionLoading: false,
        actionMessage: 'Report deleted successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<dynamic> exportReport(String id, String format) async {
    try {
      final result = await _repository.exportReport(id, format);
      state = state.copyWith(
        actionMessage: 'Report exported to ${format.toUpperCase()} successfully.',
      );
      return result;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }
}

// ============================================================================
// 2. REPORT DETAIL STATE & NOTIFIER
// ============================================================================

class ReportDetailState {
  final ViewStatus status;
  final ReportModel? report;
  final List<CitedEvidenceModel> evidence;
  final List<ReportVersionModel> versions;
  final List<ReportChangeModel> changes;
  final String? errorMessage;
  final String? actionMessage;
  final bool isActionLoading;

  const ReportDetailState({
    this.status = ViewStatus.initial,
    this.report,
    this.evidence = const [],
    this.versions = const [],
    this.changes = const [],
    this.errorMessage,
    this.actionMessage,
    this.isActionLoading = false,
  });

  bool get isLoading => status == ViewStatus.loading;
  bool get isSuccess => status == ViewStatus.success && report != null;
  bool get isError => status == ViewStatus.error;

  ReportDetailState copyWith({
    ViewStatus? status,
    ReportModel? report,
    List<CitedEvidenceModel>? evidence,
    List<ReportVersionModel>? versions,
    List<ReportChangeModel>? changes,
    String? errorMessage,
    String? actionMessage,
    bool? isActionLoading,
  }) {
    return ReportDetailState(
      status: status ?? this.status,
      report: report ?? this.report,
      evidence: evidence ?? this.evidence,
      versions: versions ?? this.versions,
      changes: changes ?? this.changes,
      errorMessage: errorMessage ?? this.errorMessage,
      actionMessage: actionMessage ?? this.actionMessage,
      isActionLoading: isActionLoading ?? this.isActionLoading,
    );
  }
}

final reportDetailNotifierProvider =
    NotifierProvider<ReportDetailNotifier, ReportDetailState>(ReportDetailNotifier.new);

class ReportDetailNotifier extends Notifier<ReportDetailState> {
  late final ReportRepository _repository;

  @override
  ReportDetailState build() {
    _repository = ref.watch(reportRepositoryProvider);
    return const ReportDetailState();
  }

  Future<void> loadReport(String id) async {
    state = state.copyWith(status: ViewStatus.loading, errorMessage: null);

    try {
      final results = await Future.wait([
        _repository.getReportById(id),
        _repository.getReportEvidence(id),
        _repository.getReportVersionHistory(id),
        _repository.getReportChanges(id),
      ]);

      final report = results[0] as ReportModel;
      final evidence = results[1] as List<CitedEvidenceModel>;
      final versions = results[2] as List<ReportVersionModel>;
      final changes = results[3] as List<ReportChangeModel>;

      state = state.copyWith(
        status: ViewStatus.success,
        report: report,
        evidence: evidence,
        versions: versions,
        changes: changes,
      );
    } catch (e) {
      state = state.copyWith(
        status: ViewStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> updateReport(String id, ReportUpdateRequest request) async {
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    try {
      final updated = await _repository.updateReport(id, request);
      final history = await _repository.getReportVersionHistory(id);

      state = state.copyWith(
        report: updated,
        versions: history,
        isActionLoading: false,
        actionMessage: 'Report updated to version ${updated.version}.',
      );
      // Also update list state if loaded
      ref.read(reportListNotifierProvider.notifier).loadReports();
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> submitForReview(String id) async {
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    try {
      final updated = await _repository.submitForReview(id);
      final changes = await _repository.getReportChanges(id);

      state = state.copyWith(
        report: updated,
        changes: changes,
        isActionLoading: false,
        actionMessage: 'Report submitted for governance review.',
      );
      ref.read(reportListNotifierProvider.notifier).loadReports();
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> approveReport(String id) async {
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    try {
      final updated = await _repository.approveReport(id);
      final changes = await _repository.getReportChanges(id);

      state = state.copyWith(
        report: updated,
        changes: changes,
        isActionLoading: false,
        actionMessage: 'Report formally approved and published.',
      );
      ref.read(reportListNotifierProvider.notifier).loadReports();
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> rejectReport(String id, String reason) async {
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    try {
      final updated = await _repository.rejectReport(id, reason);
      final changes = await _repository.getReportChanges(id);

      state = state.copyWith(
        report: updated,
        changes: changes,
        isActionLoading: false,
        actionMessage: 'Report rejected with comments recorded.',
      );
      ref.read(reportListNotifierProvider.notifier).loadReports();
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}
