import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../models/admin_model.dart';
import '../models/user_model.dart';
import 'api_client.dart';

/// Abstract contract for Admin & System Health network operations.
abstract class AdminRemoteDataSource {
  Future<AdminStatsModel> getStats();
  Future<SystemHealthModel> getSystemHealth();
  Future<List<UserModel>> getUsers();
  Future<UserModel> updateUserRole({required String userId, required String role});
  Future<void> deleteUser(String userId);
}

/// Concrete implementation calling live Express REST v1 endpoints.
class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final ApiClient _apiClient;

  AdminRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Dio get _dio => _apiClient.dio;

  @override
  Future<AdminStatsModel> getStats() async {
    final response = await _dio.get(ApiEndpoints.adminStats);
    final data = response.data['data'] as Map<String, dynamic>;
    return AdminStatsModel.fromJson(data);
  }

  @override
  Future<SystemHealthModel> getSystemHealth() async {
    final response = await _dio.get(ApiEndpoints.adminSystemHealth);
    final data = response.data['data'] as Map<String, dynamic>;
    return SystemHealthModel.fromJson(data);
  }

  @override
  Future<List<UserModel>> getUsers() async {
    final response = await _dio.get(ApiEndpoints.adminUsers);
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<UserModel> updateUserRole({required String userId, required String role}) async {
    final response = await _dio.put(
      ApiEndpoints.adminUserRole(userId),
      data: {'role': role},
    );
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return UserModel.fromJson(data);
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _dio.delete(ApiEndpoints.adminUserDelete(userId));
  }
}
