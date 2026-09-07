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

  @override
  Future<ValidationSummaryModel> runValidation(String documentId) async {
    final response = await _dio.post(
      ApiEndpoints.validationRun,
      data: {'documentId': documentId},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ValidationSummaryModel.fromJson(data);
  }

  @override
  Future<ValidationSummaryModel> getValidationSummary(String documentId) async {
    final response = await _dio.get(ApiEndpoints.validationDocument(documentId));
    final data = response.data['data'] as Map<String, dynamic>;
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
    return ValidationIssuesResponse.fromJson(response.data as Map<String, dynamic>);
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
    final data = response.data['data'] as Map<String, dynamic>;
    final issueData = data['issue'] as Map<String, dynamic>? ?? data;
    return ValidationIssueModel.fromJson(issueData);
  }

  @override
  Future<ValidationApprovalResponse> approveValidation(String documentId) async {
    final response = await _dio.post(ApiEndpoints.validationApprove(documentId));
    final data = response.data['data'] as Map<String, dynamic>;
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
    final data = response.data['data'] as Map<String, dynamic>;
    return ValidationReviewResponse.fromJson(data);
  }
}
