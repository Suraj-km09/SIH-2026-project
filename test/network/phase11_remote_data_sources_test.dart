import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/models/settings_model.dart';
import 'package:mineintel_ai/network/api_client.dart';
import 'package:mineintel_ai/network/audit_remote_data_source.dart';
import 'package:mineintel_ai/network/notification_remote_data_source.dart';
import 'package:mineintel_ai/network/settings_remote_data_source.dart';

void main() {
  group('Phase 11 Remote Data Sources Tests', () {
    late ApiClient mockApiClient;

    setUp(() {
      mockApiClient = ApiClient();
      mockApiClient.dio.interceptors.clear();
      mockApiClient.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final path = options.path;

            // Notifications
            if (path.endsWith('/notifications') && options.method == 'GET') {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': [
                    {
                      '_id': 'notif-1',
                      'userId': 'u1',
                      'message': 'Report approved',
                      'category': 'approval',
                      'read': false,
                    }
                  ],
                  'unreadCount': 1,
                },
              ));
            } else if (path.contains('/notifications/') &&
                path.endsWith('/read') &&
                options.method == 'PUT') {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    '_id': 'notif-1',
                    'userId': 'u1',
                    'message': 'Report approved',
                    'category': 'approval',
                    'read': true,
                  }
                },
              ));
            } else if (path.endsWith('/notifications/read-all') &&
                options.method == 'PUT') {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {'success': true, 'message': 'All marked read'},
              ));
            }

            // Audit
            else if (path.endsWith('/audit') && options.method == 'GET') {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': [
                    {
                      '_id': 'aud-1',
                      'user': {'_id': 'u1', 'username': 'admin'},
                      'action': 'APPROVE_REPORT',
                      'resource': 'Report',
                      'status': 'SUCCESS',
                    }
                  ],
                  'meta': {
                    'total': 1,
                    'limit': 50,
                    'skip': 0,
                    'page': 1,
                    'pages': 1,
                  }
                },
              ));
            } else if (path.endsWith('/audit/stats') && options.method == 'GET') {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'totalEvents': 10,
                    'successful': 9,
                    'failed': 1,
                    'activeUsers': 3,
                  }
                },
              ));
            } else if (path.endsWith('/audit/export') && options.method == 'GET') {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: 'id,action\naud-1,APPROVE_REPORT',
              ));
            }

            // Settings
            else if (path.endsWith('/settings') && options.method == 'GET') {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'language': 'en',
                    'appearance': {'theme': 'dark'},
                    'notifications': {
                      'emailNotif': true,
                      'pushNotif': false,
                      'reportAlerts': true,
                    },
                    'timezone': 'Asia/Kolkata (IST)',
                  }
                },
              ));
            } else if (path.endsWith('/settings/language') &&
                options.method == 'PUT') {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {'language': 'hi'}
                },
              ));
            } else if (path.endsWith('/settings/appearance') &&
                options.method == 'PUT') {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {'theme': 'dark'}
                },
              ));
            } else if (path.endsWith('/settings/notifications') &&
                options.method == 'PUT') {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'emailNotif': false,
                    'pushNotif': true,
                    'reportAlerts': false,
                  }
                },
              ));
            }

            return handler.next(options);
          },
        ),
      );
    });

    test('NotificationRemoteDataSource fetches and updates notifications', () async {
      final ds = NotificationRemoteDataSource(apiClient: mockApiClient);

      final list = await ds.getNotifications();
      expect(list.notifications.length, 1);
      expect(list.unreadCount, 1);

      final marked = await ds.markAsRead('notif-1');
      expect(marked.read, isTrue);

      final allRead = await ds.markAllAsRead();
      expect(allRead, isTrue);
    });

    test('AuditRemoteDataSource fetches logs, stats, and export', () async {
      final ds = AuditRemoteDataSource(apiClient: mockApiClient);

      final logs = await ds.getAuditLogs();
      expect(logs.logs.length, 1);
      expect(logs.logs.first.action, 'APPROVE_REPORT');

      final stats = await ds.getStats();
      expect(stats.totalEvents, 10);
      expect(stats.successful, 9);

      final export = await ds.exportAudit(format: 'csv');
      expect(export.content, contains('APPROVE_REPORT'));
    });

    test('SettingsRemoteDataSource gets and updates settings suite', () async {
      final ds = SettingsRemoteDataSource(apiClient: mockApiClient);

      final settings = await ds.getSettings();
      expect(settings.language, 'en');
      expect(settings.appearance.isDark, true);

      final lang = await ds.updateLanguage('hi');
      expect(lang, 'hi');

      final appearance = await ds.updateAppearance('dark');
      expect(appearance.isDark, true);

      final updatedPrefs = await ds.updateNotifications(
        const NotificationPreferences(
          emailNotif: false,
          pushNotif: true,
          reportAlerts: false,
        ),
      );
      expect(updatedPrefs.emailNotif, false);
      expect(updatedPrefs.pushNotif, true);
    });
  });
}
