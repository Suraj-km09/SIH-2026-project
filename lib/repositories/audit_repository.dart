import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audit_model.dart';
import '../network/audit_remote_data_source.dart';
import 'base_repository.dart';

/// Abstract contract for System Audit Trail & Compliance Provenance.
abstract class AuditRepository {
  Future<AuditLogsResponse> getAuditLogs({
    int? limit,
    int? page,
    int? skip,
    String? action,
    String? status,
    String? resource,
    String? search,
    String? startDate,
    String? endDate,
  });

  Future<AuditStats> getStats();

  Future<AuditExportResult> exportAudit({
    String format = 'csv',
    String? action,
    String? resource,
    String? status,
  });

  Future<List<AuditLogEntry>> getUserAudit(String userId);

  Future<List<AuditLogEntry>> getDocumentAudit(String documentId);

  Future<List<AuditLogEntry>> getReportAudit(String reportId);

  Future<AuditLogEntry> getAuditDetail(String id);
}

/// Concrete implementation delegating to live API or fallback Mock.
class AuditRepositoryImpl extends BaseRepository implements AuditRepository {
  final AuditRemoteDataSource _remoteDataSource;
  final AuditRepository? mockRepository;

  AuditRepositoryImpl({
    AuditRemoteDataSource? remoteDataSource,
    this.mockRepository,
  }) : _remoteDataSource = remoteDataSource ?? AuditRemoteDataSource();

  @override
  Future<AuditLogsResponse> getAuditLogs({
    int? limit,
    int? page,
    int? skip,
    String? action,
    String? status,
    String? resource,
    String? search,
    String? startDate,
    String? endDate,
  }) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getAuditLogs(
        limit: limit,
        page: page,
        skip: skip,
        action: action,
        status: status,
        resource: resource,
        search: search,
        startDate: startDate,
        endDate: endDate,
      );
    }
    return execute(() => _remoteDataSource.getAuditLogs(
          limit: limit,
          page: page,
          skip: skip,
          action: action,
          status: status,
          resource: resource,
          search: search,
          startDate: startDate,
          endDate: endDate,
        ));
  }

  @override
  Future<AuditStats> getStats() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getStats();
    }
    return execute(() => _remoteDataSource.getStats());
  }

  @override
  Future<AuditExportResult> exportAudit({
    String format = 'csv',
    String? action,
    String? resource,
    String? status,
  }) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.exportAudit(
        format: format,
        action: action,
        resource: resource,
        status: status,
      );
    }
    return execute(() => _remoteDataSource.exportAudit(
          format: format,
          action: action,
          resource: resource,
          status: status,
        ));
  }

  @override
  Future<List<AuditLogEntry>> getUserAudit(String userId) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getUserAudit(userId);
    }
    return execute(() => _remoteDataSource.getUserAudit(userId));
  }

  @override
  Future<List<AuditLogEntry>> getDocumentAudit(String documentId) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getDocumentAudit(documentId);
    }
    return execute(() => _remoteDataSource.getDocumentAudit(documentId));
  }

  @override
  Future<List<AuditLogEntry>> getReportAudit(String reportId) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getReportAudit(reportId);
    }
    return execute(() => _remoteDataSource.getReportAudit(reportId));
  }

  @override
  Future<AuditLogEntry> getAuditDetail(String id) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getAuditDetail(id);
    }
    return execute(() => _remoteDataSource.getAuditDetail(id));
  }
}

