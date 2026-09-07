import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../models/dashboard_model.dart';
import 'api_client.dart';

/// Abstract contract for Dashboard network operations.
abstract class DashboardRemoteDataSource {
  Future<DashboardOverviewModel> getOverview();
  Future<DashboardKpisModel> getKpis();
  Future<List<DashboardActivityModel>> getActivity({int limit = 15});
  Future<List<DashboardAlertModel>> getAlerts();
  Future<List<DashboardRecentDocumentModel>> getRecentDocuments({int limit = 10});
}

/// Concrete implementation calling the live Express REST v1 backend.
class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiClient _apiClient;

  DashboardRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Dio get _dio => _apiClient.dio;

  @override
  Future<DashboardOverviewModel> getOverview() async {
    final response = await _dio.get(ApiEndpoints.dashboardOverview);
    final data = response.data['data'] as Map<String, dynamic>;
    return DashboardOverviewModel.fromJson(data);
  }

  @override
  Future<DashboardKpisModel> getKpis() async {
    final response = await _dio.get(ApiEndpoints.dashboardKpis);
    final data = response.data['data'] as Map<String, dynamic>;
    return DashboardKpisModel.fromJson(data);
  }

  @override
  Future<List<DashboardActivityModel>> getActivity({int limit = 15}) async {
    final response = await _dio.get(
      ApiEndpoints.dashboardActivity,
      queryParameters: {'limit': limit},
    );
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => DashboardActivityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<DashboardAlertModel>> getAlerts() async {
    final response = await _dio.get(ApiEndpoints.dashboardAlerts);
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => DashboardAlertModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<DashboardRecentDocumentModel>> getRecentDocuments({int limit = 10}) async {
    final response = await _dio.get(
      ApiEndpoints.dashboardRecentDocuments,
      queryParameters: {'limit': limit},
    );
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => DashboardRecentDocumentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
