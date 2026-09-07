import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../models/analytics_model.dart';
import 'api_client.dart';

/// Abstract contract for Analytics network operations.
abstract class AnalyticsRemoteDataSource {
  Future<AnalyticsOverviewModel> getOverview({AnalyticsFilter? filter});
  Future<AnalyticsKpisModel> getKpis({AnalyticsFilter? filter});
  Future<ProductionAnalyticsModel> getProduction({AnalyticsFilter? filter});
  Future<DispatchAnalyticsModel> getDispatch({AnalyticsFilter? filter});
  Future<List<TrendItemModel>> getTrends({AnalyticsFilter? filter});
  Future<List<VarianceItemModel>> getVariance({AnalyticsFilter? filter});
  Future<List<AnomalyItemModel>> getAnomalies({AnalyticsFilter? filter});
}

/// Concrete implementation calling the live Express REST v1 backend.
class AnalyticsRemoteDataSourceImpl implements AnalyticsRemoteDataSource {
  final ApiClient _apiClient;

  AnalyticsRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Dio get _dio => _apiClient.dio;

  @override
  Future<AnalyticsOverviewModel> getOverview({AnalyticsFilter? filter}) async {
    final response = await _dio.get(
      ApiEndpoints.analyticsOverview,
      queryParameters: filter?.toQueryParams(),
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return AnalyticsOverviewModel.fromJson(data);
  }

  @override
  Future<AnalyticsKpisModel> getKpis({AnalyticsFilter? filter}) async {
    final response = await _dio.get(
      ApiEndpoints.analyticsKpis,
      queryParameters: filter?.toQueryParams(),
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return AnalyticsKpisModel.fromJson(data);
  }

  @override
  Future<ProductionAnalyticsModel> getProduction({AnalyticsFilter? filter}) async {
    final response = await _dio.get(
      ApiEndpoints.analyticsProduction,
      queryParameters: filter?.toQueryParams(),
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ProductionAnalyticsModel.fromJson(data);
  }

  @override
  Future<DispatchAnalyticsModel> getDispatch({AnalyticsFilter? filter}) async {
    final response = await _dio.get(
      ApiEndpoints.analyticsDispatch,
      queryParameters: filter?.toQueryParams(),
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return DispatchAnalyticsModel.fromJson(data);
  }

  @override
  Future<List<TrendItemModel>> getTrends({AnalyticsFilter? filter}) async {
    final response = await _dio.get(
      ApiEndpoints.analyticsTrends,
      queryParameters: filter?.toQueryParams(),
    );
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => TrendItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<VarianceItemModel>> getVariance({AnalyticsFilter? filter}) async {
    final response = await _dio.get(
      ApiEndpoints.analyticsVariance,
      queryParameters: filter?.toQueryParams(),
    );
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VarianceItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AnomalyItemModel>> getAnomalies({AnalyticsFilter? filter}) async {
    final response = await _dio.get(
      ApiEndpoints.analyticsAnomalies,
      queryParameters: filter?.toQueryParams(),
    );
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => AnomalyItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
