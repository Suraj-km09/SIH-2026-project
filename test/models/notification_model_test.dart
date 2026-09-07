import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/models/notification_model.dart';

void main() {
  group('Phase 11 Notification Models', () {
    test('NotificationModel parses from JSON properly', () {
      final json = {
        '_id': 'notif-101',
        'userId': 'usr-001',
        'message': 'Report approved by reviewer',
        'type': 'success',
        'category': 'approval',
        'relatedId': 'rep-001',
        'read': false,
        'createdAt': '2026-09-07T04:25:01.000Z',
      };

      final notif = NotificationModel.fromJson(json);
      expect(notif.id, 'notif-101');
      expect(notif.userId, 'usr-001');
      expect(notif.message, 'Report approved by reviewer');
      expect(notif.type, 'success');
      expect(notif.category, 'approval');
      expect(notif.relatedId, 'rep-001');
      expect(notif.read, false);
      expect(notif.isRead, false);
      expect(notif.createdAt, '2026-09-07T04:25:01.000Z');
    });

    test('NotificationModel fallback to referenceId if relatedId absent', () {
      final json = {
        '_id': 'notif-102',
        'userId': 'usr-001',
        'message': 'Upload completed',
        'referenceId': 'doc-999',
        'read': true,
      };

      final notif = NotificationModel.fromJson(json);
      expect(notif.relatedId, 'doc-999');
      expect(notif.isRead, true);
    });

    test('NotificationModel copyWith updates fields properly', () {
      const notif = NotificationModel(
        id: 'n1',
        userId: 'u1',
        message: 'Original message',
        category: 'alert',
        read: false,
      );

      final updated = notif.copyWith(read: true, message: 'Updated message');
      expect(updated.id, 'n1');
      expect(updated.read, true);
      expect(updated.message, 'Updated message');
      expect(updated.category, 'alert');
    });

    test('NotificationListResponse parses list and unread count', () {
      final json = {
        'success': true,
        'data': [
          {
            '_id': 'n1',
            'userId': 'u1',
            'message': 'Message 1',
            'category': 'system',
            'read': false,
          },
          {
            '_id': 'n2',
            'userId': 'u1',
            'message': 'Message 2',
            'category': 'system',
            'read': true,
          }
        ],
        'unreadCount': 1,
      };

      final res = NotificationListResponse.fromJson(json);
      expect(res.notifications.length, 2);
      expect(res.unreadCount, 1);
      expect(res.notifications[0].read, false);
      expect(res.notifications[1].read, true);
    });

    test('NotificationModel toJson preserves fields', () {
      const notif = NotificationModel(
        id: 'n1',
        userId: 'u1',
        message: 'Notice',
        type: 'info',
        category: 'system',
        relatedId: 'ref-1',
        read: true,
        createdAt: '2026-09-07T12:00:00.000Z',
      );

      final json = notif.toJson();
      expect(json['_id'], 'n1');
      expect(json['userId'], 'u1');
      expect(json['message'], 'Notice');
      expect(json['type'], 'info');
      expect(json['category'], 'system');
      expect(json['relatedId'], 'ref-1');
      expect(json['read'], true);
      expect(json['createdAt'], '2026-09-07T12:00:00.000Z');
    });
  });
}
