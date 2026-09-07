import 'dart:io';
import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../models/document_model.dart';
import 'api_client.dart';

/// Abstract contract for Document Lifecycle network operations.
abstract class DocumentRemoteDataSource {
  Future<DocumentModel> uploadDocument(
    File file, {
    void Function(int sent, int total)? onSendProgress,
  });

  Future<DocumentListResponse> getDocuments(DocumentFilter filter);

  Future<DocumentDetailModel> getDocumentDetail(String id);

  Future<DocumentMetadataModel> getDocumentMetadata(String id);

  Future<DocumentModel> updateDocumentMetadata(
    String id,
    DocumentMetadataUpdateRequest request,
  );

  Future<DocumentStatusModel> getDocumentStatus(String id);

  Future<DocumentModel> reprocessDocument(String id);

  Future<DocumentModel> retryDocument(String id);

  Future<String> deleteDocument(String id);

  Future<String> downloadDocument(String id, String savePath);
}

/// Concrete implementation delegating to Dio REST v1 client.
class DocumentRemoteDataSourceImpl implements DocumentRemoteDataSource {
  final ApiClient _apiClient;

  DocumentRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Dio get _dio => _apiClient.dio;

  @override
  Future<DocumentModel> uploadDocument(
    File file, {
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : file.path.split(RegExp(r'[/\\]')).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
    });

    final response = await _dio.post(
      ApiEndpoints.documentsUpload,
      data: formData,
      onSendProgress: onSendProgress,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return DocumentModel.fromJson(data);
  }

  @override
  Future<DocumentListResponse> getDocuments(DocumentFilter filter) async {
    final response = await _dio.get(
      ApiEndpoints.documents,
      queryParameters: filter.toQueryParams(),
    );

    return DocumentListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<DocumentDetailModel> getDocumentDetail(String id) async {
    final response = await _dio.get(ApiEndpoints.documentDetail(id));
    final data = response.data['data'] as Map<String, dynamic>;
    return DocumentDetailModel.fromJson(data);
  }

  @override
  Future<DocumentMetadataModel> getDocumentMetadata(String id) async {
    final response = await _dio.get(ApiEndpoints.documentMetadata(id));
    final data = response.data['data'] as Map<String, dynamic>;
    return DocumentMetadataModel.fromJson(data);
  }

  @override
  Future<DocumentModel> updateDocumentMetadata(
    String id,
    DocumentMetadataUpdateRequest request,
  ) async {
    final response = await _dio.put(
      ApiEndpoints.documentMetadata(id),
      data: request.toJson(),
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return DocumentModel.fromJson(data);
  }

  @override
  Future<DocumentStatusModel> getDocumentStatus(String id) async {
    final response = await _dio.get(ApiEndpoints.documentStatus(id));
    final data = response.data['data'] as Map<String, dynamic>;
    return DocumentStatusModel.fromJson(data);
  }

  @override
  Future<DocumentModel> reprocessDocument(String id) async {
    final response = await _dio.post(ApiEndpoints.documentReprocess(id));
    final data = response.data['data'] as Map<String, dynamic>;
    return DocumentModel.fromJson(data);
  }

  @override
  Future<DocumentModel> retryDocument(String id) async {
    final response = await _dio.post(ApiEndpoints.documentRetry(id));
    final data = response.data['data'] as Map<String, dynamic>;
    return DocumentModel.fromJson(data);
  }

  @override
  Future<String> deleteDocument(String id) async {
    final response = await _dio.delete(ApiEndpoints.documentDelete(id));
    final data = response.data['data'] as Map<String, dynamic>?;
    return data?['deletedId'] as String? ?? id;
  }

  @override
  Future<String> downloadDocument(String id, String savePath) async {
    await _dio.download(
      ApiEndpoints.documentDownload(id),
      savePath,
    );
    return savePath;
  }
}
