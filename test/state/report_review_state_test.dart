import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/models/report_model.dart';
import 'package:mineintel_ai/repositories/report_repository.dart';
import 'package:mineintel_ai/repositories/review_repository.dart';
import 'package:mineintel_ai/state/report_state.dart';
import 'package:mineintel_ai/state/review_state.dart';

void main() {
  test('older queue failure cannot replace a newer successful refresh', () async {
    final repository = _ControlledQueueRepository();
    final container = ProviderContainer(overrides: [reviewRepositoryProvider.overrideWithValue(repository)]);
    addTearDown(container.dispose);
    final notifier = container.read(reviewQueueNotifierProvider.notifier);
    final older = notifier.loadPendingReviews();
    final newer = notifier.loadPendingReviews();
    expect(await notifier.approveReview('report', expectedVersion: 0), isFalse);
    repository.loads.last.complete([]);
    await newer;
    repository.loads.first.completeError(StateError('Older queue request failed'));
    await older;
    expect(container.read(reviewQueueNotifierProvider).isSuccess, isTrue);
    expect(container.read(reviewQueueNotifierProvider).errorMessage, isNull);
  });

  for (final failOlder in [false, true]) {
    test('latest report load wins when older request ${failOlder ? 'fails' : 'completes'}', () async {
      final repository = _ControlledLoadRepository();
      final container = ProviderContainer(overrides: [reportRepositoryProvider.overrideWithValue(repository)]);
      addTearDown(container.dispose);
      final notifier = container.read(reportDetailNotifierProvider.notifier);
      final older = notifier.loadReport('older');
      final newer = notifier.loadReport('newer');
      repository.loads['newer']!.complete(const ReportModel(id: 'newer', title: 'Newer', type: 'production_summary', status: 'draft'));
      await newer;
      if (failOlder) {
        repository.loads['older']!.completeError(StateError('Old request failed'));
      } else {
        repository.loads['older']!.complete(const ReportModel(id: 'older', title: 'Older', type: 'production_summary', status: 'draft'));
      }
      await older;
      final state = container.read(reportDetailNotifierProvider);
      expect(state.report!.id, 'newer');
      expect(state.isSuccess, isTrue);
      expect(state.errorMessage, isNull);
    });
  }

  test('report load can finish after its provider is disposed', () async {
    final repository = _ControlledLoadRepository();
    final container = ProviderContainer(overrides: [reportRepositoryProvider.overrideWithValue(repository)]);
    final pending = container.read(reportDetailNotifierProvider.notifier).loadReport('report');
    container.dispose();
    repository.loads['report']!.complete(const ReportModel(id: 'report', title: 'Report', type: 'production_summary', status: 'draft'));
    await pending;
  });

  for (final action in ['update', 'submit', 'approve', 'reject']) {
    test('$action remains successful when its history refresh fails', () async {
      final repository = _FailingHistoryRepository();
      final container = ProviderContainer(overrides: [
        reportRepositoryProvider.overrideWithValue(repository),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(reportDetailNotifierProvider.notifier);
      final reportId = action == 'update' || action == 'submit' ? 'rep_003' : 'rep_002';
      await notifier.loadReport(reportId);
      final viewed = container.read(reportDetailNotifierProvider).report!;
      repository.failHistory = true;

      final bool success;
      switch (action) {
        case 'update':
          success = await notifier.updateReport(reportId, ReportUpdateRequest(expectedVersion: viewed.revision, title: 'Saved title'));
        case 'submit':
          success = await notifier.submitForReview(reportId, expectedVersion: viewed.revision);
        case 'approve':
          success = await notifier.approveReport(reportId, expectedVersion: viewed.revision);
        default:
          success = await notifier.rejectReport(reportId, 'Correction needed', expectedVersion: viewed.revision);
      }

      final state = container.read(reportDetailNotifierProvider);
      expect(success, isTrue);
      expect(state.report!.revision, viewed.revision + 1);
      expect(state.report!.status, {'update': 'draft', 'submit': 'review', 'approve': 'approved', 'reject': 'rejected'}[action]);
      expect(state.isActionLoading, isFalse);
      expect(state.actionMessage, isNotNull);
      expect(state.errorMessage, contains('Report saved'));
      expect(state.versions, isEmpty);
      expect(state.changes, isEmpty);
      expect((await repository.getReportById(reportId)).revision, viewed.revision + 1);
      repository.failHistory = false;
      await notifier.loadReport(reportId);
      expect(container.read(reportDetailNotifierProvider).errorMessage, isNull);
      expect(container.read(reportDetailNotifierProvider).report!.revision, viewed.revision + 1);
    });
  }

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

    test('stale report edit retains viewed data until explicit reload', () async {
      final notifier = container.read(reportDetailNotifierProvider.notifier);
      await notifier.loadReport('rep_003');
      final viewed = container.read(reportDetailNotifierProvider).report!;
      await mockRepo.updateReport(viewed.id, ReportUpdateRequest(
        expectedVersion: viewed.revision,
        title: 'Another editor saved',
      ));
      final draft = ReportUpdateRequest(expectedVersion: viewed.revision, title: 'My draft');
      expect(await notifier.updateReport(viewed.id, draft), isFalse);
      var state = container.read(reportDetailNotifierProvider);
      expect(state.report, same(viewed));
      expect(state.errorMessage, contains('Reload'));
      expect(await notifier.updateReport(viewed.id, draft), isFalse);
      await notifier.loadReport(viewed.id);
      state = container.read(reportDetailNotifierProvider);
      expect(state.errorMessage, isNull);
      expect(state.report!.title, 'Another editor saved');
      expect(await notifier.updateReport(viewed.id, ReportUpdateRequest(
        expectedVersion: state.report!.revision,
        title: 'My draft',
      )), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });

    test('overlapping report actions are not sent twice', () async {
      final notifier = container.read(reportDetailNotifierProvider.notifier);
      await notifier.loadReport('rep_003');
      final viewed = container.read(reportDetailNotifierProvider).report!;
      final request = ReportUpdateRequest(expectedVersion: viewed.revision, title: 'One save');
      final first = notifier.updateReport(viewed.id, request);
      expect(await notifier.updateReport(viewed.id, request), isFalse);
      expect(await notifier.submitForReview(viewed.id, expectedVersion: viewed.revision), isFalse);
      expect(await first, isTrue);
      expect((await mockRepo.getReportById(viewed.id)).revision, viewed.revision + 1);
      expect(container.read(reportDetailNotifierProvider).errorMessage, isNull);
    });

    for (final failAction in [false, true]) {
    test('navigation during a report action loads the latest requested report after ${failAction ? 'failure' : 'success'}', () async {
      final notifier = container.read(reportDetailNotifierProvider.notifier);
      await notifier.loadReport('rep_003');
      final viewed = container.read(reportDetailNotifierProvider).report!;
      final pending = notifier.submitForReview(viewed.id, expectedVersion: viewed.revision + (failAction ? 1 : 0));
      await notifier.loadReport('rep_001');
      await notifier.loadReport('rep_002');
      expect(await pending, !failAction);
      final state = container.read(reportDetailNotifierProvider);
      expect(state.report!.id, 'rep_002');
      expect(state.isSuccess, isTrue);
      expect(state.isActionLoading, isFalse);
    });
    }

    test('stale queue rejection retains item and requires reloaded revision', () async {
      final notifier = container.read(reviewQueueNotifierProvider.notifier);
      await notifier.loadPendingReviews();
      final viewed = container.read(reviewQueueNotifierProvider).items.first;
      await mockRepo.updateReport(viewed.reportId, ReportUpdateRequest(
        expectedVersion: viewed.revision,
        title: 'Changed during review',
      ));
      expect(await notifier.rejectReview(viewed.id, 'Check source', expectedVersion: viewed.revision), isFalse);
      expect(container.read(reviewQueueNotifierProvider).items, contains(viewed));
      expect(container.read(reviewQueueNotifierProvider).errorMessage, contains('Reload'));
      await notifier.loadPendingReviews();
      final fresh = container.read(reviewQueueNotifierProvider).items.firstWhere((item) => item.id == viewed.id);
      expect(fresh.revision, viewed.revision + 1);
      expect(container.read(reviewQueueNotifierProvider).errorMessage, isNull);
      expect(await notifier.rejectReview(fresh.id, 'Check source', expectedVersion: fresh.revision), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });

    for (final approve in [true, false]) {
      test('queue blocks overlapping decisions during ${approve ? 'approval' : 'rejection'}', () async {
        final notifier = container.read(reviewQueueNotifierProvider.notifier);
        await notifier.loadPendingReviews();
        final viewed = container.read(reviewQueueNotifierProvider).items.first;
        final first = approve
            ? notifier.approveReview(viewed.id, expectedVersion: viewed.revision)
            : notifier.rejectReview(viewed.id, 'Correction needed', expectedVersion: viewed.revision);
        expect(await notifier.approveReview(viewed.id, expectedVersion: viewed.revision), isFalse);
        expect(await notifier.rejectReview(viewed.id, 'Duplicate', expectedVersion: viewed.revision), isFalse);
        expect(await first, isTrue);
        expect((await mockRepo.getReportById(viewed.reportId)).revision, viewed.revision + 1);
        expect(container.read(reviewQueueNotifierProvider).errorMessage, isNull);
      });
    }

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
        ReportUpdateRequest(
          expectedVersion: state.report!.revision,
          title: 'Modified Title for rep_003',
          content: 'Updated markdown body text',
        ),
      );
      expect(updateSuccess, isTrue);

      state = container.read(reportDetailNotifierProvider);
      expect(state.report?.title, 'Modified Title for rep_003');
      expect(state.versions, isNotEmpty);

      final submitSuccess = await notifier.submitForReview('rep_003', expectedVersion: state.report!.revision);
      expect(submitSuccess, isTrue);

      state = container.read(reportDetailNotifierProvider);
      expect(state.report?.isReview, isTrue);
      expect(state.versions, isNotEmpty);
      expect(state.changes.any((change) => change.newValue == 'review'), isTrue);
    });

    test('ReviewQueueNotifier loads pending reviews and handles governance decisions', () async {
      final reviewNotifier = container.read(reviewQueueNotifierProvider.notifier);
      await reviewNotifier.loadPendingReviews();

      var reviewState = container.read(reviewQueueNotifierProvider);
      expect(reviewState.isSuccess, isTrue);
      expect(reviewState.items.isNotEmpty, isTrue);

      final target = reviewState.items.first;

      final approveSuccess = await reviewNotifier.approveReview(target.id, expectedVersion: target.revision);
      expect(approveSuccess, isTrue);

      reviewState = container.read(reviewQueueNotifierProvider);
      expect(reviewState.items.any((i) => i.id == target.id), isFalse);
      expect(reviewState.actionMessage, contains('approved and published'));
    });
  });
}

