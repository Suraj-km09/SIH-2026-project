import '../core/constants/api_endpoints.dart';
import '../models/intelligence_model.dart';
import '../models/topic_model.dart';
import 'api_client.dart';

/// Remote data source for Document Intelligence and Cross-Document Reasoning APIs (/api/v1/intelligence/*).
class IntelligenceRemoteDataSource {
  final ApiClient _apiClient;

  IntelligenceRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// GET /intelligence
  Future<IntelligenceOverview> getOverview({
    String? documentId,
    String? timeframe,
  }) async {
    final queryParams = <String, dynamic>{};
    if (documentId != null) queryParams['documentId'] = documentId;
    if (timeframe != null) queryParams['timeframe'] = timeframe;

    final response = await _apiClient.dio.get(
      ApiEndpoints.intelligence,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final rawData = response.data['data'] ?? response.data;
    return IntelligenceOverview.fromJson(rawData as Map<String, dynamic>);
  }

  /// POST /intelligence/analyze
  Future<IntelligenceAnalysisResult> analyze({
    String? documentId,
    List<String>? documentIds,
  }) async {
    final data = <String, dynamic>{};
    if (documentId != null) data['documentId'] = documentId;
    if (documentIds != null) data['documentIds'] = documentIds;

    final response = await _apiClient.dio.post(
      ApiEndpoints.intelligenceAnalyze,
      data: data.isNotEmpty ? data : null,
    );
    final rawData = response.data['data'] ?? response.data;
    return IntelligenceAnalysisResult.fromJson(rawData as Map<String, dynamic>);
  }

  /// GET /intelligence/trends
  Future<List<TopicTrend>> getTrends() async {
    final response = await _apiClient.dio.get(ApiEndpoints.intelligenceTrends);
    final rawData = response.data['data'] ?? response.data;
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(TopicTrend.fromJson)
          .toList();
    }
    return [];
  }

  /// GET /intelligence/entities
  Future<List<IntelligenceEntity>> getEntities({
    String? document,
    String? type,
  }) async {
    final queryParams = <String, dynamic>{};
    if (document != null) queryParams['document'] = document;
    if (type != null) queryParams['type'] = type;

    final response = await _apiClient.dio.get(
      ApiEndpoints.intelligenceEntities,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final rawData = response.data['data'] ?? response.data;
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(IntelligenceEntity.fromJson)
          .toList();
    }
    return [];
  }

  /// GET /intelligence/clusters
  Future<List<IntelligenceCluster>> getClusters() async {
    final response =
        await _apiClient.dio.get(ApiEndpoints.intelligenceClusters);
    final rawData = response.data['data'] ?? response.data;
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(IntelligenceCluster.fromJson)
          .toList();
    }
    return [];
  }

  /// GET /intelligence/similarity
  Future<IntelligenceSimilarityResult> getSimilarity({
    String? documentId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (documentId != null) queryParams['document'] = documentId;

    final response = await _apiClient.dio.get(
      ApiEndpoints.intelligenceSimilarity,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final rawData = response.data['data'] ?? response.data;
    return IntelligenceSimilarityResult.fromJson(rawData as Map<String, dynamic>);
  }

  /// GET /intelligence/changes
  Future<IntelligenceChangesResponse> getChanges({
    String? docA,
    String? docB,
  }) async {
    final queryParams = <String, dynamic>{};
    if (docA != null) queryParams['docA'] = docA;
    if (docB != null) queryParams['docB'] = docB;

    final response = await _apiClient.dio.get(
      ApiEndpoints.intelligenceChanges,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final rawData = response.data['data'] ?? response.data;
    return IntelligenceChangesResponse.fromJson(rawData as Map<String, dynamic>);
  }

  /// GET /intelligence/entities/:documentId
  Future<DocumentEntitiesResponse> getDocumentEntities(
      String documentId) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.intelligenceDocumentEntities(documentId),
    );
    final rawData = response.data['data'] ?? response.data;
    return DocumentEntitiesResponse.fromJson(rawData as Map<String, dynamic>);
  }

  /// GET /intelligence/similarity/:documentId
  Future<DocumentSimilarityResponse> getDocumentSimilarity(
      String documentId) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.intelligenceDocumentSimilarity(documentId),
    );
    final rawData = response.data['data'] ?? response.data;
    return DocumentSimilarityResponse.fromJson(rawData as Map<String, dynamic>);
  }

  /// POST /intelligence/link-evidence/:documentId
  Future<LinkEvidenceResult> linkEvidence(String documentId) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.intelligenceLinkEvidence(documentId),
    );
    final rawData = response.data['data'] ?? response.data;
    return LinkEvidenceResult.fromJson(rawData as Map<String, dynamic>);
  }
}
