import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../models/validation_issue_model.dart';
import 'api_client.dart';

/// Abstract contract for Validation & Quality Control network operations.
abstract class ValidationRemoteDataSource {
  Future<ValidationSummaryModel> runValidation(String documentId);
  Future<ValidationSummaryModel> getValidationSummary(String documentId);
  Future<ValidationIssuesResponse> getValidationIssues(
    String documentId,
    ValidationFilter filter,
  );
  Future<ValidationIssueModel> resolveIssue(
    String issueId,
    ValidationIssueUpdateRequest request,
  );
  Future<ValidationApprovalResponse> approveValidation(String documentId);
  Future<ValidationReviewResponse> submitReview(
    String documentId,
    ValidationReviewRequest request,
  );
}

/// Concrete implementation using Dio REST v1 client.
class ValidationRemoteDataSourceImpl implements ValidationRemoteDataSource {
  final ApiClient _apiClient;

  ValidationRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Dio get _dio => _apiClient.dio;

  Map<String, dynamic> _toMap(dynamic val, [String? fallbackDocId]) {
    if (val is Map<String, dynamic>) return val;
    if (val is Map) return Map<String, dynamic>.from(val);
    final map = <String, dynamic>{};
    if (fallbackDocId != null) {
      map['documentId'] = fallbackDocId;
    }
    if (val is List) {
      map['issues'] = val;
      map['data'] = val;
    }
    return map;
  }

  @override
  Future<ValidationSummaryModel> runValidation(String documentId) async {
    final response = await _dio.post(
      ApiEndpoints.validationRun,
      data: {'documentId': documentId},
    );
    final raw = response.data;
    final Map<String, dynamic> data;
    if (raw is Map && raw['data'] != null) {
      data = _toMap(raw['data'], documentId);
    } else {
      data = _toMap(raw, documentId);
    }
    return ValidationSummaryModel.fromJson(data);
  }

  @override
  Future<ValidationSummaryModel> getValidationSummary(String documentId) async {
    final response = await _dio.get(ApiEndpoints.validationDocument(documentId));
    final raw = response.data;
    final Map<String, dynamic> data;
    if (raw is Map && raw['data'] != null) {
      data = _toMap(raw['data'], documentId);
    } else {
      data = _toMap(raw, documentId);
    }
    return ValidationSummaryModel.fromJson(data);
  }

  @override
  Future<ValidationIssuesResponse> getValidationIssues(
    String documentId,
    ValidationFilter filter,
  ) async {
    final response = await _dio.get(
      ApiEndpoints.validationIssues(documentId),
      queryParameters: filter.toQueryParams(),
    );
    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      return ValidationIssuesResponse.fromJson(raw);
    } else if (raw is Map) {
      return ValidationIssuesResponse.fromJson(Map<String, dynamic>.from(raw));
    } else if (raw is List) {
      return ValidationIssuesResponse.fromJson({'data': raw});
    }
    return const ValidationIssuesResponse(
      issues: [],
      meta: ValidationPaginationMeta(total: 0, page: 1, limit: 50, pages: 1),
    );
  }

  @override
  Future<ValidationIssueModel> resolveIssue(
    String issueId,
    ValidationIssueUpdateRequest request,
  ) async {
    final response = await _dio.put(
      ApiEndpoints.validationIssueResolve(issueId),
      data: request.toJson(),
    );
    final raw = response.data;
    final Map<String, dynamic> data = raw is Map && raw['data'] != null
        ? _toMap(raw['data'])
        : _toMap(raw);
    final issueData = data['issue'] is Map ? _toMap(data['issue']) : data;
    return ValidationIssueModel.fromJson(issueData);
  }

  @override
  Future<ValidationApprovalResponse> approveValidation(String documentId) async {
    final response = await _dio.post(ApiEndpoints.validationApprove(documentId));
    final raw = response.data;
    final Map<String, dynamic> data = raw is Map && raw['data'] != null
        ? _toMap(raw['data'], documentId)
        : _toMap(raw, documentId);
    return ValidationApprovalResponse.fromJson(data);
  }

  @override
  Future<ValidationReviewResponse> submitReview(
    String documentId,
    ValidationReviewRequest request,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.validationReview(documentId),
      data: request.toJson(),
    );
    final raw = response.data;
    final Map<String, dynamic> data = raw is Map && raw['data'] != null
        ? _toMap(raw['data'], documentId)
        : _toMap(raw, documentId);
    return ValidationReviewResponse.fromJson(data);
  }
}
