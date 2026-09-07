import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../models/report_model.dart';
import 'api_client.dart';

/// Remote data source for Report APIs: /api/v1/reports.
class ReportRemoteDataSource {
  final ApiClient _apiClient;

  ReportRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// POST /api/v1/reports/generate
  Future<ReportModel> generateReport(ReportGenerateRequest request) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.reportsGenerate,
      data: request.toJson(),
    );
    final data = response.data['data'] ?? response.data;
    return ReportModel.fromJson(data as Map<String, dynamic>);
  }

  /// GET /api/v1/reports
  Future<ReportsResponse> getReports(ReportFilter filter) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.reports,
      queryParameters: filter.toQueryParams(),
    );
    return ReportsResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /api/v1/reports/:id
  Future<ReportModel> getReportById(String id) async {
    final response = await _apiClient.dio.get(ApiEndpoints.reportDetail(id));
    final data = response.data['data'] ?? response.data;
    return ReportModel.fromJson(data as Map<String, dynamic>);
  }

  /// PUT /api/v1/reports/:id
  Future<ReportModel> updateReport(String id, ReportUpdateRequest request) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.reportUpdate(id),
      data: request.toJson(),
    );
    final data = response.data['data'] ?? response.data;
    return ReportModel.fromJson(data as Map<String, dynamic>);
  }

  /// DELETE /api/v1/reports/:id
  Future<bool> deleteReport(String id) async {
    final response = await _apiClient.dio.delete(ApiEndpoints.reportDelete(id));
    return response.data['success'] as bool? ?? true;
  }

  /// POST /api/v1/reports/:id/submit-review
  Future<ReportModel> submitForReview(String id) async {
    final response = await _apiClient.dio.post(ApiEndpoints.reportSubmitReview(id));
    final data = response.data['data'] ?? response.data;
    return ReportModel.fromJson(data as Map<String, dynamic>);
  }

  /// POST /api/v1/reports/:id/approve (Admin only)
  Future<ReportModel> approveReport(String id) async {
    final response = await _apiClient.dio.post(ApiEndpoints.reportApprove(id));
    final data = response.data['data'] ?? response.data;
    return ReportModel.fromJson(data as Map<String, dynamic>);
  }

  /// POST /api/v1/reports/:id/reject (Reviewer/Admin)
  Future<ReportModel> rejectReport(String id, String reason) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.reportReject(id),
      data: {'reason': reason},
    );
    final data = response.data['data'] ?? response.data;
    return ReportModel.fromJson(data as Map<String, dynamic>);
  }

  /// GET /api/v1/reports/:id/evidence
  Future<List<CitedEvidenceModel>> getReportEvidence(String id) async {
    final response = await _apiClient.dio.get(ApiEndpoints.reportEvidence(id));
    final raw = response.data['data'] ?? response.data['evidence'] ?? response.data['citations'] ?? [];
    if (raw is List) {
      return raw.map((e) => CitedEvidenceModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// GET /api/v1/reports/:id/version-history
  Future<List<ReportVersionModel>> getReportVersionHistory(String id) async {
    final response = await _apiClient.dio.get(ApiEndpoints.reportVersionHistory(id));
    final raw = response.data['data'] ?? response.data['versions'] ?? [];
    if (raw is List) {
      return raw.map((e) => ReportVersionModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// GET /api/v1/reports/:id/changes
  Future<List<ReportChangeModel>> getReportChanges(String id) async {
    final response = await _apiClient.dio.get(ApiEndpoints.reportChanges(id));
    final raw = response.data['data'] ?? response.data['changes'] ?? [];
    if (raw is List) {
      return raw.map((e) => ReportChangeModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// GET /api/v1/reports/:id/export or /export/:format
  Future<dynamic> exportReport(String id, String format) async {
    final fmt = format.toLowerCase().replaceAll('.', '');
    final String endpoint;
    switch (fmt) {
      case 'pdf':
        endpoint = ApiEndpoints.reportExportPdf(id);
        break;
      case 'docx':
        endpoint = ApiEndpoints.reportExportDocx(id);
        break;
      case 'csv':
        endpoint = ApiEndpoints.reportExportCsv(id);
        break;
      case 'json':
        endpoint = ApiEndpoints.reportExportJson(id);
        break;
      default:
        endpoint = '${ApiEndpoints.reportExport(id)}?format=$fmt';
    }

    final response = await _apiClient.dio.get(
      endpoint,
      options: Options(
        responseType: fmt == 'json' || fmt == 'csv' ? ResponseType.json : ResponseType.bytes,
      ),
    );
    return response.data;
  }
}
