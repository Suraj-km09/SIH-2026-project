import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/file_saver.dart';
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

  Future<String?> exportReport(String id, String format, {String? reportTitle}) async {
    state = state.copyWith(isActionLoading: true, errorMessage: null);
    try {
      final data = await _repository.exportReport(id, format);
      if (data == null) throw Exception('No export data received');

      final fmt = format.toLowerCase().replaceAll('.', '');
      String titlePart = (reportTitle ?? '').trim();
      if (titlePart.isEmpty) {
        final match = state.reports.where((r) => r.id == id).firstOrNull;
        if (match != null) titlePart = match.title;
      }
      if (titlePart.isEmpty) titlePart = 'report_$id';

      final cleanTitle = titlePart
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      final shortId = id.length > 8 ? id.substring(0, 8) : id;
      final fileName = 'Statutory_Report_${cleanTitle}_$shortId.$fmt';

      Uint8List bytes;
      String mimeType;
      if (data is Uint8List) {
        bytes = data;
      } else if (data is List<int>) {
        bytes = Uint8List.fromList(data);
      } else if (data is String) {
        bytes = Uint8List.fromList(utf8.encode(data));
      } else if (data is Map || data is List) {
        bytes = Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(data)));
      } else {
        bytes = Uint8List.fromList(utf8.encode(data.toString()));
      }

      switch (fmt) {
        case 'pdf':
          mimeType = 'application/pdf';
          break;
        case 'docx':
        case 'doc':
          mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case 'csv':
          mimeType = 'text/csv;charset=utf-8';
          break;
        case 'json':
          mimeType = 'application/json;charset=utf-8';
          break;
        default:
          mimeType = 'application/octet-stream';
      }

      final savedPath = await FileSaver.saveAndLaunchFile(bytes, fileName, mimeType: mimeType);
      state = state.copyWith(
        isActionLoading: false,
        actionMessage: 'Report exported as $fileName. Download started.',
      );
      return savedPath ?? fileName;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Export failed: $e',
      );
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
      errorMessage: errorMessage,
      actionMessage: actionMessage,
      isActionLoading: isActionLoading ?? this.isActionLoading,
    );
  }
}

final reportDetailNotifierProvider =
    NotifierProvider<ReportDetailNotifier, ReportDetailState>(ReportDetailNotifier.new);

class ReportDetailNotifier extends Notifier<ReportDetailState> {
  late final ReportRepository _repository;
  int _loadSequence = 0;
  String? _pendingReportId;

  @override
  ReportDetailState build() {
    _repository = ref.watch(reportRepositoryProvider);
    return const ReportDetailState();
  }

  Future<void> loadReport(String id) async {
    if (state.isActionLoading) {
      _pendingReportId = id;
      return;
    }
    final sequence = ++_loadSequence;
    state = state.copyWith(status: ViewStatus.loading, errorMessage: null);

    try {
      final results = await Future.wait([
        _repository.getReportById(id),
        _repository.getReportEvidence(id),
        _repository.getReportVersionHistory(id),
        _repository.getReportChanges(id),
      ]);
      if (!ref.mounted || sequence != _loadSequence) return;

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
      if (!ref.mounted || sequence != _loadSequence) return;
      state = state.copyWith(
        status: ViewStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> updateReport(String id, ReportUpdateRequest request) async {
    if (state.isLoading || state.isActionLoading) return false;
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    try {
      final updated = await _repository.updateReport(id, request);
      await _completeMutation(updated, 'Report updated to version ${updated.version}.');
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    } finally {
      await _loadPendingReport();
    }
  }

  Future<bool> submitForReview(String id, {required int expectedVersion}) async {
    if (state.isLoading || state.isActionLoading) return false;
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    try {
      final updated = await _repository.submitForReview(id, expectedVersion: expectedVersion);
      await _completeMutation(updated, 'Report submitted for governance review.');
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    } finally {
      await _loadPendingReport();
    }
  }

  Future<bool> approveReport(String id, {required int expectedVersion}) async {
    if (state.isLoading || state.isActionLoading) return false;
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    try {
      final updated = await _repository.approveReport(id, expectedVersion: expectedVersion);
      await _completeMutation(updated, 'Report formally approved and published.');
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    } finally {
      await _loadPendingReport();
    }
  }

  Future<bool> rejectReport(String id, String reason, {required int expectedVersion}) async {
    if (state.isLoading || state.isActionLoading) return false;
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    try {
      final updated = await _repository.rejectReport(id, reason, expectedVersion: expectedVersion);
      await _completeMutation(updated, 'Report rejected with comments recorded.');
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    } finally {
      await _loadPendingReport();
    }
  }

  Future<void> _loadPendingReport() async {
    if (!ref.mounted) return;
    final reportId = _pendingReportId;
    _pendingReportId = null;
    if (reportId != null) await loadReport(reportId);
  }

  Future<void> _completeMutation(ReportModel updated, String message) async {
    if (!ref.mounted) return;
    state = state.copyWith(
      report: updated,
      versions: const [],
      changes: const [],
      actionMessage: message,
    );
    ref.read(reportListNotifierProvider.notifier).loadReports();
    try {
      final results = await Future.wait([
        _repository.getReportVersionHistory(updated.id),
        _repository.getReportChanges(updated.id),
      ]);
      if (!ref.mounted) return;
      state = state.copyWith(
        versions: results[0] as List<ReportVersionModel>,
        changes: results[1] as List<ReportChangeModel>,
        isActionLoading: false,
        actionMessage: message,
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isActionLoading: false,
        actionMessage: message,
        errorMessage: 'Report saved, but history could not be refreshed. Reload to view current history.',
      );
    }
  }

  Future<String?> exportReport(String id, String format, {String? reportTitle}) async {
    if (state.isLoading || state.isActionLoading) return null;
    state = state.copyWith(isActionLoading: true, errorMessage: null);
    try {
      final data = await _repository.exportReport(id, format);
      if (data == null) throw Exception('No export data received');

      final fmt = format.toLowerCase().replaceAll('.', '');
      String titlePart = (reportTitle ?? state.report?.title ?? '').trim();
      if (titlePart.isEmpty) titlePart = 'report_$id';

      final cleanTitle = titlePart
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      final shortId = id.length > 8 ? id.substring(0, 8) : id;
      final fileName = 'Statutory_Report_${cleanTitle}_$shortId.$fmt';

      Uint8List bytes;
      String mimeType;
      if (data is Uint8List) {
        bytes = data;
      } else if (data is List<int>) {
        bytes = Uint8List.fromList(data);
      } else if (data is String) {
        bytes = Uint8List.fromList(utf8.encode(data));
      } else if (data is Map || data is List) {
        bytes = Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(data)));
      } else {
        bytes = Uint8List.fromList(utf8.encode(data.toString()));
      }

      switch (fmt) {
        case 'pdf':
          mimeType = 'application/pdf';
          break;
        case 'docx':
        case 'doc':
          mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case 'csv':
          mimeType = 'text/csv;charset=utf-8';
          break;
        case 'json':
          mimeType = 'application/json;charset=utf-8';
          break;
        default:
          mimeType = 'application/octet-stream';
      }

      final savedPath = await FileSaver.saveAndLaunchFile(bytes, fileName, mimeType: mimeType);
      if (!ref.mounted) return savedPath ?? fileName;
      state = state.copyWith(
        isActionLoading: false,
        actionMessage: 'Report exported as $fileName. Download started.',
      );
      return savedPath ?? fileName;
    } catch (e) {
      if (!ref.mounted) return null;
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Export failed: $e',
      );
      return null;
    } finally {
      await _loadPendingReport();
    }
  }
}
