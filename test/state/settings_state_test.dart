import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/models/settings_model.dart';
import 'package:mineintel_ai/repositories/settings_repository.dart';
import 'package:mineintel_ai/state/settings_state.dart';

void main() {
  group('Phase 11 Settings Riverpod State Tests', () {
    late ProviderContainer container;
    late MockSettingsRepository mockRepo;

    setUp(() {
      EnvConfig.useMockData = true;
      mockRepo = MockSettingsRepository();
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('SettingsNotifier loads default settings', () async {
      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.loadSettings();

      final state = container.read(settingsNotifierProvider);
      expect(state.settings.language, 'en');
      expect(state.settings.appearance.isDark, false);

      final themeMode = container.read(themeModeProvider);
      expect(themeMode, ThemeMode.light);
    });

    test('SettingsNotifier updateTheme alters appearance and themeModeProvider', () async {
      final notifier = container.read(settingsNotifierProvider.notifier);
      final success = await notifier.updateTheme('dark');

      expect(success, isTrue);
      final state = container.read(settingsNotifierProvider);
      expect(state.settings.appearance.theme, 'dark');
      expect(state.settings.appearance.isDark, true);

      final themeMode = container.read(themeModeProvider);
      expect(themeMode, ThemeMode.dark);
    });

    test('SettingsNotifier updateLanguage updates language code', () async {
      final notifier = container.read(settingsNotifierProvider.notifier);
      final success = await notifier.updateLanguage('hi');

      expect(success, isTrue);
      final state = container.read(settingsNotifierProvider);
      expect(state.settings.language, 'hi');
      expect(state.successMessage, contains('HI'));
    });

    test('SettingsNotifier updateNotificationPreferences updates flags', () async {
      final notifier = container.read(settingsNotifierProvider.notifier);
      final success = await notifier.updateNotificationPreferences(
        emailNotif: false,
        pushNotif: true,
        reportAlerts: false,
      );

      expect(success, isTrue);
      final state = container.read(settingsNotifierProvider);
      expect(state.settings.notifications.emailNotif, false);
      expect(state.settings.notifications.pushNotif, true);
      expect(state.settings.notifications.reportAlerts, false);
    });

    test('SettingsNotifier updateTimezone persists timezone', () async {
      final notifier = container.read(settingsNotifierProvider.notifier);
      final success = await notifier.updateTimezone('UTC (+00:00)');

      expect(success, isTrue);
      final state = container.read(settingsNotifierProvider);
      expect(state.settings.timezone, 'UTC (+00:00)');
    });

    test('SettingsNotifier saveAllSettings updates bundle', () async {
      final notifier = container.read(settingsNotifierProvider.notifier);
      const custom = UserSettings(
        language: 'hi',
        appearance: AppearanceSettings(theme: 'dark'),
        notifications: NotificationPreferences(
          emailNotif: false,
          pushNotif: false,
          reportAlerts: true,
        ),
        timezone: 'Asia/Kolkata (IST)',
      );

      final success = await notifier.saveAllSettings(custom);
      expect(success, isTrue);

      final state = container.read(settingsNotifierProvider);
      expect(state.settings.language, 'hi');
      expect(state.settings.appearance.isDark, true);
      expect(state.settings.notifications.emailNotif, false);
    });
  });
}
