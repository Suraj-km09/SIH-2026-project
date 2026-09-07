import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/models/report_model.dart';
import 'package:mineintel_ai/repositories/report_repository.dart';
import 'package:mineintel_ai/repositories/review_repository.dart';
import 'package:mineintel_ai/state/report_state.dart';
import 'package:mineintel_ai/state/review_state.dart';

void main() {
  group('Phase 8 Report and Review Riverpod State Tests', () {
    late ProviderContainer container;
    late MockReportRepository mockRepo;
    late MockReviewRepository mockReviewRepo;

    setUp(() {
      EnvConfig.useMockData = true;
      mockRepo = MockReportRepository();
      mockReviewRepo = MockReviewRepository(reportRepository: mockRepo);
      container = ProviderContainer(
        overrides: [
          reportRepositoryProvider.overrideWithValue(mockRepo),
          reviewRepositoryProvider.overrideWithValue(mockReviewRepo),
        ],
      );
    });

    tearDown(() {
      EnvConfig.useMockData = false;
      container.dispose();
    });

    test('ReportListNotifier loads reports and applies filters', () async {
      final notifier = container.read(reportListNotifierProvider.notifier);
      await notifier.loadReports();

      final state = container.read(reportListNotifierProvider);
      expect(state.isSuccess, isTrue);
      expect(state.reports.isNotEmpty, isTrue);

      notifier.setFilter(const ReportFilter(status: 'approved'));
      await Future.delayed(const Duration(milliseconds: 200));

      final filteredState = container.read(reportListNotifierProvider);
      for (final r in filteredState.reports) {
        expect(r.status, 'approved');
      }
    });

    test('ReportListNotifier generateReport prepends new report', () async {
      final notifier = container.read(reportListNotifierProvider.notifier);
      await notifier.loadReports();

      final initialCount = container.read(reportListNotifierProvider).reports.length;

      final generated = await notifier.generateReport(
        const ReportGenerateRequest(
          type: 'compliance_audit',
          title: 'New Statutory Filing',
          documentIds: ['doc_001'],
        ),
      );

      expect(generated, isNotNull);
      final newState = container.read(reportListNotifierProvider);
      expect(newState.reports.length, initialCount + 1);
      expect(newState.reports.first.title, 'New Statutory Filing');
      expect(newState.actionMessage, contains('generated successfully'));
    });

    test('ReportListNotifier deleteReport removes report', () async {
      final notifier = container.read(reportListNotifierProvider.notifier);
      await notifier.loadReports();

      final target = container.read(reportListNotifierProvider).reports.first;
      final success = await notifier.deleteReport(target.id);
      expect(success, isTrue);

      final newState = container.read(reportListNotifierProvider);
      expect(newState.reports.any((r) => r.id == target.id), isFalse);
    });

    test('ReportDetailNotifier loads report, updates content, and submits review', () async {
      final notifier = container.read(reportDetailNotifierProvider.notifier);
      await notifier.loadReport('rep_003');

      var state = container.read(reportDetailNotifierProvider);
      expect(state.isSuccess, isTrue);
      expect(state.report?.id, 'rep_003');
      expect(state.evidence, isNotNull);
      expect(state.versions, isNotNull);

      final updateSuccess = await notifier.updateReport(
        'rep_003',
        const ReportUpdateRequest(
          title: 'Modified Title for rep_003',
          content: 'Updated markdown body text',
        ),
      );
      expect(updateSuccess, isTrue);

      state = container.read(reportDetailNotifierProvider);
      expect(state.report?.title, 'Modified Title for rep_003');

      final submitSuccess = await notifier.submitForReview('rep_003');
      expect(submitSuccess, isTrue);

      state = container.read(reportDetailNotifierProvider);
      expect(state.report?.isReview, isTrue);
    });

    test('ReviewQueueNotifier loads pending reviews and handles governance decisions', () async {
      final reviewNotifier = container.read(reviewQueueNotifierProvider.notifier);
      await reviewNotifier.loadPendingReviews();

      var reviewState = container.read(reviewQueueNotifierProvider);
      expect(reviewState.isSuccess, isTrue);
      expect(reviewState.items.isNotEmpty, isTrue);

      final target = reviewState.items.first;

      final approveSuccess = await reviewNotifier.approveReview(target.id);
      expect(approveSuccess, isTrue);

      reviewState = container.read(reviewQueueNotifierProvider);
      expect(reviewState.items.any((i) => i.id == target.id), isFalse);
      expect(reviewState.actionMessage, contains('approved and published'));
    });
  });
}