class _FailingHistoryRepository extends MockReportRepository {
  bool failHistory = false;

  @override
  Future<List<ReportVersionModel>> getReportVersionHistory(String id) async {
    if (failHistory) throw StateError('History unavailable');
    return super.getReportVersionHistory(id);
  }

  @override
  Future<List<ReportChangeModel>> getReportChanges(String id) async {
    if (failHistory) throw StateError('Changes unavailable');
    return super.getReportChanges(id);
  }
}

class _ControlledLoadRepository extends MockReportRepository {
  final loads = <String, Completer<ReportModel>>{};

  @override
  Future<ReportModel> getReportById(String id) {
    final pending = Completer<ReportModel>();
    loads[id] = pending;
    return pending.future;
  }

  @override
  Future<List<CitedEvidenceModel>> getReportEvidence(String id) async => [];

  @override
  Future<List<ReportVersionModel>> getReportVersionHistory(String id) async => [];

  @override
  Future<List<ReportChangeModel>> getReportChanges(String id) async => [];
}

class _ControlledQueueRepository extends MockReviewRepository {
  final loads = <Completer<List<ReviewItemModel>>>[];

  @override
  Future<List<ReviewItemModel>> getPendingReviews() {
    final pending = Completer<List<ReviewItemModel>>();
    loads.add(pending);
    return pending.future;
  }
}
