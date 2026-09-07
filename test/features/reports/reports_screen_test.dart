import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/features/reports/report_detail_screen.dart';
import 'package:mineintel_ai/features/reports/reports_list_screen.dart';
import 'package:mineintel_ai/models/user_model.dart';
import 'package:mineintel_ai/repositories/report_repository.dart';
import 'package:mineintel_ai/state/auth_state.dart';
import 'package:mineintel_ai/state/report_state.dart';

void main() {
  group('Phase 8 ReportsListScreen Widget Tests', () {
    testWidgets('Renders report list, KPI stats cards, and filter toolbar', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockReportRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(
                  const UserModel(id: 'u_1', username: 'admin', role: 'admin'),
                )),
          ],
          child: const MaterialApp(
            home: ReportsListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Statutory Reports & Regulatory Filings'), findsOneWidget);
      expect(find.text('Total Reports'), findsOneWidget);
      expect(find.text('Draft Reports'), findsOneWidget);
      expect(find.text('Generate Report'), findsOneWidget);

      // Verify report titles
      expect(find.textContaining('Gevra OCP'), findsWidgets);
    });

    testWidgets('ReportDetailScreen renders content narrative and tabs', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockReportRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(
                  const UserModel(id: 'u_1', username: 'admin', role: 'admin'),
                )),
          ],
          child: const MaterialApp(
            home: ReportDetailScreen(reportId: 'rep_001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Report Content'), findsOneWidget);
      expect(find.text('Evidence & Citations'), findsOneWidget);
      expect(find.text('Version History'), findsOneWidget);
      expect(find.text('Changes Diff'), findsOneWidget);

      // Verify content
      expect(find.textContaining('Gevra Open Cast Project'), findsWidgets);

      // Switch to Evidence tab
      await tester.tap(find.text('Evidence & Citations'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Gevra_Monthly_Production_May2024.pdf'), findsWidgets);
    });
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  final UserModel _user;
  _FakeAuthNotifier(this._user);

  @override
  AuthState build() {
    return AuthState(status: AuthStatus.authenticated, user: _user);
  }
}
