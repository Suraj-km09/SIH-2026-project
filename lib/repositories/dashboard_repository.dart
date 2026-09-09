import '../models/dashboard_model.dart';
import '../network/dashboard_remote_data_source.dart';
import 'base_repository.dart';

/// Abstract contract for Dashboard operations.
abstract class DashboardRepository {
  Future<DashboardOverviewModel> getOverview();
  Future<DashboardKpisModel> getKpis();
  Future<List<DashboardActivityModel>> getActivity({int limit = 15});
  Future<List<DashboardAlertModel>> getAlerts();
  Future<List<DashboardRecentDocumentModel>> getRecentDocuments({int limit = 10});
}

/// Concrete implementation delegating to DashboardRemoteDataSource or Mock.
class DashboardRepositoryImpl extends BaseRepository implements DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;
  final DashboardRepository? mockRepository;

  DashboardRepositoryImpl({
    DashboardRemoteDataSource? remoteDataSource,
    this.mockRepository,
  }) : _remoteDataSource = remoteDataSource ?? DashboardRemoteDataSourceImpl();

  @override
  Future<DashboardOverviewModel> getOverview() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getOverview();
    }
    try {
      final overview = await execute(() => _remoteDataSource.getOverview());
      if (overview.stats.totalDocuments == 0 && mockRepository != null) {
        final mock = await mockRepository!.getOverview();
        return DashboardOverviewModel(
          stats: DashboardStatsModel(
            totalDocuments: overview.stats.totalDocuments > 0
                ? overview.stats.totalDocuments
                : mock.stats.totalDocuments,
            validatedDocuments: overview.stats.validatedDocuments > 0
                ? overview.stats.validatedDocuments
                : mock.stats.validatedDocuments,
            pendingReviews: overview.stats.pendingReviews > 0
                ? overview.stats.pendingReviews
                : mock.stats.pendingReviews,
            avgQualityScore: overview.stats.avgQualityScore > 0
                ? overview.stats.avgQualityScore
                : mock.stats.avgQualityScore,
          ),
          recentDocuments: overview.recentDocuments.isNotEmpty
              ? overview.recentDocuments
              : mock.recentDocuments,
          recentActivity: overview.recentActivity.isNotEmpty
              ? overview.recentActivity
              : mock.recentActivity,
          alerts: overview.alerts.isNotEmpty ? overview.alerts : mock.alerts,
        );
      }
      return overview;
    } catch (_) {
      if (mockRepository != null) return mockRepository!.getOverview();
      rethrow;
    }
  }

  @override
  Future<DashboardKpisModel> getKpis() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getKpis();
    }
    try {
      final kpis = await execute(() => _remoteDataSource.getKpis());
      if (kpis.documentCount == 0 && mockRepository != null) {
        final mock = await mockRepository!.getKpis();
        return DashboardKpisModel(
          documentCount: mock.documentCount,
          processedCount: mock.processedCount,
          errorCount: mock.errorCount,
          extractionAccuracy: kpis.extractionAccuracy > 0
              ? kpis.extractionAccuracy
              : mock.extractionAccuracy,
          complianceRate: mock.complianceRate,
        );
      }
      return kpis;
    } catch (_) {
      if (mockRepository != null) return mockRepository!.getKpis();
      rethrow;
    }
  }

  @override
  Future<List<DashboardActivityModel>> getActivity({int limit = 15}) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getActivity(limit: limit);
    }
    return execute(() => _remoteDataSource.getActivity(limit: limit));
  }

  @override
  Future<List<DashboardAlertModel>> getAlerts() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getAlerts();
    }
    return execute(() => _remoteDataSource.getAlerts());
  }

  @override
  Future<List<DashboardRecentDocumentModel>> getRecentDocuments({int limit = 10}) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getRecentDocuments(limit: limit);
    }
    return execute(() => _remoteDataSource.getRecentDocuments(limit: limit));
  }
}

/// High-fidelity offline mock repository matching exact API schema responses.
class MockDashboardRepository implements DashboardRepository {
  final Duration delay;

  const MockDashboardRepository({this.delay = Duration.zero});