/// High-fidelity in-memory Mock implementation for offline operation.
class MockAuditRepository implements AuditRepository {
  final List<AuditLogEntry> _mockLogs = [
    const AuditLogEntry(
      id: 'aud-001',
      user: AuditUser(id: 'usr-admin-01', username: 'admin', role: 'admin'),
      action: 'APPROVE_REPORT',
      resource: 'Report',
      resourceId: 'rep-q2-coal-2026',
      status: 'SUCCESS',
      ipAddress: '192.168.1.105',
      details: {
        'reportTitle': 'Quarterly Coal Production Compliance Q2',
        'approverRole': 'admin',
        'statutoryAuthority': 'DGMS / CIL',
        'comments': 'Statutory verification completed with all criteria passed.',
      },
      timestamp: '2026-09-07T04:25:00.000Z',
    ),
    const AuditLogEntry(
      id: 'aud-002',
      user: AuditUser(
          id: 'usr-reviewer-01', username: 'reviewer', role: 'reviewer'),
      action: 'REJECT_REPORT',
      resource: 'Report',
      resourceId: 'rep-env-audit-2026',
      status: 'SUCCESS',
      ipAddress: '192.168.1.112',
      details: {
        'reason': 'Stripping ratio in Pit-2 requires recalculation with updated surveying ledger.',
        'rejectionCode': 'QC_RULE_04_VARIANCE',
      },
      timestamp: '2026-09-07T03:50:00.000Z',
    ),
    const AuditLogEntry(
      id: 'aud-003',
      user: AuditUser(
          id: '64e0a1b2c3d4e5f6a7b8c9d0',
          username: 'vishal',
          role: 'user'),
      action: 'UPLOAD_DOCUMENT',
      resource: 'Document',
      resourceId: 'doc-bokaro-survey-01',
      status: 'SUCCESS',
      ipAddress: '10.0.4.52',
      details: {
        'filename': 'Bokaro OpenCast Survey 2026.pdf',
        'fileSize': 14829384,
        'mimeType': 'application/pdf',
        'sha256': '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08',
      },
      timestamp: '2026-09-07T02:15:30.000Z',
    ),
    const AuditLogEntry(
      id: 'aud-004',
      user: AuditUser(
          id: '64e0a1b2c3d4e5f6a7b8c9d0',
          username: 'vishal',
          role: 'user'),
      action: 'UPDATE_RECORD',
      resource: 'Record',
      resourceId: 'rec-monthly-prod-88',
      status: 'SUCCESS',
      ipAddress: '10.0.4.52',
      details: {
        'field': 'monthlyTonnage',
        'previousValue': 42800.0,
        'newValue': 44250.0,
        'unit': 'MT',
        'auditReason': 'Correction based on certified weighbridge scale slip #4401',
      },
      timestamp: '2026-09-06T17:40:00.000Z',
    ),
    const AuditLogEntry(
      id: 'aud-005',
      user: AuditUser(
          id: 'usr-guest-99', username: 'contractor_audit', role: 'user'),
      action: 'ACCESS_RESTRICTED_RESOURCE',
      resource: 'Admin',
      resourceId: 'sys-role-governance',
      status: 'FAILED',
      ipAddress: '203.0.113.19',
      details: {
        'errorCode': 403,
        'message': 'Unauthorized attempt to access Admin User Governance.',
      },
      timestamp: '2026-09-06T14:22:10.000Z',
    ),
    const AuditLogEntry(
      id: 'aud-006',
      user: AuditUser(id: 'usr-admin-01', username: 'admin', role: 'admin'),
      action: 'EXPORT_AUDIT',
      resource: 'Audit',
      resourceId: 'export-20260906',
      status: 'SUCCESS',
      ipAddress: '192.168.1.105',
      details: {
        'format': 'csv',
        'totalExportedLogs': 308,
        'complianceRecipient': 'Ministry of Coal Statutory Oversight Cell',
      },
      timestamp: '2026-09-06T10:00:00.000Z',
    ),
    const AuditLogEntry(
      id: 'aud-007',
      user: AuditUser(
          id: '64e0a1b2c3d4e5f6a7b8c9d0',
          username: 'vishal',
          role: 'user'),
      action: 'USER_LOGIN',
      resource: 'Auth',
      resourceId: 'sess-88912',
      status: 'SUCCESS',
      ipAddress: '10.0.4.52',
      details: {'authMethod': 'JWT_BEARER', 'userAgent': 'MineIntel/Flutter Windows'},
      timestamp: '2026-09-06T08:30:00.000Z',
    ),
    const AuditLogEntry(
      id: 'aud-008',
      user: AuditUser(
          id: 'usr-reviewer-01', username: 'reviewer', role: 'reviewer'),
      action: 'TRIGGER_PIPELINE',
      resource: 'Document',
      resourceId: 'doc-bokaro-survey-01',
      status: 'SUCCESS',
      ipAddress: '192.168.1.112',
      details: {
        'pipelineStage': 'OCR_AND_SEMANTIC_CHUNK',
        'targetEngine': 'TesseractOCR + Gemini-Pro-Embeddings',
      },
      timestamp: '2026-09-05T16:15:00.000Z',
    ),
  ];

