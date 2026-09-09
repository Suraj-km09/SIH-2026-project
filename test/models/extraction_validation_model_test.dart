import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/models/extracted_record_model.dart';
import 'package:mineintel_ai/models/validation_issue_model.dart';

void main() {
  group('Phase 7 Extraction Models Tests', () {
    test('ExtractedRecordModel json serialization and deserialization', () {
      final json = {
        '_id': 'rec_101',
        'documentId': 'doc_001',
        'pageNumber': 2,
        'parameter': 'Coal Production (ROM)',
        'value': '124500',
        'unit': 'Tonnes',
        'period': 'May 2024',
        'mineName': 'Gevra OCP',
        'subsidiary': 'SECL',
        'confidenceScore': 0.96,
        'sourceText': 'Total ROM coal production during May 2024 was 124,500 Tonnes.',
        'status': 'pending',
        'originalValue': '124500',
        'editHistory': [
          {
            'field': 'value',
            'oldValue': '120000',
            'newValue': '124500',
            'editedAt': '2026-09-07T10:00:00Z',
            'editedBy': 'analyst_1',
          }
        ],
        'linkedEvidence': [
          {
            'pageNumber': 2,
            'snippet': '124,500 Tonnes produced',
            'similarity': 0.97,
          }
        ],
      };

      final record = ExtractedRecordModel.fromJson(json);

      expect(record.id, 'rec_101');
      expect(record.documentId, 'doc_001');
      expect(record.parameter, 'Coal Production (ROM)');
      expect(record.value, '124500');
      expect(record.unit, 'Tonnes');
      expect(record.confidence, 0.96);
      expect(record.isPending, isTrue);
      expect(record.isApproved, isFalse);
      expect(record.editHistory.length, 1);
      expect(record.editHistory.first.editedBy, 'analyst_1');
      expect(record.linkedEvidence.first.similarity, 0.97);

      final serialized = record.toJson();
      expect(serialized['_id'], 'rec_101');
      expect(serialized['parameter'], 'Coal Production (ROM)');
      expect(serialized['confidenceScore'], 0.96);
    });

    test('ExtractionSummaryStats and ExtractionSummaryModel parsing', () {
      final json = {
        'documentId': 'doc_001',
        'summary': {
          'total': 20,
          'approved': 15,
          'pending': 4,
          'rejected': 1,
          'avgConfidence': 0.935,
          'parameters': ['Coal Production', 'Overburden Removal'],
        },
        'records': [],
      };

      final summaryModel = ExtractionSummaryModel.fromJson(json);
      expect(summaryModel.documentId, 'doc_001');
      expect(summaryModel.summary.totalRecords, 20);
      expect(summaryModel.summary.approvedRecords, 15);
      expect(summaryModel.summary.pendingRecords, 4);
      expect(summaryModel.summary.rejectedRecords, 1);
      expect(summaryModel.summary.averageConfidence, 0.935);
      expect(summaryModel.summary.parameters.length, 2);
    });

    test('ExtractionFilter toQueryParams formatting', () {
      const filter = ExtractionFilter(
        status: 'pending',
        parameter: 'Overburden',
        mineName: 'Dipka',
        minConfidence: 85.0,
        page: 2,
        limit: 25,
      );

      final params = filter.toQueryParams();
      expect(params['status'], 'pending');
      expect(params['parameter'], 'Overburden');
      expect(params['mineName'], 'Dipka');
      expect(params['minConfidence'], 85.0);
      expect(params['page'], 2);
      expect(params['limit'], 25);
    });
  });

  group('Phase 7 Validation Models Tests', () {
    test('ValidationIssueModel serialization and getters', () {
      final json = {
        '_id': 'iss_001',
        'documentId': 'doc_001',
        'recordId': 'rec_101',
        'type': 'range_check',
        'severity': 'critical',
        'field': 'Stripping Ratio',
        'message': 'Stripping ratio exceeds valid mining baseline of 5.0 m3/t.',
        'status': 'open',
        'currentValue': '12.4',
        'suggestedValue': '2.4',
        'resolution': null,
        'correctedValue': null,
        'notes': null,
      };

      final issue = ValidationIssueModel.fromJson(json);

      expect(issue.id, 'iss_001');
      expect(issue.documentId, 'doc_001');
      expect(issue.type, 'range_check');
      expect(issue.isCritical, isTrue);
      expect(issue.isOpen, isTrue);
      expect(issue.isResolved, isFalse);
      expect(issue.currentValue, '12.4');
      expect(issue.suggestedValue, '2.4');

      final serialized = issue.toJson();
      expect(serialized['_id'], 'iss_001');
      expect(serialized['severity'], 'critical');
      expect(serialized['currentValue'], '12.4');
    });

    test('ValidationSummaryModel calculations and distribution', () {
      final json = {
        'documentId': 'doc_001',
        'documentName': 'Gevra_Production_Report.pdf',
        'qualityScore': 88,
        'avgConfidence': 0.94,
        'totalIssues': 4,
        'openIssues': 2,
        'resolvedIssues': 2,
        'recordsCount': 35,
        'bySeverity': {'critical': 1, 'error': 1, 'warning': 1, 'info': 1},
        'byType': {'range_check': 2, 'math_discrepancy': 2},
        'issues': [],
      };

      final summary = ValidationSummaryModel.fromJson(json);

      expect(summary.documentId, 'doc_001');
      expect(summary.qualityScore, 88);
      expect(summary.totalIssues, 4);
      expect(summary.openIssues, 2);
      expect(summary.resolvedIssues, 2);
      expect(summary.recordsCount, 35);
      expect(summary.bySeverity['critical'], 1);
      expect(summary.byType['range_check'], 2);
    });

    test('ValidationReviewRequest and Resolution serialization', () {
      const resolution = ValidationIssueResolution(
        issueId: 'iss_001',
        status: 'resolved',
        resolution: 'corrected_value',
        correctedValue: '2.4',
        notes: 'Fixed decimal typo in stripping ratio',
      );

      const reviewReq = ValidationReviewRequest(
        decision: 'approved',
        comments: 'All production variances resolved by chief mine surveyor.',
        issueResolutions: [resolution],
      );

      final json = reviewReq.toJson();
      expect(json['decision'], 'approved');
      expect(json['comments'], contains('chief mine surveyor'));
      final resList = json['issueResolutions'] as List<dynamic>;
      expect(resList.length, 1);
      expect((resList.first as Map<String, dynamic>)['correctedValue'], '2.4');
    });

    test('ValidationIssueModel and ValidationSummaryModel safely handle Map/Object documentId without TypeError', () {
      final jsonIssue = {
        'id': 'iss_002',
        'documentId': {
          '_id': '1788807291803-376382343',
          'filename': 'Monthly_Production.pdf',
        },
        'recordId': {'_id': 'rec_001'},
        'type': 'math_discrepancy',
        'severity': 'warning',
        'field': {'name': 'Coal Dispatch'},
        'message': 'Volume mismatch',
        'status': 'open',
      };

      final issue = ValidationIssueModel.fromJson(jsonIssue);
      expect(issue.id, 'iss_002');
      expect(issue.documentId, '1788807291803-376382343');
      expect(issue.recordId, 'rec_001');
      expect(issue.field, 'Coal Dispatch');

      final jsonSummary = {
        'documentId': {
          '_id': '1788807291803-376382343',
          'filename': 'Monthly_Production.pdf',
          'status': 'completed',
        },
        'documentName': null,
        'qualityScore': '95',
        'avgConfidence': '0.98',
        'totalIssues': '1',
        'openIssues': '1',
        'resolvedIssues': '0',
        'bySeverity': {'warning': '1'},
        'issues': [jsonIssue],
      };

      final summary = ValidationSummaryModel.fromJson(jsonSummary);
      expect(summary.documentId, '1788807291803-376382343');
      expect(summary.documentName, 'Monthly_Production.pdf');
      expect(summary.documentStatus, 'completed');
      expect(summary.qualityScore, 95);
      expect(summary.avgConfidence, 0.98);
      expect(summary.totalIssues, 1);
      expect(summary.issues.length, 1);
      expect(summary.issues.first.documentId, '1788807291803-376382343');
    });
  });
}
