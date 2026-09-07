import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/models/report_model.dart';
import 'package:mineintel_ai/repositories/report_repository.dart';

void main() {
  group('Phase 8 ReportRepository & MockReportRepository Tests', () {
    late ReportRepository repository;

    setUp(() {
      EnvConfig.useMockData = true;
      repository = ReportRepositoryImpl(mockRepository: MockReportRepository());
    });

    tearDown(() {
      EnvConfig.useMockData = false;
    });

    test('getReports returns seeded reports and supports status filtering', () async {
      final all = await repository.getReports(const ReportFilter());
      expect(all.reports.isNotEmpty, isTrue);
      expect(all.meta.total, greaterThan(0));

      final approved = await repository.getReports(const ReportFilter(status: 'approved'));
      for (final r in approved.reports) {
        expect(r.status, 'approved');
      }
    });

    test('getReports supports type filtering', () async {
      final varianceReports = await repository.getReports(const ReportFilter(type: 'variance_analysis'));
      for (final r in varianceReports.reports) {
        expect(r.type, 'variance_analysis');
      }
    });

    test('generateReport creates a new report in draft status', () async {
      final newReport = await repository.generateReport(
        const ReportGenerateRequest(
          type: 'compliance_audit',
          title: 'Custom Statutory Environmental Audit',
          documentIds: ['doc_001'],
          language: 'en',
        ),
      );

      expect(newReport.id, startsWith('rep_'));
      expect(newReport.title, 'Custom Statutory Environmental Audit');
      expect(newReport.isDraft, isTrue);
      expect(newReport.version, 1);

      final fetched = await repository.getReportById(newReport.id);
      expect(fetched.title, 'Custom Statutory Environmental Audit');
    });

    test('updateReport increments version and records version history', () async {
      final report = await repository.getReportById('rep_003');

      final updated = await repository.updateReport(
        report.id,
        const ReportUpdateRequest(
          title: 'Updated Environmental Safeguards Audit',
          content: '# Updated Content\nNew observations added.',
        ),
      );

      expect(updated.title, 'Updated Environmental Safeguards Audit');
      expect(updated.version, report.version + 1);

      final history = await repository.getReportVersionHistory(report.id);
      expect(history.isNotEmpty, isTrue);
      expect(history.first.version, updated.version);
    });

    test('submitForReview transitions status to review', () async {
      final report = await repository.getReportById('rep_003');
      final submitted = await repository.submitForReview(report.id);
      expect(submitted.isReview, isTrue);

      final changes = await repository.getReportChanges(report.id);
      expect(changes.any((c) => c.field == 'status' && c.newValue == 'review'), isTrue);
    });

    test('approveReport transitions status to approved with admin stamp', () async {
      final approved = await repository.approveReport('rep_002');
      expect(approved.isApproved, isTrue);
      expect(approved.approvedBy, 'admin');
      expect(approved.approvedAt, isNotNull);
    });

    test('rejectReport transitions status to rejected and records reason', () async {
      final rejected = await repository.rejectReport(
        'rep_002',
        'Overburden bench survey failed reconciliation.',
      );
      expect(rejected.isRejected, isTrue);
      expect(rejected.reviewerComments, 'Overburden bench survey failed reconciliation.');
      expect(rejected.reviewedAt, isNotNull);
    });

    test('getReportEvidence returns citations', () async {
      final evidence = await repository.getReportEvidence('rep_001');
      expect(evidence.isNotEmpty, isTrue);
      expect(evidence.first.snippet.isNotEmpty, isTrue);
    });

    test('exportReport returns data for all supported formats', () async {
      final pdfData = await repository.exportReport('rep_001', 'pdf');
      expect(pdfData, isNotNull);

      final docxData = await repository.exportReport('rep_001', 'docx');
      expect(docxData, isNotNull);

      final csvData = await repository.exportReport('rep_001', 'csv');
      expect(csvData, isA<String>());
      expect(csvData.toString(), contains('Field,Value'));

      final jsonData = await repository.exportReport('rep_001', 'json');
      expect(jsonData, isA<String>());
      expect(jsonData.toString(), contains('Monthly Statutory Production Summary'));
    });

    test('deleteReport deletes report', () async {
      final success = await repository.deleteReport('rep_004');
      expect(success, isTrue);

      expect(() => repository.getReportById('rep_004'), throwsA(isA<Exception>()));
    });
  });
}
