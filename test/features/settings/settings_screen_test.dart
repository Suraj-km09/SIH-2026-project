import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/features/settings/settings_screen.dart';
import 'package:mineintel_ai/models/user_model.dart';
import 'package:mineintel_ai/repositories/settings_repository.dart';
import 'package:mineintel_ai/state/auth_state.dart';

class _FakeAuthNotifier extends AuthNotifier {
  final UserModel _user;
  _FakeAuthNotifier(this._user);

  @override
  AuthState build() {
    return AuthState(status: AuthStatus.authenticated, user: _user);
  }
}

void main() {
  Widget buildSettingsTestHarness({
    SettingsRepository? repository,
    UserModel? user,
  }) {
    final effectiveUser = user ??
        const UserModel(
          id: 'usr-001',
          username: 'vishal',
          email: 'vishal@mineintel.ai',
          role: 'user',
          department: 'Mine Operations',
        );

    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          repository ?? MockSettingsRepository(),
        ),
        authNotifierProvider.overrideWith(() => _FakeAuthNotifier(effectiveUser)),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SettingsScreen(),
        ),
      ),
    );
  }

  group('Phase 11 SettingsScreen Widget Tests', () {
    setUp(() {
      EnvConfig.useMockData = true;
    });

    testWidgets('Renders tabs: Profile & Account, Appearance & Locale, Notification Channels',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSettingsTestHarness());
      await tester.pumpAndSettle();

      expect(find.text('User Settings & Preferences'), findsOneWidget);
      expect(find.text('Profile & Account'), findsOneWidget);
      expect(find.text('Appearance & Locale'), findsOneWidget);
      expect(find.text('Notification Channels'), findsOneWidget);

      expect(find.text('vishal'), findsOneWidget);
      expect(find.text('Save Profile'), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);
    });

    testWidgets('Appearance & Locale tab switches theme and language',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSettingsTestHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Appearance & Locale'));
      await tester.pumpAndSettle();

      expect(find.text('Light Theme'), findsOneWidget);
      expect(find.text('Dark Theme'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('हिन्दी (Hindi)'), findsOneWidget);

      await tester.tap(find.text('Dark Theme'));
      await tester.pumpAndSettle();
      expect(find.textContaining('DARK'), findsWidgets);

      await tester.tap(find.text('हिन्दी (Hindi)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('HI'), findsWidgets);
    });

    testWidgets('Notification Channels tab renders switches and saves preferences',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSettingsTestHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notification Channels'));
      await tester.pumpAndSettle();

      expect(find.text('Email Notifications'), findsOneWidget);
      expect(find.text('Push Notification Preference'), findsOneWidget);
      expect(find.text('Statutory Report Alerts'), findsOneWidget);

      expect(find.text('Save Preferences'), findsOneWidget);
      await tester.tap(find.text('Save Preferences'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Notification preferences saved successfully'), findsOneWidget);
    });
  });
}
