import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/models/report_model.dart';

void main() {
  group('Phase 8 Report Models Tests', () {
    test('ReportModel json serialization and deserialization', () {
      final json = {
        '_id': 'rep_101',
        'title': 'Monthly Statutory Production Summary - Gevra OCP',
        'type': 'production_summary',
        'content': '# Production Summary\nTotal production: 124,500 MT',
        'status': 'draft',
        'fileUrl': 'https://cdn.mineintel.ai/reports/rep_101.pdf',
        'generatedBy': 'analyst_sharma',
        'reviewerId': null,
        'reviewerComments': null,
        'reviewedAt': null,
        'approvedBy': null,
        'approvedAt': null,
        'version': 1,
        'confidenceScore': 0.96,
        'language': 'en',
        'createdAt': '2026-09-07T10:00:00Z',
        'documentIds': ['doc_001'],
      };

      final report = ReportModel.fromJson(json);

      expect(report.id, 'rep_101');
      expect(report.title, 'Monthly Statutory Production Summary - Gevra OCP');
      expect(report.type, 'production_summary');
      expect(report.contentAsString, contains('Total production: 124,500 MT'));
      expect(report.isDraft, isTrue);
      expect(report.isApproved, isFalse);
      expect(report.isReview, isFalse);
      expect(report.version, 1);
      expect(report.confidenceScore, 0.96);
      expect(report.language, 'en');
      expect(report.documentIds, contains('doc_001'));

      final serialized = report.toJson();
      expect(serialized['_id'], 'rep_101');
      expect(serialized['title'], 'Monthly Statutory Production Summary - Gevra OCP');
      expect(serialized['status'], 'draft');
    });

    test('ReportFilter toQueryParams formatting', () {
      const filter = ReportFilter(
        type: 'variance_analysis',
        status: 'review',
        page: 2,
        limit: 10,
      );

      final params = filter.toQueryParams();
      expect(params['type'], 'variance_analysis');
      expect(params['status'], 'review');
      expect(params['page'], 2);
      expect(params['limit'], 10);
    });

    test('CitedEvidenceModel and ReportVersionModel serialization', () {
      final evJson = {
        'documentId': 'doc_001',
        'documentName': 'Gevra_Production.pdf',
        'pageNumber': 3,
        'snippet': 'Total ROM coal extracted was 124,500 MT',
        'similarity': 0.98,
      };
      final evidence = CitedEvidenceModel.fromJson(evJson);
      expect(evidence.documentId, 'doc_001');
      expect(evidence.pageNumber, 3);
      expect(evidence.similarity, 0.98);

      final verJson = {
        'version': 2,
        'title': 'Revised Production Summary',
        'content': '# Revised...',
        'updatedBy': 'analyst_1',
        'updatedAt': '2026-09-07T12:00:00Z',
        'changeSummary': 'Updated ambient air monitoring values',
      };
      final version = ReportVersionModel.fromJson(verJson);
      expect(version.version, 2);
      expect(version.updatedBy, 'analyst_1');
      expect(version.changeSummary, contains('ambient air monitoring'));
    });

    test('ReviewItemModel parsing', () {
      final json = {
        '_id': 'rev_001',
        'reportId': 'rep_002',
        'title': 'Quarterly Overburden Variance',
        'type': 'variance_analysis',
        'submittedBy': 'operator_roy',
        'submittedAt': '2026-09-07T08:00:00Z',
        'confidenceScore': 0.92,
        'evidenceCount': 4,
        'daysPending': 1,
      };

      final reviewItem = ReviewItemModel.fromJson(json);
      expect(reviewItem.id, 'rev_001');
      expect(reviewItem.reportId, 'rep_002');
      expect(reviewItem.confidenceScore, 0.92);
      expect(reviewItem.evidenceCount, 4);
    });
  });
}
