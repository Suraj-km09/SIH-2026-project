import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/models/settings_model.dart';

void main() {
  group('Phase 11 Settings Models', () {
    test('NotificationPreferences parses properly', () {
      final json = {
        'emailNotif': false,
        'pushNotif': true,
        'reportAlerts': false,
      };

      final prefs = NotificationPreferences.fromJson(json);
      expect(prefs.emailNotif, false);
      expect(prefs.pushNotif, true);
      expect(prefs.reportAlerts, false);

      final updated = prefs.copyWith(emailNotif: true);
      expect(updated.emailNotif, true);
      expect(updated.pushNotif, true);
      expect(updated.reportAlerts, false);
    });

    test('AppearanceSettings parses object and string', () {
      final fromObj = AppearanceSettings.fromJson({'theme': 'dark'});
      expect(fromObj.theme, 'dark');
      expect(fromObj.isDark, true);

      final fromString = AppearanceSettings.fromJson('light');
      expect(fromString.theme, 'light');
      expect(fromString.isDark, false);
    });

    test('UserSettings parses nested preferences and language', () {
      final json = {
        'language': 'hi',
        'appearance': {'theme': 'dark'},
        'notifications': {
          'emailNotif': true,
          'pushNotif': false,
          'reportAlerts': true,
        },
        'timezone': 'Asia/Kolkata (IST)',
      };

      final settings = UserSettings.fromJson(json);
      expect(settings.language, 'hi');
      expect(settings.appearance.isDark, true);
      expect(settings.notifications.emailNotif, true);
      expect(settings.notifications.pushNotif, false);
      expect(settings.timezone, 'Asia/Kolkata (IST)');
    });

    test('UserSettings copyWith and toJson roundtrip', () {
      const settings = UserSettings(
        language: 'en',
        appearance: AppearanceSettings(theme: 'light'),
        notifications: NotificationPreferences(
          emailNotif: true,
          pushNotif: false,
          reportAlerts: true,
        ),
        timezone: 'UTC (+00:00)',
      );

      final updated = settings.copyWith(language: 'hi');
      expect(updated.language, 'hi');
      expect(updated.timezone, 'UTC (+00:00)');

      final json = updated.toJson();
      expect(json['language'], 'hi');
      expect(json['appearance']['theme'], 'light');
      expect(json['notifications']['emailNotif'], true);
      expect(json['timezone'], 'UTC (+00:00)');
    });
  });
}
