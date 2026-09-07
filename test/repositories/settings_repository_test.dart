import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/models/settings_model.dart';
import 'package:mineintel_ai/repositories/settings_repository.dart';

void main() {
  group('Phase 11 SettingsRepository & MockSettingsRepository Tests', () {
    late MockSettingsRepository mockRepo;
    late SettingsRepositoryImpl implRepo;

    setUp(() {
      EnvConfig.useMockData = true;
      mockRepo = MockSettingsRepository();
      implRepo = SettingsRepositoryImpl(mockRepository: mockRepo);
    });

    test('getSettings returns default preferences suite', () async {
      final settings = await mockRepo.getSettings();
      expect(settings.language, 'en');
      expect(settings.appearance.theme, 'light');
      expect(settings.notifications.emailNotif, true);
      expect(settings.notifications.pushNotif, false);
      expect(settings.notifications.reportAlerts, true);
    });

    test('updateLanguage updates language code', () async {
      final lang = await mockRepo.updateLanguage('hi');
      expect(lang, 'hi');

      final settings = await mockRepo.getSettings();
      expect(settings.language, 'hi');
    });

    test('updateAppearance updates theme to dark', () async {
      final appearance = await mockRepo.updateAppearance('dark');
      expect(appearance.theme, 'dark');
      expect(appearance.isDark, true);

      final settings = await mockRepo.getSettings();
      expect(settings.appearance.isDark, true);
    });

    test('updateNotifications updates preference flags', () async {
      const newPrefs = NotificationPreferences(
        emailNotif: false,
        pushNotif: true,
        reportAlerts: false,
      );

      final updated = await mockRepo.updateNotifications(newPrefs);
      expect(updated.emailNotif, false);
      expect(updated.pushNotif, true);
      expect(updated.reportAlerts, false);

      final settings = await mockRepo.getSettings();
      expect(settings.notifications.emailNotif, false);
      expect(settings.notifications.pushNotif, true);
    });

    test('updateSettings updates entire configuration bundle', () async {
      const custom = UserSettings(
        language: 'hi',
        appearance: AppearanceSettings(theme: 'dark'),
        notifications: NotificationPreferences(
          emailNotif: false,
          pushNotif: false,
          reportAlerts: false,
        ),
        timezone: 'Asia/Dubai (GST)',
      );

      final result = await mockRepo.updateSettings(custom);
      expect(result.language, 'hi');
      expect(result.appearance.isDark, true);
      expect(result.timezone, 'Asia/Dubai (GST)');
    });

    test('SettingsRepositoryImpl delegates properly in mock mode', () async {
      final settings = await implRepo.getSettings();
      expect(settings.language, isNotEmpty);

      final lang = await implRepo.updateLanguage('en');
      expect(lang, 'en');
    });
  });
}
