import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../models/extracted_record_model.dart';
import 'api_client.dart';

/// Abstract contract for Data Extraction network operations.
abstract class ExtractionRemoteDataSource {
  Future<ExtractionSummaryModel> runExtraction(String documentId);
  Future<ExtractionSummaryModel> getExtractionSummary(String documentId);
  Future<ExtractionRecordsResponse> getExtractionRecords(
    String documentId,
    ExtractionFilter filter,
  );
  Future<ExtractedRecordModel> updateExtractionRecord(
    String documentId,
    String recordId,
    ExtractedRecordUpdateRequest request,
  );
  Future<ExtractedRecordModel> approveRecord(String recordId);
  Future<ExtractedRecordModel> rejectRecord(String recordId);
  Future<BulkApproveResponse> bulkApproveRecords(List<String> recordIds);
}

/// Concrete implementation using Dio REST v1 client.
class ExtractionRemoteDataSourceImpl implements ExtractionRemoteDataSource {
  final ApiClient _apiClient;

  ExtractionRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Dio get _dio => _apiClient.dio;

  @override
  Future<ExtractionSummaryModel> runExtraction(String documentId) async {
    final response = await _dio.post(
      ApiEndpoints.extractionRun,
      data: {'documentId': documentId},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ExtractionSummaryModel.fromJson(data);
  }

  @override
  Future<ExtractionSummaryModel> getExtractionSummary(String documentId) async {
    final response = await _dio.get(ApiEndpoints.extractionSummary(documentId));
    final data = response.data['data'] as Map<String, dynamic>;
    return ExtractionSummaryModel.fromJson(data);
  }

  @override
  Future<ExtractionRecordsResponse> getExtractionRecords(
    String documentId,
    ExtractionFilter filter,
  ) async {
    final response = await _dio.get(
      ApiEndpoints.extractionRecords(documentId),
      queryParameters: filter.toQueryParams(),
    );
    return ExtractionRecordsResponse.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ExtractedRecordModel> updateExtractionRecord(
    String documentId,
    String recordId,
    ExtractedRecordUpdateRequest request,
  ) async {
    final response = await _dio.put(
      ApiEndpoints.extractionRecordUpdate(documentId, recordId),
      data: request.toJson(),
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ExtractedRecordModel.fromJson(data);
  }

  @override
  Future<ExtractedRecordModel> approveRecord(String recordId) async {
    final response = await _dio.post(ApiEndpoints.extractionRecordApprove(recordId));
    final data = response.data['data'] as Map<String, dynamic>;
    return ExtractedRecordModel.fromJson(data);
  }

  @override
  Future<ExtractedRecordModel> rejectRecord(String recordId) async {
    final response = await _dio.post(ApiEndpoints.extractionRecordReject(recordId));
    final data = response.data['data'] as Map<String, dynamic>;
    return ExtractedRecordModel.fromJson(data);
  }

  @override
  Future<BulkApproveResponse> bulkApproveRecords(List<String> recordIds) async {
    final response = await _dio.post(
      ApiEndpoints.extractionBulkApprove,
      data: {'ids': recordIds},
    );
    return BulkApproveResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
