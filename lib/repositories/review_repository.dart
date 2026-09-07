import '../models/report_model.dart';
import '../network/review_remote_data_source.dart';
import 'base_repository.dart';
import 'report_repository.dart';

/// Abstract contract for Dedicated Maker-Checker Review Governance.
abstract class ReviewRepository {
  Future<List<ReviewItemModel>> getPendingReviews();
  Future<ReviewItemModel> getReviewById(String id);
  Future<ReportModel> approveReview(String id);
  Future<ReportModel> rejectReview(String id, String reason);
}

/// Concrete implementation delegating to ReviewRemoteDataSource or Mock.
class ReviewRepositoryImpl extends BaseRepository implements ReviewRepository {
  final ReviewRemoteDataSource _remoteDataSource;
  final ReviewRepository? mockRepository;

  ReviewRepositoryImpl({
    ReviewRemoteDataSource? remoteDataSource,
    this.mockRepository,
  }) : _remoteDataSource = remoteDataSource ?? ReviewRemoteDataSource();

  @override
  Future<List<ReviewItemModel>> getPendingReviews() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getPendingReviews();
    }
    return execute(() => _remoteDataSource.getPendingReviews());
  }

  @override
  Future<ReviewItemModel> getReviewById(String id) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getReviewById(id);
    }
    return execute(() => _remoteDataSource.getReviewById(id));
  }

  @override
  Future<ReportModel> approveReview(String id) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.approveReview(id);
    }
    return execute(() => _remoteDataSource.approveReview(id));
  }

  @override
  Future<ReportModel> rejectReview(String id, String reason) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.rejectReview(id, reason);
    }
    return execute(() => _remoteDataSource.rejectReview(id, reason));
  }
}

/// Standalone mock repository for Review governance.
class MockReviewRepository implements ReviewRepository {
  final ReportRepository _reportRepository;

  MockReviewRepository({ReportRepository? reportRepository})
      : _reportRepository = reportRepository ?? MockReportRepository();

  @override
  Future<List<ReviewItemModel>> getPendingReviews() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final reportsResp = await _reportRepository.getReports(const ReportFilter(status: 'review'));
    return reportsResp.reports.map((r) {
      return ReviewItemModel(
        id: 'rev_${r.id}',
        reportId: r.id,
        title: r.title,
        type: r.type,
        submittedBy: r.generatedBy ?? 'Mining Operator',
        submittedAt: r.createdAt ?? DateTime.now().toIso8601String(),
        confidenceScore: r.confidenceScore ?? 0.94,
        evidenceCount: 3,
        daysPending: 2,
        report: r,
      );
    }).toList();
  }

  @override
  Future<ReviewItemModel> getReviewById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final reportId = id.startsWith('rev_') ? id.substring(4) : id;
    final report = await _reportRepository.getReportById(reportId);
    return ReviewItemModel(
      id: id,
      reportId: report.id,
      title: report.title,
      type: report.type,
      submittedBy: report.generatedBy ?? 'Mining Operator',
      submittedAt: report.createdAt ?? DateTime.now().toIso8601String(),
      confidenceScore: report.confidenceScore ?? 0.94,
      evidenceCount: 3,
      daysPending: 2,
      report: report,
    );
  }

  @override
  Future<ReportModel> approveReview(String id) async {
    final reportId = id.startsWith('rev_') ? id.substring(4) : id;
    return _reportRepository.approveReport(reportId);
  }

  @override
  Future<ReportModel> rejectReview(String id, String reason) async {
    final reportId = id.startsWith('rev_') ? id.substring(4) : id;
    return _reportRepository.rejectReport(reportId, reason);
  }
}
