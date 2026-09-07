import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import 'api_client.dart';

/// Abstract contract for authentication network operations.
abstract class AuthRemoteDataSource {
  Future<AuthResultModel> register({
    required String username,
    required String password,
    String? email,
  });

  Future<AuthResultModel> login({
    required String username,
    required String password,
  });

  Future<UserModel> getMe();

  Future<UserModel> updateProfile({
    String? email,
    String? department,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<RefreshTokenResultModel> refresh(String token);

  Future<void> logout();
}

/// Concrete implementation calling the live Express REST v1 backend.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Dio get _dio => _apiClient.dio;

  @override
  Future<AuthResultModel> register({
    required String username,
    required String password,
    String? email,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.authRegister,
      data: {
        'username': username.trim(),
        'password': password,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return AuthResultModel.fromJson(data);
  }

  @override
  Future<AuthResultModel> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.authLogin,
      data: {
        'username': username.trim(),
        'password': password,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return AuthResultModel.fromJson(data);
  }

  @override
  Future<UserModel> getMe() async {
    final response = await _dio.get(ApiEndpoints.authMe);
    final data = response.data['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  @override
  Future<UserModel> updateProfile({
    String? email,
    String? department,
  }) async {
    final response = await _dio.put(
      ApiEndpoints.authProfile,
      data: {
        if (email != null) 'email': email.trim(),
        if (department != null) 'department': department.trim(),
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.put(
      ApiEndpoints.authChangePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  @override
  Future<RefreshTokenResultModel> refresh(String token) async {
    final response = await _dio.post(
      ApiEndpoints.authRefresh,
      data: {'token': token},
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return RefreshTokenResultModel.fromJson(data);
  }

  @override
  Future<void> logout() async {
    await _dio.post(ApiEndpoints.authLogout);
  }
}
