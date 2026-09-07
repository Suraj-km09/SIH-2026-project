import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/repositories/report_repository.dart';
import 'package:mineintel_ai/repositories/review_repository.dart';

void main() {
  group('Phase 8 ReviewRepository & MockReviewRepository Tests', () {
    late ReportRepository reportRepo;
    late ReviewRepository reviewRepo;

    setUp(() {
      EnvConfig.useMockData = true;
      reportRepo = MockReportRepository();
      reviewRepo = ReviewRepositoryImpl(
        mockRepository: MockReviewRepository(reportRepository: reportRepo),
      );
    });

    tearDown(() {
      EnvConfig.useMockData = false;
    });

    test('getPendingReviews returns reports currently in review status', () async {
      final items = await reviewRepo.getPendingReviews();
      expect(items.isNotEmpty, isTrue);
      for (final item in items) {
        expect(item.report?.isReview, isTrue);
      }
    });

    test('getReviewById returns detailed review telemetry', () async {
      final items = await reviewRepo.getPendingReviews();
      final target = items.first;

      final review = await reviewRepo.getReviewById(target.id);
      expect(review.id, target.id);
      expect(review.reportId, target.reportId);
      expect(review.confidenceScore, greaterThan(0.5));
    });

    test('approveReview formally approves report', () async {
      final items = await reviewRepo.getPendingReviews();
      final target = items.first;

      final approved = await reviewRepo.approveReview(target.id);
      expect(approved.isApproved, isTrue);
      expect(approved.approvedBy, 'admin');
    });

    test('rejectReview records rejection reason on report', () async {
      final items = await reviewRepo.getPendingReviews();
      final target = items.first;

      final rejected = await reviewRepo.rejectReview(
        target.id,
        'Survey benchmarks require re-triangulation.',
      );
      expect(rejected.isRejected, isTrue);
      expect(rejected.reviewerComments, 'Survey benchmarks require re-triangulation.');
    });
  });
}
