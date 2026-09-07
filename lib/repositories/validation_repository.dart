import '../core/errors/failures.dart';
import '../models/validation_issue_model.dart';
import '../network/validation_remote_data_source.dart';
import 'base_repository.dart';

/// Abstract contract for Validation & Quality Control operations.
abstract class ValidationRepository {
  Future<ValidationSummaryModel> runValidation(String documentId);
  Future<ValidationSummaryModel> getValidationSummary(String documentId);
  Future<ValidationIssuesResponse> getValidationIssues(
    String documentId,
    ValidationFilter filter,
  );
  Future<ValidationIssueModel> resolveIssue(
    String issueId,
    ValidationIssueUpdateRequest request,
  );
  Future<ValidationApprovalResponse> approveValidation(String documentId);
  Future<ValidationReviewResponse> submitReview(
    String documentId,
    ValidationReviewRequest request,
  );
}

/// Concrete implementation delegating to ValidationRemoteDataSource or Mock.
class ValidationRepositoryImpl extends BaseRepository implements ValidationRepository {
  final ValidationRemoteDataSource _remoteDataSource;
  final ValidationRepository? mockRepository;

  ValidationRepositoryImpl({
    ValidationRemoteDataSource? remoteDataSource,
    this.mockRepository,
  }) : _remoteDataSource = remoteDataSource ?? ValidationRemoteDataSourceImpl();

  @override
  Future<ValidationSummaryModel> runValidation(String documentId) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.runValidation(documentId);
    }
    return execute(() => _remoteDataSource.runValidation(documentId));
  }

  @override
  Future<ValidationSummaryModel> getValidationSummary(String documentId) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getValidationSummary(documentId);
    }
    return execute(() => _remoteDataSource.getValidationSummary(documentId));
  }

  @override
  Future<ValidationIssuesResponse> getValidationIssues(
    String documentId,
    ValidationFilter filter,
  ) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getValidationIssues(documentId, filter);
    }
    return execute(() => _remoteDataSource.getValidationIssues(documentId, filter));
  }

  @override
  Future<ValidationIssueModel> resolveIssue(
    String issueId,
    ValidationIssueUpdateRequest request,
  ) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.resolveIssue(issueId, request);
    }
    return execute(() => _remoteDataSource.resolveIssue(issueId, request));
  }

  @override
  Future<ValidationApprovalResponse> approveValidation(String documentId) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.approveValidation(documentId);
    }
    return execute(() => _remoteDataSource.approveValidation(documentId));
  }

  @override
  Future<ValidationReviewResponse> submitReview(
    String documentId,
    ValidationReviewRequest request,
  ) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.submitReview(documentId, request);
    }
    return execute(() => _remoteDataSource.submitReview(documentId, request));
  }
}

/// High-fidelity offline mock repository implementing 8-rule validation results.
class MockValidationRepository implements ValidationRepository {
  final Duration delay;
  final Map<String, List<ValidationIssueModel>> _issuesByDoc = {};
  final Map<String, String> _validationStatusByDoc = {};

  MockValidationRepository({
    this.delay = Duration.zero,
    Map<String, List<ValidationIssueModel>>? initialIssues,
  }) {
    if (initialIssues != null) {
      _issuesByDoc.addAll(initialIssues);
    } else {
      _seedDefaultIssues();
    }
  }

