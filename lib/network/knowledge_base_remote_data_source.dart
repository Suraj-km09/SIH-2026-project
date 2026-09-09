import '../core/constants/api_endpoints.dart';
import '../models/knowledge_base_model.dart';
import 'api_client.dart';

/// Remote data source for Knowledge Base & RAG APIs (/api/v1/knowledge-base/*, /api/v1/rag/*).
class KnowledgeBaseRemoteDataSource {
  final ApiClient _apiClient;

  KnowledgeBaseRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// GET /api/v1/knowledge-base
  Future<KnowledgeBaseListResponse> getKnowledgeBase(KnowledgeBaseFilter filter) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.knowledgeBase,
      queryParameters: filter.toQueryParams(),
    );
    final map = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    return KnowledgeBaseListResponse.fromJson(map);
  }

  /// POST /api/v1/knowledge-base/index
  Future<IndexDocumentResponse> indexDocument(String documentId) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.knowledgeBaseIndex,
      data: {'documentId': documentId},
    );
    final map = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    return IndexDocumentResponse.fromJson(map);
  }

  /// GET /api/v1/knowledge-base/:documentId
  Future<KnowledgeBaseDetailModel> getDocumentChunks(String documentId) async {
    final response = await _apiClient.dio.get(ApiEndpoints.knowledgeBaseDocument(documentId));
    final map = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    return KnowledgeBaseDetailModel.fromJson(map);
  }

  /// DELETE /api/v1/knowledge-base/:documentId
  Future<bool> deleteDocumentIndex(String documentId) async {
    final response = await _apiClient.dio.delete(ApiEndpoints.knowledgeBaseDelete(documentId));
    if (response.data is Map) {
      return response.statusCode == 200 || (response.data as Map)['success'] == true;
    }
    return response.statusCode == 200;
  }

  /// POST /api/v1/knowledge-base/search
  Future<KnowledgeBaseSearchResponse> search(
    String query, {
    int topK = 5,
    Map<String, dynamic>? filters,
  }) async {
    final body = <String, dynamic>{
      'query': query,
      'topK': topK,
    };
    if (filters != null && filters.isNotEmpty) {
      body['filters'] = filters;
    }

    final response = await _apiClient.dio.post(
      ApiEndpoints.knowledgeBaseSearch,
      data: body,
    );
    final map = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    return KnowledgeBaseSearchResponse.fromJson(map);
  }

  /// POST /api/v1/rag/:documentId/index
  Future<IndexDocumentResponse> ragIndexDocument(String documentId) async {
    final response = await _apiClient.dio.post(ApiEndpoints.ragIndex(documentId));
    final map = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    return IndexDocumentResponse.fromJson(map);
  }

  /// POST /api/v1/rag/search
  Future<List<KnowledgeBaseSearchResult>> ragSearch(String query, {int topK = 5}) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.ragSearch,
      data: {
        'query': query,
        'topK': topK,
      },
    );

    final rawList = response.data is List
        ? response.data as List
        : (response.data is Map
            ? ((response.data as Map)['data'] as List? ??
                (response.data as Map)['results'] as List? ??
                [])
            : []);

    return rawList
        .whereType<Map>()
        .map((e) => KnowledgeBaseSearchResult.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
