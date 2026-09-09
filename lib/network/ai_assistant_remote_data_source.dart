import '../core/constants/api_endpoints.dart';
import '../models/ai_assistant_model.dart';
import 'api_client.dart';

/// Remote data source for AI Conversational Assistant APIs (/api/v1/ai-assistant/*).
class AiAssistantRemoteDataSource {
  final ApiClient _apiClient;

  AiAssistantRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// POST /api/v1/ai-assistant/query
  Future<AiAssistantResponse> query(AiAssistantQueryRequest request) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.aiAssistantQuery,
      data: request.toJson(),
    );
    final data = response.data is Map ? response.data as Map : {};
    return AiAssistantResponse.fromJson(Map<String, dynamic>.from(data));
  }

  /// GET /api/v1/ai-assistant/history
  Future<List<ConversationThreadModel>> getHistory() async {
    final response = await _apiClient.dio.get(ApiEndpoints.aiAssistantHistory);
    final rawData = response.data is Map
        ? (response.data['data'] ?? response.data)
        : response.data;
    if (rawData is List) {
      return rawData
          .whereType<Map>()
          .map((e) => ConversationThreadModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  /// GET /api/v1/ai-assistant/history/:id
  Future<ConversationThreadModel> getConversationById(String id) async {
    final response = await _apiClient.dio.get(ApiEndpoints.aiAssistantHistoryDetail(id));
    final rawData = response.data is Map
        ? (response.data['data'] ?? response.data)
        : response.data;
    return ConversationThreadModel.fromJson(
        Map<String, dynamic>.from(rawData is Map ? rawData : {}));
  }

  /// DELETE /api/v1/ai-assistant/history/:id
  Future<bool> deleteConversation(String id) async {
    final response = await _apiClient.dio.delete(ApiEndpoints.aiAssistantHistoryDelete(id));
    return response.statusCode == 200 ||
        (response.data is Map && response.data['success'] == true);
  }
}