  void _seedDefaultIssues() {
    _issuesByDoc['doc-001'] = [
      const ValidationIssueModel(
        id: 'iss-001-1',
        documentId: 'doc-001',
        recordId: 'rec-001-4',
        type: 'range_check',
        severity: 'warning',
        field: 'Ash Content',
        message: 'Ash content 14.2% is slightly above normal band (10.0% - 13.5%) for Seam VII.',
        status: 'open',
      ),
      const ValidationIssueModel(
        id: 'iss-001-2',
        documentId: 'doc-001',
        recordId: 'rec-001-3',
        type: 'math_discrepancy',
        severity: 'warning',
        field: 'Coal Dispatch Rail',
        message:
            'Rail dispatch volume (1,150.0 MT) differs from total production (1,420.5 MT) without recorded stockpile transfer.',
        status: 'open',
      ),
      const ValidationIssueModel(
        id: 'iss-001-3',
        documentId: 'doc-001',
        recordId: 'rec-001-2',
        type: 'unit_mismatch',
        severity: 'info',
        field: 'Overburden Removal',
        message: 'Excavation unit specified as Cu.m; standard reporting metric is BCM (Bank Cubic Metres).',
        status: 'resolved',
        resolution: 'Confirmed 1:1 parity with Cu.m for Rajmahal contractual tender.',
        resolvedAt: '2026-09-06T15:00:00.000Z',
        resolvedBy: 'admin',
      ),
    ];

    _issuesByDoc['doc-002'] = [
      const ValidationIssueModel(
        id: 'iss-002-1',
        documentId: 'doc-002',
        recordId: 'rec-002-2',
        type: 'suspicious_value',
        severity: 'error',
        field: 'Respirable Dust PM10',
        message: 'Respirable dust measured at 2.4 mg/m3; statutory DGMS threshold limit is 2.0 mg/m3.',
        status: 'open',
      ),
    ];
  }

  int _calculateQualityScore(List<ValidationIssueModel> issues) {
    int penalty = 0;
    for (final issue in issues.where((i) => i.isOpen)) {
      switch (issue.severity) {
        case 'critical':
          penalty += 25;
          break;
        case 'error':
          penalty += 15;
          break;
        case 'warning':
          penalty += 5;
          break;
        case 'info':
          penalty += 1;
          break;
      }
    }
    return (100 - penalty).clamp(0, 100);
  }

  @override
  Future<ValidationSummaryModel> runValidation(String documentId) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    if (!_issuesByDoc.containsKey(documentId)) {
      _issuesByDoc[documentId] = [
        ValidationIssueModel(
          id: 'iss-$documentId-1',
          documentId: documentId,
          type: 'range_check',
          severity: 'info',
          field: 'Monthly Output',
          message: 'Output verified against statutory coal lease entitlement limits.',
          status: 'open',
        ),
      ];
    }

