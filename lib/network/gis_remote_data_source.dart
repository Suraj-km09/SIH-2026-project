import '../core/constants/api_endpoints.dart';
import '../models/gis_model.dart';
import 'api_client.dart';

/// Remote data source for GIS Spatial Integration APIs (/api/v1/integration/gis).
class GisRemoteDataSource {
  final ApiClient _apiClient;

  GisRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// GET /integration/gis
  Future<List<GisDocumentRecord>> getGisRecords() async {
    final response = await _apiClient.dio.get(ApiEndpoints.integrationGis);
    final rawData = response.data['data'] ?? response.data;
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(GisDocumentRecord.fromJson)
          .toList();
    }
    return [];
  }
}
