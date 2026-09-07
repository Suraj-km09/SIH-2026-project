import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/features/reviews/review_queue_screen.dart';
import 'package:mineintel_ai/models/user_model.dart';
import 'package:mineintel_ai/repositories/report_repository.dart';
import 'package:mineintel_ai/repositories/review_repository.dart';
import 'package:mineintel_ai/state/auth_state.dart';
import 'package:mineintel_ai/state/report_state.dart';
import 'package:mineintel_ai/state/review_state.dart';

void main() {
  group('Phase 8 ReviewQueueScreen RBAC & Widget Tests', () {
    testWidgets('Admin user sees enabled Approve and Reject actions', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final reportRepo = MockReportRepository();
      final reviewRepo = MockReviewRepository(reportRepository: reportRepo);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(reportRepo),
            reviewRepositoryProvider.overrideWithValue(reviewRepo),
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(
                  const UserModel(id: 'u_admin', username: 'admin', role: 'admin'),
                )),
          ],
          child: const MaterialApp(
            home: ReviewQueueScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Review Queue & Maker-Checker Governance'), findsOneWidget);
      expect(find.text('Administrator Sign-off Authority Active'), findsOneWidget);

      // Verify actions exist
      expect(find.widgetWithText(FilledButton, 'Approve'), findsWidgets);
      expect(find.widgetWithText(OutlinedButton, 'Reject'), findsWidgets);

      final approveBtn = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Approve').first);
      expect(approveBtn.onPressed, isNotNull);
    });

    testWidgets('Reviewer user has Reject enabled but Approve disabled (Admin Only)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final reportRepo = MockReportRepository();
      final reviewRepo = MockReviewRepository(reportRepository: reportRepo);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(reportRepo),
            reviewRepositoryProvider.overrideWithValue(reviewRepo),
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(
                  const UserModel(id: 'u_rev', username: 'reviewer_1', role: 'reviewer'),
                )),
          ],
          child: const MaterialApp(
            home: ReviewQueueScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Reviewer Evaluation Mode'), findsOneWidget);

      // Verify Reject is enabled for Reviewer
      final rejectBtn = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Reject').first);
      expect(rejectBtn.onPressed, isNotNull);

      // Verify Approve is disabled for Reviewer
      final approveBtn = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Approve').first);
      expect(approveBtn.onPressed, isNull);
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
