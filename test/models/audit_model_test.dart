import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/models/audit_model.dart';

void main() {
  group('Phase 11 Audit Models', () {
    test('AuditUser parses from object and string', () {
      final userFromObj = AuditUser.fromJson({
        '_id': 'usr-001',
        'username': 'admin',
        'role': 'admin',
      });
      expect(userFromObj.id, 'usr-001');
      expect(userFromObj.username, 'admin');
      expect(userFromObj.role, 'admin');

      final userFromString = AuditUser.fromJson('usr-plain');
      expect(userFromString.id, 'usr-plain');
      expect(userFromString.username, 'usr-plain');
    });

    test('AuditLogEntry parses from JSON properly', () {
      final json = {
        '_id': 'aud-001',
        'user': {
          '_id': 'usr-admin',
          'username': 'admin',
          'role': 'admin',
        },
        'action': 'APPROVE_REPORT',
        'resource': 'Report',
        'resourceId': 'rep-101',
        'status': 'SUCCESS',
        'ipAddress': '192.168.1.1',
        'details': {'note': 'Statutory verification completed'},
        'timestamp': '2026-09-07T04:25:00.000Z',
      };

      final entry = AuditLogEntry.fromJson(json);
      expect(entry.id, 'aud-001');
      expect(entry.user.username, 'admin');
      expect(entry.action, 'APPROVE_REPORT');
      expect(entry.resource, 'Report');
      expect(entry.resourceId, 'rep-101');
      expect(entry.status, 'SUCCESS');
      expect(entry.isSuccess, true);
      expect(entry.isFailed, false);
      expect(entry.ipAddress, '192.168.1.1');
      expect(entry.details['note'], 'Statutory verification completed');
      expect(entry.timestamp, '2026-09-07T04:25:00.000Z');
    });

    test('AuditStats parses event statistics', () {
      final json = {
        'totalEvents': 312,
        'successful': 308,
        'failed': 4,
        'activeUsers': 9,
      };

      final stats = AuditStats.fromJson(json);
      expect(stats.totalEvents, 312);
      expect(stats.successful, 308);
      expect(stats.failed, 4);
      expect(stats.activeUsers, 9);
    });

    test('AuditMeta and AuditLogsResponse parse pagination', () {
      final json = {
        'success': true,
        'data': [
          {
            '_id': 'aud-001',
            'user': {'_id': 'u1', 'username': 'user1'},
            'action': 'UPLOAD_DOCUMENT',
            'resource': 'Document',
            'status': 'SUCCESS',
          }
        ],
        'meta': {
          'total': 142,
          'limit': 50,
          'skip': 0,
          'page': 1,
          'pages': 3,
        }
      };

      final res = AuditLogsResponse.fromJson(json);
      expect(res.logs.length, 1);
      expect(res.meta?.total, 142);
      expect(res.meta?.limit, 50);
      expect(res.meta?.page, 1);
      expect(res.meta?.pages, 3);
    });

    test('AuditLogsResponse parses when list elements are dynamic maps and supports pagination fallback', () {
      final dynamicJson = <String, dynamic>{
        'success': true,
        'data': [
          <dynamic, dynamic>{
            '_id': 'aud-002',
            'user': <dynamic, dynamic>{'_id': 'u2', 'username': 'vishal'},
            'action': 'ADMIN_LOGIN',
            'resource': 'Auth',
            'status': 'SUCCESS',
            'details': <dynamic, dynamic>{'attempt': 1},
          }
        ],
        'pagination': <dynamic, dynamic>{
          'total': 428,
          'limit': 100,
          'skip': 0,
          'page': 1,
          'pages': 5,
        }
      };

      final res = AuditLogsResponse.fromJson(dynamicJson);
      expect(res.logs.length, 1);
      expect(res.logs.first.id, 'aud-002');
      expect(res.logs.first.user.username, 'vishal');
      expect(res.logs.first.details['attempt'], 1);
      expect(res.meta?.total, 428);
      expect(res.meta?.pages, 5);
    });

    test('AuditExportResult model holds export metadata', () {
      const result = AuditExportResult(
        content: 'id,action\n1,LOGIN',
        format: 'csv',
        filename: 'audit_logs_export.csv',
      );

      expect(result.format, 'csv');
      expect(result.filename, 'audit_logs_export.csv');
      expect(result.content, contains('LOGIN'));
    });
  });
}
