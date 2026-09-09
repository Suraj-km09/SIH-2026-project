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
    final raw = response.data['data'];
    final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return AnalyticsOverviewModel.fromJson(data);
  }

  @override
  Future<AnalyticsKpisModel> getKpis({AnalyticsFilter? filter}) async {
    final response = await _dio.get(
      ApiEndpoints.analyticsKpis,
      queryParameters: filter?.toQueryParams(),
    );
    final raw = response.data['data'];
    final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return AnalyticsKpisModel.fromJson(data);
  }

  @override
  Future<ProductionAnalyticsModel> getProduction({AnalyticsFilter? filter}) async {
    final response = await _dio.get(
      ApiEndpoints.analyticsProduction,
      queryParameters: filter?.toQueryParams(),
    );
    final raw = response.data['data'];
    final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return ProductionAnalyticsModel.fromJson(data);
  }

  @override
  Future<DispatchAnalyticsModel> getDispatch({AnalyticsFilter? filter}) async {
    final response = await _dio.get(
      ApiEndpoints.analyticsDispatch,
      queryParameters: filter?.toQueryParams(),
    );
    final raw = response.data['data'];
    final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return DispatchAnalyticsModel.fromJson(data);
  }

  @override
  Future<List<TrendItemModel>> getTrends({AnalyticsFilter? filter}) async {
    final response = await _dio.get(
      ApiEndpoints.analyticsTrends,
      queryParameters: filter?.toQueryParams(),
    );
    final raw = response.data['data'];
    final List<dynamic> list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map && raw['trends'] is List) {
      list = raw['trends'] as List<dynamic>;
    } else if (raw is Map && raw['records'] is List) {
      list = raw['records'] as List<dynamic>;
    } else {
      list = [];
    }
    return list
        .whereType<Map>()
        .map((e) => TrendItemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<VarianceItemModel>> getVariance({AnalyticsFilter? filter}) async {
    final response = await _dio.get(
      ApiEndpoints.analyticsVariance,
      queryParameters: filter?.toQueryParams(),
    );
    final raw = response.data['data'];
    final List<dynamic> list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map && raw['periods'] is List) {
      list = raw['periods'] as List<dynamic>;
    } else if (raw is Map && raw['variances'] is List) {
      list = raw['variances'] as List<dynamic>;
    } else {
      list = [];
    }
    return list
        .whereType<Map>()
        .map((e) => VarianceItemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<AnomalyItemModel>> getAnomalies({AnalyticsFilter? filter}) async {
    final response = await _dio.get(
      ApiEndpoints.analyticsAnomalies,
      queryParameters: filter?.toQueryParams(),
    );
    final raw = response.data['data'];
    final List<dynamic> list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map && raw['anomalies'] is List) {
      list = raw['anomalies'] as List<dynamic>;
    } else {
      list = [];
    }
    return list
        .whereType<Map>()
        .map((e) => AnomalyItemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
