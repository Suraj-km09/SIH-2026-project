import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/models/dashboard_model.dart';

void main() {
  group('Dashboard Models JSON Serialization Tests', () {
    test('DashboardOverviewModel parses from valid API response JSON', () {
      final json = {
        'stats': {
          'totalDocuments': 12,
          'validatedDocuments': 10,
          'pendingReviews': 2,
          'avgQualityScore': 94.5,
        },
        'recentDocuments': [
          {
            '_id': 'doc_123',
            'originalName': 'ECL_Production_Report.pdf',
            'fileType': 'pdf',
            'status': 'completed',
            'uploadedAt': '2026-09-06T18:00:00.000Z',
          }
        ],
        'recentActivity': [
          {
            'id': 'act_456',
            'action': 'UPLOAD_DOCUMENT',
            'resource': 'Document',
            'timestamp': '2026-09-07T03:30:00.000Z',
            'user': 'vishal',
          }
        ],
        'alerts': [
          {
            'id': 'alt_789',
            'severity': 'critical',
            'title': 'Production Target Deficit',
            'message': 'Subsidiary ECL reported -14.2% variance.',
            'timestamp': '2026-09-07T01:00:00.000Z',
          }
        ],
      };

      final model = DashboardOverviewModel.fromJson(json);

      expect(model.stats.totalDocuments, 12);
      expect(model.stats.validatedDocuments, 10);
      expect(model.stats.pendingReviews, 2);
      expect(model.stats.avgQualityScore, 94.5);

      expect(model.recentDocuments.length, 1);
      expect(model.recentDocuments.first.id, 'doc_123');
      expect(model.recentDocuments.first.originalName, 'ECL_Production_Report.pdf');
      expect(model.recentDocuments.first.status, 'completed');

      expect(model.recentActivity.length, 1);
      expect(model.recentActivity.first.id, 'act_456');
      expect(model.recentActivity.first.action, 'UPLOAD_DOCUMENT');
      expect(model.recentActivity.first.user, 'vishal');

      expect(model.alerts.length, 1);
      expect(model.alerts.first.isCritical, isTrue);
      expect(model.alerts.first.title, 'Production Target Deficit');

      // Test serialization back to JSON
      final encoded = model.toJson();
      expect(encoded['stats']['totalDocuments'], 12);
      expect((encoded['recentDocuments'] as List).length, 1);
    });

    test('DashboardKpisModel parses correctly', () {
      final json = {
        'documentCount': 15,
        'processedCount': 14,
        'errorCount': 1,
        'extractionAccuracy': 97.2,
        'complianceRate': 93.8,
      };

      final kpis = DashboardKpisModel.fromJson(json);

      expect(kpis.documentCount, 15);
      expect(kpis.processedCount, 14);
      expect(kpis.errorCount, 1);
      expect(kpis.extractionAccuracy, 97.2);
      expect(kpis.complianceRate, 93.8);

      final encoded = kpis.toJson();
      expect(encoded['documentCount'], 15);
      expect(encoded['complianceRate'], 93.8);
    });

    test('DashboardAlertModel severity helper flags correctly', () {
      const crit = DashboardAlertModel(
        id: '1',
        severity: 'critical',
        title: 'Crit',
        message: 'msg',
        timestamp: 'ts',
      );
      const warn = DashboardAlertModel(
        id: '2',
        severity: 'warning',
        title: 'Warn',
        message: 'msg',
        timestamp: 'ts',
      );
      const info = DashboardAlertModel(
        id: '3',
        severity: 'info',
        title: 'Info',
        message: 'msg',
        timestamp: 'ts',
      );

      expect(crit.isCritical, isTrue);
      expect(crit.isWarning, isFalse);

      expect(warn.isWarning, isTrue);
      expect(warn.isCritical, isFalse);

      expect(info.isInfo, isTrue);
    });
  });
}
