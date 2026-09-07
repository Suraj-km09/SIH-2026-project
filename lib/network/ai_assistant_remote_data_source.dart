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
    return AiAssistantResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /api/v1/ai-assistant/history
  Future<List<ConversationThreadModel>> getHistory() async {
    final response = await _apiClient.dio.get(ApiEndpoints.aiAssistantHistory);
    final rawData = response.data['data'] ?? response.data;
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(ConversationThreadModel.fromJson)
          .toList();
    }
    return [];
  }

  /// GET /api/v1/ai-assistant/history/:id
  Future<ConversationThreadModel> getConversationById(String id) async {
    final response = await _apiClient.dio.get(ApiEndpoints.aiAssistantHistoryDetail(id));
    final rawData = response.data['data'] ?? response.data;
    return ConversationThreadModel.fromJson(rawData as Map<String, dynamic>);
  }

  /// DELETE /api/v1/ai-assistant/history/:id
  Future<bool> deleteConversation(String id) async {
    final response = await _apiClient.dio.delete(ApiEndpoints.aiAssistantHistoryDelete(id));
    return response.statusCode == 200 || response.data['success'] == true;
  }
}
