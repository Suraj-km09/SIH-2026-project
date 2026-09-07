import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/repositories/notification_repository.dart';

void main() {
  group('Phase 11 NotificationRepository & MockNotificationRepository Tests', () {
    late MockNotificationRepository mockRepo;
    late NotificationRepositoryImpl implRepo;

    setUp(() {
      EnvConfig.useMockData = true;
      mockRepo = MockNotificationRepository();
      implRepo = NotificationRepositoryImpl(mockRepository: mockRepo);
    });

    test('getNotifications returns list with accurate unread count', () async {
      final response = await mockRepo.getNotifications();
      expect(response.notifications, isNotEmpty);
      expect(response.unreadCount, greaterThan(0));
      expect(
        response.unreadCount,
        response.notifications.where((n) => !n.read).length,
      );
    });

    test('getNotifications with unread=true filters to unread only', () async {
      final response = await mockRepo.getNotifications(unread: true);
      expect(response.notifications, isNotEmpty);
      expect(response.notifications.every((n) => !n.read), isTrue);
    });

    test('markAsRead marks an individual notification as read', () async {
      final initial = await mockRepo.getNotifications();
      final target = initial.notifications.firstWhere((n) => !n.read);

      final updated = await mockRepo.markAsRead(target.id);
      expect(updated.id, target.id);
      expect(updated.read, isTrue);

      final after = await mockRepo.getNotifications();
      final afterTarget =
          after.notifications.firstWhere((n) => n.id == target.id);
      expect(afterTarget.read, isTrue);
      expect(after.unreadCount, initial.unreadCount - 1);
    });

    test('markAllAsRead marks all notifications as read', () async {
      final initial = await mockRepo.getNotifications();
      expect(initial.unreadCount, greaterThan(0));

      final success = await mockRepo.markAllAsRead();
      expect(success, isTrue);

      final after = await mockRepo.getNotifications();
      expect(after.unreadCount, 0);
      expect(after.notifications.every((n) => n.read), isTrue);
    });

    test('NotificationRepositoryImpl delegates properly in mock mode', () async {
      final response = await implRepo.getNotifications();
      expect(response.notifications, isNotEmpty);
      expect(response.unreadCount, greaterThanOrEqualTo(0));

      final allRead = await implRepo.markAllAsRead();
      expect(allRead, isTrue);
    });
  });
}
