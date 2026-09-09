import '../core/constants/api_endpoints.dart';
import '../models/command_centre_model.dart';
import 'api_client.dart';

/// Remote data source for Command Centre APIs (/api/v1/command-centre/*).
class CommandCentreRemoteDataSource {
  final ApiClient _apiClient;

  CommandCentreRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// GET /api/v1/command-centre/overview
  Future<CommandCentreOverviewModel> getOverview() async {
    final response = await _apiClient.dio.get(ApiEndpoints.commandCentreOverview);
    final data = response.data is Map
        ? (response.data['data'] ?? response.data)
        : response.data;
    return CommandCentreOverviewModel.fromJson(
        Map<String, dynamic>.from(data as Map));
  }

  /// GET /api/v1/command-centre/pipeline
  Future<CommandCentrePipelineModel> getPipeline() async {
    final response = await _apiClient.dio.get(ApiEndpoints.commandCentrePipeline);
    final data = response.data is Map
        ? (response.data['data'] ?? response.data)
        : response.data;
    return CommandCentrePipelineModel.fromJson(
        Map<String, dynamic>.from(data as Map));
  }

  /// GET /api/v1/command-centre/status
  Future<CommandCentreStatusModel> getStatus() async {
    final response = await _apiClient.dio.get(ApiEndpoints.commandCentreStatus);
    final data = response.data is Map
        ? (response.data['data'] ?? response.data)
        : response.data;
    return CommandCentreStatusModel.fromJson(
        Map<String, dynamic>.from(data as Map));
  }

  /// GET /api/v1/command-centre/attention-items
  Future<CommandCentreAttentionModel> getAttentionItems() async {
    final response =
        await _apiClient.dio.get(ApiEndpoints.commandCentreAttentionItems);
    final data = response.data is Map
        ? (response.data['data'] ?? response.data)
        : response.data;
    return CommandCentreAttentionModel.fromJson(
        Map<String, dynamic>.from(data as Map));
  }

  /// GET /api/v1/command-centre/activity
  Future<List<CommandCentreActivityModel>> getActivity() async {
    final response = await _apiClient.dio.get(ApiEndpoints.commandCentreActivity);
    final rawData = response.data is Map
        ? (response.data['data'] ?? response.data)
        : response.data;
    if (rawData is List) {
      return rawData
          .whereType<Map>()
          .map((e) =>
              CommandCentreActivityModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}