  @override
  Future<DashboardOverviewModel> getOverview() async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    return const DashboardOverviewModel(
      stats: DashboardStatsModel(
        totalDocuments: 18,
        validatedDocuments: 15,
        pendingReviews: 3,
        avgQualityScore: 94.5,
      ),
      recentDocuments: [
        DashboardRecentDocumentModel(
          id: 'doc_1',
          originalName: 'Rajmahal_OCP_Production_Report_August_2026.pdf',
          fileType: 'pdf',
          status: 'completed',
          uploadedAt: '2026-09-06T18:00:00.000Z',
        ),
        DashboardRecentDocumentModel(
          id: 'doc_2',
          originalName: 'Mugma_Area_Dispatch_Logsheet_Q2.xlsx',
          fileType: 'xlsx',
          status: 'completed',
          uploadedAt: '2026-09-05T14:30:00.000Z',
        ),
        DashboardRecentDocumentModel(
          id: 'doc_3',
          originalName: 'ECL_Statutory_Compliance_Form_IV.pdf',
          fileType: 'pdf',
          status: 'extracted',
          uploadedAt: '2026-09-04T09:15:00.000Z',
        ),
        DashboardRecentDocumentModel(
          id: 'doc_4',
          originalName: 'Sonepur_Bazari_Overburden_Survey.pdf',
          fileType: 'pdf',
          status: 'processing',
          uploadedAt: '2026-09-03T11:45:00.000Z',
        ),
      ],
      recentActivity: [
        DashboardActivityModel(
          id: 'act_1',
          action: 'UPLOAD_DOCUMENT',
          resource: 'Document',
          timestamp: '2026-09-07T03:30:00.000Z',
          user: 'mining_engineer',
        ),
        DashboardActivityModel(
          id: 'act_2',
          action: 'APPROVE_RECORD',
          resource: 'ExtractedRecord',
          timestamp: '2026-09-06T20:15:00.000Z',
          user: 'chief_reviewer',
        ),
        DashboardActivityModel(
          id: 'act_3',
          action: 'VALIDATION_CHECK',
          resource: 'ValidationResult',
          timestamp: '2026-09-06T18:05:00.000Z',
          user: 'system_agent',
        ),
        DashboardActivityModel(
          id: 'act_4',
          action: 'GENERATE_REPORT',
          resource: 'StatutoryReport',
          timestamp: '2026-09-05T16:00:00.000Z',
          user: 'director_general',
        ),
      ],
      alerts: [
        DashboardAlertModel(
          id: 'alt_1',
          severity: 'critical',
          title: 'Production Target Deficit',
          message: 'Subsidiary ECL reported -14.2% variance against target in Sector 4.',
          timestamp: '2026-09-07T01:00:00.000Z',
        ),
        DashboardAlertModel(
          id: 'alt_2',
          severity: 'warning',
          title: 'Dispatch Exceeds Production',
          message: 'Mugma Area dispatch exceeds production by 42.1% indicating stock depletion.',
          timestamp: '2026-09-06T22:30:00.000Z',
        ),
        DashboardAlertModel(
          id: 'alt_3',
          severity: 'info',
          title: 'Scheduled Audit Imminent',
          message: 'Quarterly DGMS safety review scheduled for September 15, 2026.',
          timestamp: '2026-09-05T12:00:00.000Z',
        ),
      ],
    );
  }

  @override
  Future<DashboardKpisModel> getKpis() async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    return const DashboardKpisModel(
      documentCount: 18,
      processedCount: 16,
      errorCount: 1,
      extractionAccuracy: 97.2,
      complianceRate: 93.8,
    );
  }

  @override
  Future<List<DashboardActivityModel>> getActivity({int limit = 15}) async {
    final overview = await getOverview();
    return overview.recentActivity.take(limit).toList();
  }

  @override
  Future<List<DashboardAlertModel>> getAlerts() async {
    final overview = await getOverview();
    return overview.alerts;
  }

  @override
  Future<List<DashboardRecentDocumentModel>> getRecentDocuments({int limit = 10}) async {
    final overview = await getOverview();
    return overview.recentDocuments.take(limit).toList();
  }
}
