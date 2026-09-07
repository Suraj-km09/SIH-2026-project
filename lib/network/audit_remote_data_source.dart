import '../core/constants/api_endpoints.dart';
import '../models/audit_model.dart';
import 'api_client.dart';

/// Remote data source for Audit Trail & Provenance APIs (/api/v1/audit/*).
class AuditRemoteDataSource {
  final ApiClient _apiClient;

  AuditRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// GET /audit
  Future<AuditLogsResponse> getAuditLogs({
    int? limit,
    int? page,
    int? skip,
    String? action,
    String? status,
    String? resource,
    String? search,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (limit != null) queryParams['limit'] = limit;
    if (page != null) queryParams['page'] = page;
    if (skip != null) queryParams['skip'] = skip;
    if (action != null && action.isNotEmpty) queryParams['action'] = action;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (resource != null && resource.isNotEmpty) queryParams['resource'] = resource;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (startDate != null && startDate.isNotEmpty) queryParams['startDate'] = startDate;
    if (endDate != null && endDate.isNotEmpty) queryParams['endDate'] = endDate;

    final response = await _apiClient.dio.get(
      ApiEndpoints.audit,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return AuditLogsResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /audit/stats
  Future<AuditStats> getStats() async {
    final response = await _apiClient.dio.get(ApiEndpoints.auditStats);
    final rawData = response.data['data'] ?? response.data;
    return AuditStats.fromJson(rawData as Map<String, dynamic>);
  }

  /// GET /audit/export
  Future<AuditExportResult> exportAudit({
    String format = 'csv',
    String? action,
    String? resource,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{'format': format};
    if (action != null && action.isNotEmpty) queryParams['action'] = action;
    if (resource != null && resource.isNotEmpty) queryParams['resource'] = resource;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final response = await _apiClient.dio.get<String>(
      ApiEndpoints.auditExport,
      queryParameters: queryParams,
    );

    return AuditExportResult(
      content: response.data ?? '',
      format: format,
      filename: 'audit_logs_export.$format',
    );
  }

  /// GET /audit/user/:userId
  Future<List<AuditLogEntry>> getUserAudit(String userId) async {
    final response = await _apiClient.dio.get(ApiEndpoints.auditUser(userId));
    final rawData = response.data['data'] ?? response.data;
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(AuditLogEntry.fromJson)
          .toList();
    }
    return [];
  }

  /// GET /audit/document/:documentId
  Future<List<AuditLogEntry>> getDocumentAudit(String documentId) async {
    final response =
        await _apiClient.dio.get(ApiEndpoints.auditDocument(documentId));
    final rawData = response.data['data'] ?? response.data;
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(AuditLogEntry.fromJson)
          .toList();
    }
    return [];
  }

  /// GET /audit/report/:reportId
  Future<List<AuditLogEntry>> getReportAudit(String reportId) async {
    final response =
        await _apiClient.dio.get(ApiEndpoints.auditReport(reportId));
    final rawData = response.data['data'] ?? response.data;
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(AuditLogEntry.fromJson)
          .toList();
    }
    return [];
  }

  /// GET /audit/:id
  Future<AuditLogEntry> getAuditDetail(String id) async {
    final response = await _apiClient.dio.get(ApiEndpoints.auditDetail(id));
    final rawData = response.data['data'] ?? response.data;
    return AuditLogEntry.fromJson(rawData as Map<String, dynamic>);
  }
}
