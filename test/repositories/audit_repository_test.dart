import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/repositories/audit_repository.dart';

void main() {
  group('Phase 11 AuditRepository & MockAuditRepository Tests', () {
    late MockAuditRepository mockRepo;
    late AuditRepositoryImpl implRepo;

    setUp(() {
      EnvConfig.useMockData = true;
      mockRepo = MockAuditRepository();
      implRepo = AuditRepositoryImpl(mockRepository: mockRepo);
    });

    test('getAuditLogs returns default list with metadata', () async {
      final response = await mockRepo.getAuditLogs();
      expect(response.logs, isNotEmpty);
      expect(response.meta?.total, greaterThan(0));
      expect(response.meta?.limit, 100);
      expect(response.meta?.page, 1);
    });

    test('getAuditLogs filters by action', () async {
      final response =
          await mockRepo.getAuditLogs(action: 'APPROVE_REPORT');
      expect(response.logs, isNotEmpty);
      expect(
        response.logs.every((l) => l.action == 'APPROVE_REPORT'),
        isTrue,
      );
    });

    test('getAuditLogs filters by status', () async {
      final failedResp = await mockRepo.getAuditLogs(status: 'FAILED');
      expect(failedResp.logs, isNotEmpty);
      expect(failedResp.logs.every((l) => l.isFailed), isTrue);

      final successResp = await mockRepo.getAuditLogs(status: 'SUCCESS');
      expect(successResp.logs, isNotEmpty);
      expect(successResp.logs.every((l) => l.isSuccess), isTrue);
    });

    test('getAuditLogs filters by search term across fields', () async {
      final response = await mockRepo.getAuditLogs(search: 'admin');
      expect(response.logs, isNotEmpty);
      expect(
        response.logs.every((l) =>
            l.user.username.contains('admin') ||
            l.action.toLowerCase().contains('admin') ||
            l.resource.toLowerCase().contains('admin')),
        isTrue,
      );
    });

    test('getStats calculates correct aggregate metrics', () async {
      final stats = await mockRepo.getStats();
      expect(stats.totalEvents, greaterThan(0));
      expect(stats.successful, greaterThan(0));
      expect(stats.failed, greaterThanOrEqualTo(0));
      expect(stats.activeUsers, greaterThan(0));
      expect(stats.successful + stats.failed, equals(stats.totalEvents));
    });

    test('exportAudit returns formatted CSV data', () async {
      final exportResult = await mockRepo.exportAudit(format: 'csv');
      expect(exportResult.format, 'csv');
      expect(exportResult.filename, 'audit_logs_export.csv');
      expect(exportResult.content, contains('id,timestamp,username,role'));
      expect(exportResult.content.split('\n').length, greaterThan(2));
    });

    test('exportAudit returns formatted JSON data', () async {
      final exportResult = await mockRepo.exportAudit(format: 'json');
      expect(exportResult.format, 'json');
      expect(exportResult.filename, 'audit_logs_export.json');
      final decoded = jsonDecode(exportResult.content);
      expect(decoded, isA<List>());
      expect((decoded as List), isNotEmpty);
    });

    test('getUserAudit returns logs scoped to a specific user', () async {
      final logs =
          await mockRepo.getUserAudit('64e0a1b2c3d4e5f6a7b8c9d0');
      expect(logs, isNotEmpty);
      expect(
        logs.every((l) => l.user.id == '64e0a1b2c3d4e5f6a7b8c9d0'),
        isTrue,
      );
    });

    test('getDocumentAudit returns provenance for target document', () async {
      final logs =
          await mockRepo.getDocumentAudit('doc-bokaro-survey-01');
      expect(logs, isNotEmpty);
      expect(
        logs.every((l) =>
            l.resource == 'Document' &&
            l.resourceId == 'doc-bokaro-survey-01'),
        isTrue,
      );
    });

    test('getReportAudit returns provenance for target report', () async {
      final logs = await mockRepo.getReportAudit('rep-q2-coal-2026');
      expect(logs, isNotEmpty);
      expect(
        logs.every(
            (l) => l.resource == 'Report' && l.resourceId == 'rep-q2-coal-2026'),
        isTrue,
      );
    });

    test('getAuditDetail returns single log record', () async {
      final detail = await mockRepo.getAuditDetail('aud-001');
      expect(detail.id, 'aud-001');
      expect(detail.action, 'APPROVE_REPORT');
      expect(detail.details, isNotEmpty);
    });

    test('AuditRepositoryImpl delegates to mock repository in mock mode', () async {
      final response = await implRepo.getAuditLogs();
      expect(response.logs, isNotEmpty);

      final stats = await implRepo.getStats();
      expect(stats.totalEvents, greaterThan(0));

      final export = await implRepo.exportAudit(format: 'csv');
      expect(export.format, 'csv');
    });
  });
}
