import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/models/document_model.dart';
import 'package:mineintel_ai/models/extracted_record_model.dart';
import 'package:mineintel_ai/models/notification_model.dart';
import 'package:mineintel_ai/models/processing_job_model.dart';
import 'package:mineintel_ai/models/report_model.dart';
import 'package:mineintel_ai/models/user_model.dart';
import 'package:mineintel_ai/models/validation_issue_model.dart';

void main() {
  group('Data Models JSON Serialization Tests', () {
    test('UserModel deserializes cleanly from MongoDB JSON', () {
      final json = {
        '_id': '64e0a1b2c3d4e5f6a7b8c9d0',
        'username': 'mining_engineer',
        'email': 'engineer@mineintel.ai',
        'role': 'user',
        'department': 'Mining Tech',
        'status': 'active',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, '64e0a1b2c3d4e5f6a7b8c9d0');
      expect(user.username, 'mining_engineer');
      expect(user.isAdmin, false);
      expect(user.isReviewer, false);
    });

    test('DocumentModel with GIS metadata deserializes correctly', () {
      final json = {
        '_id': 'doc_123',
        'originalName': 'July_Production_Report.pdf',
        'fileSize': 142058,
        'fileType': 'pdf',
        'category': 'Production Report',
        'classification': 'internal',
        'status': 'processing',
        'totalPages': 12,
        'gisMetadata': {
          'latitude': 23.7957,
          'longitude': 86.4304,
          'region': 'Jharia Coalfield',
        },
      };

      final doc = DocumentModel.fromJson(json);
      expect(doc.id, 'doc_123');
      expect(doc.originalName, 'July_Production_Report.pdf');
      expect(doc.isProcessing, true);
      expect(doc.gisMetadata?.region, 'Jharia Coalfield');
      expect(doc.gisMetadata?.latitude, 23.7957);
    });

    test('ProcessingJobModel deserializes pipeline steps', () {
      final json = {
        '_id': 'job_123',
        'documentId': 'doc_123',
        'status': 'processing',
        'progress': 65,
        'currentStep': 'Information Extraction',
        'steps': [
          {'name': 'File Ingestion', 'status': 'completed'},
          {'name': 'OCR Parsing', 'status': 'completed'},
          {'name': 'Information Extraction', 'status': 'processing'},
          {'name': 'Vector Indexing', 'status': 'pending'},
        ],
      };

      final job = ProcessingJobModel.fromJson(json);
      expect(job.progress, 65);
      expect(job.steps.length, 4);
      expect(job.isProcessing, true);
      expect(job.steps[0].isCompleted, true);
      expect(job.steps[0].status, 'completed');
    });

    test('ExtractedRecordModel deserializes edit history and confidence', () {
      final json = {
        '_id': 'rec_123',
        'documentId': 'doc_123',
        'pageNumber': 3,
        'parameter': 'Coal Production',
        'value': '142500',
        'unit': 'Metric Tonnes',
        'confidenceScore': 0.96,
        'status': 'pending',
        'editHistory': [
          {
            'field': 'value',
            'oldValue': '140000',
            'newValue': '142500',
            'editedAt': '2026-09-07T10:00:00.000Z',
          }
        ],
      };

      final record = ExtractedRecordModel.fromJson(json);
      expect(record.parameter, 'Coal Production');
      expect(record.confidenceScore, 0.96);
      expect(record.editHistory.length, 1);
      expect(record.editHistory.first.oldValue, '140000');
    });

    test('ValidationIssueModel and ValidationSummaryModel deserialize correctly', () {
      final json = {
        'documentId': 'doc_123',
        'qualityScore': 92,
        'avgConfidence': 0.94,
        'totalIssues': 2,
        'openIssues': 1,
        'resolvedIssues': 1,
        'bySeverity': {'warning': 1, 'info': 1},
        'issues': [
          {
            '_id': 'issue_1',
            'documentId': 'doc_123',
            'type': 'unit_mismatch',
            'severity': 'warning',
            'field': 'production',
            'message': 'Metric Tonnes expected instead of Cubic Meters',
            'status': 'open',
          }
        ],
      };

      final summary = ValidationSummaryModel.fromJson(json);
      expect(summary.qualityScore, 92);
      expect(summary.issues.length, 1);
      expect(summary.issues.first.isOpen, true);
    });

    test('ReportModel and NotificationModel deserialize correctly', () {
      final repJson = {
        '_id': 'rep_123',
        'title': 'Monthly Statutory Summary',
        'type': 'production_summary',
        'status': 'draft',
        'version': 1,
      };
      final report = ReportModel.fromJson(repJson);
      expect(report.isDraft, true);
      expect(report.version, 1);

      final notifJson = {
        '_id': 'notif_123',
        'userId': 'user_123',
        'message': 'Report approved',
        'category': 'approval',
        'read': false,
      };
      final notif = NotificationModel.fromJson(notifJson);
      expect(notif.read, false);
      expect(notif.category, 'approval');
    });
  });
}
