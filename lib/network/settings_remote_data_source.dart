import '../core/constants/api_endpoints.dart';
import '../models/settings_model.dart';
import 'api_client.dart';

/// Remote data source for User Settings & Preferences APIs (/api/v1/settings/*).
class SettingsRemoteDataSource {
  final ApiClient _apiClient;

  SettingsRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// GET /settings
  Future<UserSettings> getSettings() async {
    final response = await _apiClient.dio.get(ApiEndpoints.settings);
    final rawData = response.data['data'] ?? response.data;
    return UserSettings.fromJson(rawData as Map<String, dynamic>);
  }

  /// PUT /settings
  Future<UserSettings> updateSettings(UserSettings settings) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.settings,
      data: settings.toJson(),
    );
    final rawData = response.data['data'] ?? response.data;
    return UserSettings.fromJson(rawData as Map<String, dynamic>);
  }

  /// GET /settings/language
  Future<String> getLanguage() async {
    final response = await _apiClient.dio.get(ApiEndpoints.settingsLanguage);
    final rawData = response.data['data'] ?? response.data;
    if (rawData is Map<String, dynamic>) {
      return rawData['language'] as String? ?? 'en';
    }
    return rawData?.toString() ?? 'en';
  }

  /// PUT /settings/language
  Future<String> updateLanguage(String language) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.settingsLanguage,
      data: {'language': language},
    );
    final rawData = response.data['data'] ?? response.data;
    if (rawData is Map<String, dynamic>) {
      return rawData['language'] as String? ?? language;
    }
    return language;
  }

  /// GET /settings/appearance
  Future<AppearanceSettings> getAppearance() async {
    final response = await _apiClient.dio.get(ApiEndpoints.settingsAppearance);
    final rawData = response.data['data'] ?? response.data;
    return AppearanceSettings.fromJson(rawData);
  }

  /// PUT /settings/appearance
  Future<AppearanceSettings> updateAppearance(String theme) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.settingsAppearance,
      data: {'theme': theme},
    );
    final rawData = response.data['data'] ?? response.data;
    return AppearanceSettings.fromJson(rawData);
  }

  /// GET /settings/notifications
  Future<NotificationPreferences> getNotifications() async {
    final response =
        await _apiClient.dio.get(ApiEndpoints.settingsNotifications);
    final rawData = response.data['data'] ?? response.data;
    return NotificationPreferences.fromJson(rawData as Map<String, dynamic>);
  }

  /// PUT /settings/notifications
  Future<NotificationPreferences> updateNotifications(
      NotificationPreferences preferences) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.settingsNotifications,
      data: preferences.toJson(),
    );
    final rawData = response.data['data'] ?? response.data;
    return NotificationPreferences.fromJson(rawData as Map<String, dynamic>);
  }
}
