import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audit_model.dart';
import '../repositories/audit_repository.dart';

/// State representation for System Audit Trail.
class AuditState {
  final List<AuditLogEntry> logs;
  final AuditStats? stats;
  final AuditLogEntry? selectedLog;
  final bool isLoading;
  final bool isExporting;
  final String? exportMessage;
  final String? errorMessage;
  final String searchQuery;
  final String selectedStatus;
  final String selectedAction;
  final String selectedResource;
  final String? entityFilterType; // 'user', 'document', 'report', or null
  final String? entityFilterId;
  final AuditMeta? meta;

  const AuditState({
    this.logs = const [],
    this.stats,
    this.selectedLog,
    this.isLoading = false,
    this.isExporting = false,
    this.exportMessage,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedStatus = 'ALL',
    this.selectedAction = 'ALL',
    this.selectedResource = 'ALL',
    this.entityFilterType,
    this.entityFilterId,
    this.meta,
  });

  bool get hasEntityFilter => entityFilterType != null && entityFilterId != null;

  AuditState copyWith({
    List<AuditLogEntry>? logs,
    AuditStats? stats,
    AuditLogEntry? selectedLog,
    bool? isLoading,
    bool? isExporting,
    String? exportMessage,
    String? errorMessage,
    String? searchQuery,
    String? selectedStatus,
    String? selectedAction,
    String? selectedResource,
    String? entityFilterType,
    String? entityFilterId,
    bool clearEntityFilter = false,
    AuditMeta? meta,
  }) {
    return AuditState(
      logs: logs ?? this.logs,
      stats: stats ?? this.stats,
      selectedLog: selectedLog ?? this.selectedLog,
      isLoading: isLoading ?? this.isLoading,
      isExporting: isExporting ?? this.isExporting,
      exportMessage: exportMessage,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedAction: selectedAction ?? this.selectedAction,
      selectedResource: selectedResource ?? this.selectedResource,
      entityFilterType:
          clearEntityFilter ? null : (entityFilterType ?? this.entityFilterType),
      entityFilterId:
          clearEntityFilter ? null : (entityFilterId ?? this.entityFilterId),
      meta: meta ?? this.meta,
    );
  }
}

/// Global provider for AuditNotifier.
final auditNotifierProvider =
    NotifierProvider<AuditNotifier, AuditState>(AuditNotifier.new);

/// Notifier orchestrating audit log queries, role-aware filtering, statistics, and exports.
class AuditNotifier extends Notifier<AuditState> {
  late final AuditRepository _repository;

  @override
  AuditState build() {
    _repository = ref.watch(auditRepositoryProvider);
    return const AuditState();
  }

  /// Fetches system audit logs based on current filters.
  Future<void> loadLogs() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      if (state.entityFilterType == 'user' && state.entityFilterId != null) {
        final logs = await _repository.getUserAudit(state.entityFilterId!);
        if (!ref.mounted) return;
        state = state.copyWith(
          logs: logs,
          isLoading: false,
        );
      } else if (state.entityFilterType == 'document' &&
          state.entityFilterId != null) {
        final logs =
            await _repository.getDocumentAudit(state.entityFilterId!);
        if (!ref.mounted) return;
        state = state.copyWith(
          logs: logs,
          isLoading: false,
        );
      } else if (state.entityFilterType == 'report' &&
          state.entityFilterId != null) {
        final logs = await _repository.getReportAudit(state.entityFilterId!);
        if (!ref.mounted) return;
        state = state.copyWith(
          logs: logs,
          isLoading: false,
        );
      } else {
        final response = await _repository.getAuditLogs(
          action: state.selectedAction,
          status: state.selectedStatus,
          resource: state.selectedResource,
          search: state.searchQuery,
        );
        if (!ref.mounted) return;
        state = state.copyWith(
          logs: response.logs,
          meta: response.meta,
          isLoading: false,
        );
      }
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Fetches aggregate compliance statistics.
  Future<void> loadStats() async {
    try {
      final stats = await _repository.getStats();
      if (!ref.mounted) return;
      state = state.copyWith(stats: stats);
    } catch (_) {
      // Non-blocking for primary audit log view
    }
  }

  /// Filters logs by specific user ID.
  void filterByUser(String userId) {
    state = state.copyWith(
      entityFilterType: 'user',
      entityFilterId: userId,
    );
    loadLogs();
  }

  /// Filters logs by document ID.
  void filterByDocument(String documentId) {
    state = state.copyWith(
      entityFilterType: 'document',
      entityFilterId: documentId,
    );
    loadLogs();
  }

  /// Filters logs by report ID.
  void filterByReport(String reportId) {
    state = state.copyWith(
      entityFilterType: 'report',
      entityFilterId: reportId,
    );
    loadLogs();
  }

  /// Resets entity-scoped filters.
  void clearEntityFilter() {
    state = state.copyWith(clearEntityFilter: true);
    loadLogs();
  }

  /// Updates text search query.
  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
    loadLogs();
  }

  /// Updates status filter.
  void setStatus(String status) {
    state = state.copyWith(selectedStatus: status);
    loadLogs();
  }

  /// Updates action filter.
  void setAction(String action) {
    state = state.copyWith(selectedAction: action);
    loadLogs();
  }

  /// Updates resource filter.
  void setResource(String resource) {
    state = state.copyWith(selectedResource: resource);
    loadLogs();
  }

  /// Loads full details for a single log entry.
  Future<AuditLogEntry?> getLogDetail(String id) async {
    try {
      final log = await _repository.getAuditDetail(id);
      if (!ref.mounted) return null;
      state = state.copyWith(selectedLog: log);
      return log;
    } catch (e) {
      if (!ref.mounted) return null;
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  /// Exports audit trail in CSV or JSON format.
  Future<AuditExportResult?> exportAudit(String format) async {
    state = state.copyWith(isExporting: true, exportMessage: null);
    try {
      final result = await _repository.exportAudit(
        format: format,
        action: state.selectedAction,
        resource: state.selectedResource,
        status: state.selectedStatus,
      );
      if (!ref.mounted) return null;
      state = state.copyWith(
        isExporting: false,
        exportMessage:
            'Export completed: ${result.filename} (${result.content.length} bytes)',
      );
      return result;
    } catch (e) {
      if (!ref.mounted) return null;
      state = state.copyWith(
        isExporting: false,
        errorMessage: 'Export failed: $e',
      );
      return null;
    }
  }
}
