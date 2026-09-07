import '../core/constants/api_endpoints.dart';
import '../models/topic_model.dart';
import 'api_client.dart';

/// Remote data source for Topic Modeling & Taxonomy Discovery APIs (/api/v1/topics/*).
class TopicRemoteDataSource {
  final ApiClient _apiClient;

  TopicRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// GET /topics
  Future<List<TopicModel>> getTopics() async {
    final response = await _apiClient.dio.get(ApiEndpoints.topics);
    final rawData = response.data['data'] ?? response.data;
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(TopicModel.fromJson)
          .toList();
    }
    return [];
  }

  /// POST /topics/analyze
  Future<TopicAnalysisResult> analyzeTopics({
    String? documentId,
    List<String>? documentIds,
  }) async {
    final data = <String, dynamic>{};
    if (documentId != null) data['documentId'] = documentId;
    if (documentIds != null) data['documentIds'] = documentIds;

    final response = await _apiClient.dio.post(
      ApiEndpoints.topicsAnalyze,
      data: data.isNotEmpty ? data : null,
    );
    final rawData = response.data['data'] ?? response.data;
    return TopicAnalysisResult.fromJson(rawData as Map<String, dynamic>);
  }

  /// GET /topics/trends
  Future<List<TopicTrend>> getTrends() async {
    final response = await _apiClient.dio.get(ApiEndpoints.topicsTrends);
    final rawData = response.data['data'] ?? response.data;
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(TopicTrend.fromJson)
          .toList();
    }
    return [];
  }

  /// GET /topics/clusters
  Future<List<TopicCluster>> getClusters() async {
    final response = await _apiClient.dio.get(ApiEndpoints.topicsClusters);
    final rawData = response.data['data'] ?? response.data;
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(TopicCluster.fromJson)
          .toList();
    }
    return [];
  }

  /// GET /topics/entities
  Future<List<TopicEntityAssociation>> getEntities() async {
    final response = await _apiClient.dio.get(ApiEndpoints.topicsEntities);
    final rawData = response.data['data'] ?? response.data;
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(TopicEntityAssociation.fromJson)
          .toList();
    }
    return [];
  }

  /// GET /topics/emerging
  Future<List<EmergingTopic>> getEmerging() async {
    final response = await _apiClient.dio.get(ApiEndpoints.topicsEmerging);
    final rawData = response.data['data'] ?? response.data;
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(EmergingTopic.fromJson)
          .toList();
    }
    return [];
  }

  /// GET /topics/changes
  Future<List<TopicChange>> getChanges() async {
    final response = await _apiClient.dio.get(ApiEndpoints.topicsChanges);
    final rawData = response.data['data'] ?? response.data;
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(TopicChange.fromJson)
          .toList();
    }
    return [];
  }
}
