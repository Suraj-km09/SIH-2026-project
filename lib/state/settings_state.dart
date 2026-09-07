import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings_model.dart';
import '../repositories/settings_repository.dart';

/// State representation for User Settings & Preferences.
class SettingsState {
  final UserSettings settings;
  final bool isLoading;
  final bool isSaving;
  final String? successMessage;
  final String? errorMessage;

  const SettingsState({
    this.settings = const UserSettings(),
    this.isLoading = false,
    this.isSaving = false,
    this.successMessage,
    this.errorMessage,
  });

  SettingsState copyWith({
    UserSettings? settings,
    bool? isLoading,
    bool? isSaving,
    String? successMessage,
    String? errorMessage,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}

/// Global provider for SettingsNotifier.
final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

/// Reactive ThemeMode provider synchronized with Settings appearance.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settingsState = ref.watch(settingsNotifierProvider);
  return settingsState.settings.appearance.isDark
      ? ThemeMode.dark
      : ThemeMode.light;
});

/// Notifier managing language, appearance theme, notification preferences, and timezone.
class SettingsNotifier extends Notifier<SettingsState> {
  late final SettingsRepository _repository;

  @override
  SettingsState build() {
    _repository = ref.watch(settingsRepositoryProvider);
    return const SettingsState();
  }

  /// Fetches saved settings suite from backend.
  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final settings = await _repository.getSettings();
      if (!ref.mounted) return;
      state = state.copyWith(
        settings: settings,
        isLoading: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Updates language preference (en / hi).
  Future<bool> updateLanguage(String language) async {
    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);
    try {
      final updatedLang = await _repository.updateLanguage(language);
      if (!ref.mounted) return false;
      state = state.copyWith(
        settings: state.settings.copyWith(language: updatedLang),
        isSaving: false,
        successMessage: 'Language updated to ${language.toUpperCase()}',
      );
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Updates UI theme appearance (light / dark).
  Future<bool> updateTheme(String theme) async {
    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);
    try {
      final updatedAppearance = await _repository.updateAppearance(theme);
      if (!ref.mounted) return false;
      state = state.copyWith(
        settings: state.settings.copyWith(appearance: updatedAppearance),
        isSaving: false,
        successMessage: 'Appearance theme updated to ${theme.toUpperCase()}',
      );
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Updates notification channel preferences.
  Future<bool> updateNotificationPreferences({
    bool? emailNotif,
    bool? pushNotif,
    bool? reportAlerts,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);
    try {
      final current = state.settings.notifications;
      final updated = current.copyWith(
        emailNotif: emailNotif,
        pushNotif: pushNotif,
        reportAlerts: reportAlerts,
      );

      final result = await _repository.updateNotifications(updated);
      if (!ref.mounted) return false;
      state = state.copyWith(
        settings: state.settings.copyWith(notifications: result),
        isSaving: false,
        successMessage: 'Notification preferences saved successfully',
      );
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Updates timezone preference.
  Future<bool> updateTimezone(String timezone) async {
    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);
    try {
      final updatedSettings = state.settings.copyWith(timezone: timezone);
      final result = await _repository.updateSettings(updatedSettings);
      if (!ref.mounted) return false;
      state = state.copyWith(
        settings: result,
        isSaving: false,
        successMessage: 'Timezone preference updated to $timezone',
      );
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Bulk updates all settings.
  Future<bool> saveAllSettings(UserSettings newSettings) async {
    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);
    try {
      final result = await _repository.updateSettings(newSettings);
      if (!ref.mounted) return false;
      state = state.copyWith(
        settings: result,
        isSaving: false,
        successMessage: 'All settings saved successfully',
      );
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Clears temporary feedback messages.
  void clearMessages() {
    state = state.copyWith(successMessage: null, errorMessage: null);
  }
}
