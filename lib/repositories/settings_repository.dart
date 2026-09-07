import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings_model.dart';
import '../network/settings_remote_data_source.dart';
import 'base_repository.dart';

/// Abstract contract for User Settings & Preferences.
abstract class SettingsRepository {
  Future<UserSettings> getSettings();
  Future<UserSettings> updateSettings(UserSettings settings);
  Future<String> getLanguage();
  Future<String> updateLanguage(String language);
  Future<AppearanceSettings> getAppearance();
  Future<AppearanceSettings> updateAppearance(String theme);
  Future<NotificationPreferences> getNotifications();
  Future<NotificationPreferences> updateNotifications(
      NotificationPreferences preferences);
}

/// Concrete implementation delegating to live API or fallback Mock.
class SettingsRepositoryImpl extends BaseRepository
    implements SettingsRepository {
  final SettingsRemoteDataSource _remoteDataSource;
  final SettingsRepository? mockRepository;

  SettingsRepositoryImpl({
    SettingsRemoteDataSource? remoteDataSource,
    this.mockRepository,
  }) : _remoteDataSource =
            remoteDataSource ?? SettingsRemoteDataSource();

  @override
  Future<UserSettings> getSettings() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getSettings();
    }
    return execute(() => _remoteDataSource.getSettings());
  }

  @override
  Future<UserSettings> updateSettings(UserSettings settings) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.updateSettings(settings);
    }
    return execute(() => _remoteDataSource.updateSettings(settings));
  }

  @override
  Future<String> getLanguage() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getLanguage();
    }
    return execute(() => _remoteDataSource.getLanguage());
  }

  @override
  Future<String> updateLanguage(String language) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.updateLanguage(language);
    }
    return execute(() => _remoteDataSource.updateLanguage(language));
  }

  @override
  Future<AppearanceSettings> getAppearance() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getAppearance();
    }
    return execute(() => _remoteDataSource.getAppearance());
  }

  @override
  Future<AppearanceSettings> updateAppearance(String theme) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.updateAppearance(theme);
    }
    return execute(() => _remoteDataSource.updateAppearance(theme));
  }

  @override
  Future<NotificationPreferences> getNotifications() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getNotifications();
    }
    return execute(() => _remoteDataSource.getNotifications());
  }

  @override
  Future<NotificationPreferences> updateNotifications(
      NotificationPreferences preferences) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.updateNotifications(preferences);
    }
    return execute(() => _remoteDataSource.updateNotifications(preferences));
  }
}

/// High-fidelity in-memory Mock implementation for offline operation.
class MockSettingsRepository implements SettingsRepository {
  UserSettings _mockSettings = const UserSettings(
    language: 'en',
    appearance: AppearanceSettings(theme: 'light'),
    notifications: NotificationPreferences(
      emailNotif: true,
      pushNotif: false,
      reportAlerts: true,
    ),
    timezone: 'Asia/Kolkata (IST)',
  );

  @override
  Future<UserSettings> getSettings() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockSettings;
  }

  @override
  Future<UserSettings> updateSettings(UserSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _mockSettings = settings;
    return _mockSettings;
  }

  @override
  Future<String> getLanguage() async {
    await Future.delayed(const Duration(milliseconds: 80));
    return _mockSettings.language;
  }

  @override
  Future<String> updateLanguage(String language) async {
    await Future.delayed(const Duration(milliseconds: 120));
    _mockSettings = _mockSettings.copyWith(language: language);
    return _mockSettings.language;
  }

  @override
  Future<AppearanceSettings> getAppearance() async {
    await Future.delayed(const Duration(milliseconds: 80));
    return _mockSettings.appearance;
  }

  @override
  Future<AppearanceSettings> updateAppearance(String theme) async {
    await Future.delayed(const Duration(milliseconds: 120));
    _mockSettings = _mockSettings.copyWith(
      appearance: AppearanceSettings(theme: theme),
    );
    return _mockSettings.appearance;
  }

  @override
  Future<NotificationPreferences> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 80));
    return _mockSettings.notifications;
  }

  @override
  Future<NotificationPreferences> updateNotifications(
      NotificationPreferences preferences) async {
    await Future.delayed(const Duration(milliseconds: 120));
    _mockSettings = _mockSettings.copyWith(notifications: preferences);
    return _mockSettings.notifications;
  }
}

/// Global provider for SettingsRepository.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    mockRepository: MockSettingsRepository(),
  );
});
