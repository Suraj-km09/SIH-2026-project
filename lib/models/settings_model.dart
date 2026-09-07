// Models for Module 06: User Settings & Preferences (/api/v1/settings/*).

/// Notification dispatch preferences.
class NotificationPreferences {
  final bool emailNotif;
  final bool pushNotif;
  final bool reportAlerts;

  const NotificationPreferences({
    this.emailNotif = true,
    this.pushNotif = false,
    this.reportAlerts = true,
  });

  NotificationPreferences copyWith({
    bool? emailNotif,
    bool? pushNotif,
    bool? reportAlerts,
  }) {
    return NotificationPreferences(
      emailNotif: emailNotif ?? this.emailNotif,
      pushNotif: pushNotif ?? this.pushNotif,
      reportAlerts: reportAlerts ?? this.reportAlerts,
    );
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      emailNotif: json['emailNotif'] as bool? ?? true,
      pushNotif: json['pushNotif'] as bool? ?? false,
      reportAlerts: json['reportAlerts'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'emailNotif': emailNotif,
        'pushNotif': pushNotif,
        'reportAlerts': reportAlerts,
      };
}

/// Appearance and UI theme settings.
class AppearanceSettings {
  final String theme; // 'light' | 'dark'

  const AppearanceSettings({
    this.theme = 'light',
  });

  bool get isDark => theme.toLowerCase() == 'dark';

  AppearanceSettings copyWith({String? theme}) {
    return AppearanceSettings(theme: theme ?? this.theme);
  }

  factory AppearanceSettings.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return AppearanceSettings(theme: json['theme'] as String? ?? 'light');
    } else if (json is String) {
      return AppearanceSettings(theme: json);
    }
    return const AppearanceSettings(theme: 'light');
  }

  Map<String, dynamic> toJson() => {
        'theme': theme,
      };
}

/// Comprehensive user configuration settings suite.
class UserSettings {
  final String language; // 'en' | 'hi'
  final AppearanceSettings appearance;
  final NotificationPreferences notifications;
  final String timezone; // e.g. 'Asia/Kolkata (IST)'

  const UserSettings({
    this.language = 'en',
    this.appearance = const AppearanceSettings(theme: 'light'),
    this.notifications = const NotificationPreferences(),
    this.timezone = 'Asia/Kolkata (IST)',
  });

  UserSettings copyWith({
    String? language,
    AppearanceSettings? appearance,
    NotificationPreferences? notifications,
    String? timezone,
  }) {
    return UserSettings(
      language: language ?? this.language,
      appearance: appearance ?? this.appearance,
      notifications: notifications ?? this.notifications,
      timezone: timezone ?? this.timezone,
    );
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    // Language can be string or object { language: 'en' }
    String lang = 'en';
    if (json['language'] is Map<String, dynamic>) {
      lang = json['language']['language'] as String? ?? 'en';
    } else if (json['language'] is String) {
      lang = json['language'] as String;
    }

    // Appearance can be string or object { theme: 'dark' }
    AppearanceSettings appSetting = const AppearanceSettings(theme: 'light');
    if (json['appearance'] != null) {
      appSetting = AppearanceSettings.fromJson(json['appearance']);
    }

    // Notifications
    NotificationPreferences notifs = const NotificationPreferences();
    if (json['notifications'] is Map<String, dynamic>) {
      notifs = NotificationPreferences.fromJson(
          json['notifications'] as Map<String, dynamic>);
    }

    // Timezone
    final tz = json['timezone'] as String? ?? 'Asia/Kolkata (IST)';

    return UserSettings(
      language: lang,
      appearance: appSetting,
      notifications: notifs,
      timezone: tz,
    );
  }

  Map<String, dynamic> toJson() => {
        'language': language,
        'appearance': appearance.toJson(),
        'notifications': notifications.toJson(),
        'timezone': timezone,
      };
}