    return getValidationSummary(documentId);
  }

  @override
  Future<ValidationSummaryModel> getValidationSummary(String documentId) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    final issues = _issuesByDoc[documentId] ?? [];
    final total = issues.length;
    final open = issues.where((i) => i.isOpen).length;
    final resolved = issues.where((i) => i.isResolved).length;

    final bySev = <String, int>{'info': 0, 'warning': 0, 'error': 0, 'critical': 0};
    final byType = <String, int>{};

    for (final issue in issues) {
      bySev[issue.severity] = (bySev[issue.severity] ?? 0) + 1;
      byType[issue.type] = (byType[issue.type] ?? 0) + 1;
    }

    final score = _calculateQualityScore(issues);

    return ValidationSummaryModel(
      documentId: documentId,
      documentName: 'Document-$documentId.pdf',
      documentStatus: _validationStatusByDoc[documentId] ?? 'completed',
      qualityScore: score,
      avgConfidence: 0.95,
      totalIssues: total,
      openIssues: open,
      resolvedIssues: resolved,
      recordsCount: 14,
      bySeverity: bySev,
      byType: byType,
      issues: issues,
    );
  }

  @override
  Future<ValidationIssuesResponse> getValidationIssues(
    String documentId,
    ValidationFilter filter,
  ) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    var list = List<ValidationIssueModel>.from(_issuesByDoc[documentId] ?? []);

    if (filter.status != null && filter.status!.isNotEmpty && filter.status != 'all') {
      list = list.where((i) => i.status.toLowerCase() == filter.status!.toLowerCase()).toList();
    }
    if (filter.severity != null && filter.severity!.isNotEmpty) {
      list = list.where((i) => i.severity.toLowerCase() == filter.severity!.toLowerCase()).toList();
    }
    if (filter.type != null && filter.type!.isNotEmpty) {
      list = list.where((i) => i.type.toLowerCase() == filter.type!.toLowerCase()).toList();
    }

    final total = list.length;
    final totalPages = (total / filter.limit).ceil().clamp(1, 99999);
    final startIndex = ((filter.page - 1) * filter.limit).clamp(0, total);
    final endIndex = (startIndex + filter.limit).clamp(0, total);
    final paginated = list.sublist(startIndex, endIndex);

    final allIssues = _issuesByDoc[documentId] ?? [];
    final bySev = <String, int>{'info': 0, 'warning': 0, 'error': 0, 'critical': 0};
    final byType = <String, int>{};

    for (final issue in allIssues) {
      bySev[issue.severity] = (bySev[issue.severity] ?? 0) + 1;
      byType[issue.type] = (byType[issue.type] ?? 0) + 1;
    }

    return ValidationIssuesResponse(
      issues: paginated,
      meta: ValidationPaginationMeta(
        total: total,
        page: filter.page,
        limit: filter.limit,
        pages: totalPages,
        qualityScore: _calculateQualityScore(allIssues),
        bySeverity: bySev,
        byType: byType,
      ),
    );
  }

  @override
  Future<ValidationIssueModel> resolveIssue(
    String issueId,
    ValidationIssueUpdateRequest request,
  ) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    for (final issues in _issuesByDoc.values) {
      final index = issues.indexWhere((i) => i.id == issueId);
      if (index != -1) {
        final old = issues[index];
        final updated = old.copyWith(
          status: request.status,
          resolution: request.resolution ?? old.resolution,
          correctedValue: request.correctedValue ?? old.correctedValue,
          notes: request.notes ?? old.notes,
          resolvedAt: DateTime.now().toUtc().toIso8601String(),
          resolvedBy: 'reviewer',
        );
        issues[index] = updated;
        return updated;
      }
    }

    throw NotFoundFailure('Validation issue with id $issueId not found.');
  }

  @override
  Future<ValidationApprovalResponse> approveValidation(String documentId) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    final issues = _issuesByDoc[documentId] ?? [];
    // Auto-resolve non-critical open issues
    for (int i = 0; i < issues.length; i++) {
      if (issues[i].isOpen && issues[i].severity != 'critical') {
        issues[i] = issues[i].copyWith(
          status: 'resolved',
          resolution: 'Auto-resolved upon formal validation approval',
          resolvedAt: DateTime.now().toUtc().toIso8601String(),
          resolvedBy: 'admin',
        );
      }
    }

    _validationStatusByDoc[documentId] = 'approved';

    return ValidationApprovalResponse(
      documentId: documentId,
      documentName: 'Document-$documentId.pdf',
      status: 'approved',
      approvedBy: 'admin',
      approvedAt: DateTime.now().toUtc().toIso8601String(),
      recordsApproved: 14,
    );
  }

  @override
  Future<ValidationReviewResponse> submitReview(
    String documentId,
    ValidationReviewRequest request,
  ) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    // Apply issue resolutions
    final issues = _issuesByDoc[documentId] ?? [];
    for (final res in request.issueResolutions) {
      final index = issues.indexWhere((i) => i.id == res.issueId);
      if (index != -1) {
        issues[index] = issues[index].copyWith(
          status: res.status,
          correctedValue: res.correctedValue,
          resolution: res.resolution,
          notes: res.notes,
          resolvedAt: DateTime.now().toUtc().toIso8601String(),
          resolvedBy: 'reviewer',
        );
      }
    }

    _validationStatusByDoc[documentId] = request.decision;

    return ValidationReviewResponse(
      documentId: documentId,
      documentName: 'Document-$documentId.pdf',
      status: request.decision,
      decision: request.decision,
      comments: request.comments,
    );
  }
}