  @override
  Future<AuditLogsResponse> getAuditLogs({
    int? limit,
    int? page,
    int? skip,
    String? action,
    String? status,
    String? resource,
    String? search,
    String? startDate,
    String? endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    var list = List<AuditLogEntry>.from(_mockLogs);

    if (action != null && action.isNotEmpty && action != 'ALL') {
      list = list
          .where((l) => l.action.toLowerCase() == action.toLowerCase())
          .toList();
    }
    if (status != null && status.isNotEmpty && status != 'ALL') {
      list = list
          .where((l) => l.status.toLowerCase() == status.toLowerCase())
          .toList();
    }
    if (resource != null && resource.isNotEmpty && resource != 'ALL') {
      list = list
          .where((l) => l.resource.toLowerCase() == resource.toLowerCase())
          .toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((l) {
        return l.action.toLowerCase().contains(q) ||
            l.resource.toLowerCase().contains(q) ||
            l.user.username.toLowerCase().contains(q) ||
            (l.ipAddress?.toLowerCase().contains(q) ?? false) ||
            (l.resourceId?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    final total = list.length;
    final effectiveLimit = limit ?? 100;
    final effectivePage = page ?? 1;

    return AuditLogsResponse(
      logs: list,
      meta: AuditMeta(
        total: total,
        limit: effectiveLimit,
        skip: skip ?? 0,
        page: effectivePage,
        pages: (total / effectiveLimit).ceil().clamp(1, 999),
      ),
    );
  }

  @override
  Future<AuditStats> getStats() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final successful = _mockLogs.where((l) => l.isSuccess).length;
    final failed = _mockLogs.where((l) => l.isFailed).length;
    final uniqueUsers = _mockLogs.map((l) => l.user.id).toSet().length;

    return AuditStats(
      totalEvents: _mockLogs.length,
      successful: successful,
      failed: failed,
      activeUsers: uniqueUsers,
    );
  }

  @override
  Future<AuditExportResult> exportAudit({
    String format = 'csv',
    String? action,
    String? resource,
    String? status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final logsRes = await getAuditLogs(
      action: action,
      resource: resource,
      status: status,
    );
    final logs = logsRes.logs;

    if (format.toLowerCase() == 'json') {
      final jsonString = const JsonEncoder.withIndent('  ').convert(
        logs.map((l) => l.toJson()).toList(),
      );
      return AuditExportResult(
        content: jsonString,
        format: 'json',
        filename: 'audit_logs_export.json',
      );
    } else {
      final buffer = StringBuffer();
      buffer.writeln(
          'id,timestamp,username,role,action,resource,resourceId,status,ipAddress');
      for (final log in logs) {
        buffer.writeln(
          '${log.id},${log.timestamp},${log.user.username},${log.user.role ?? ""},'
          '${log.action},${log.resource},${log.resourceId ?? ""},${log.status},${log.ipAddress ?? ""}',
        );
      }
      return AuditExportResult(
        content: buffer.toString(),
        format: 'csv',
        filename: 'audit_logs_export.csv',
      );
    }
  }

  @override
  Future<List<AuditLogEntry>> getUserAudit(String userId) async {
    await Future.delayed(const Duration(milliseconds: 120));
    return _mockLogs.where((l) => l.user.id == userId).toList();
  }

  @override
  Future<List<AuditLogEntry>> getDocumentAudit(String documentId) async {
    await Future.delayed(const Duration(milliseconds: 120));
    return _mockLogs
        .where((l) => l.resource == 'Document' && l.resourceId == documentId)
        .toList();
  }

  @override
  Future<List<AuditLogEntry>> getReportAudit(String reportId) async {
    await Future.delayed(const Duration(milliseconds: 120));
    return _mockLogs
        .where((l) => l.resource == 'Report' && l.resourceId == reportId)
        .toList();
  }

  @override
  Future<AuditLogEntry> getAuditDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final entry = _mockLogs.firstWhere(
      (l) => l.id == id,
      orElse: () => _mockLogs.first,
    );
    return entry;
  }
}

/// Global provider for AuditRepository.
final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepositoryImpl(
    mockRepository: MockAuditRepository(),
  );
});
