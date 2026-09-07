import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/repositories/notification_repository.dart';
import 'package:mineintel_ai/state/notification_state.dart';

void main() {
  group('Phase 11 Notification Riverpod State Tests', () {
    late ProviderContainer container;
    late MockNotificationRepository mockRepo;

    setUp(() {
      EnvConfig.useMockData = true;
      mockRepo = MockNotificationRepository();
      container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('NotificationNotifier loads notifications and initializes unread count', () async {
      final notifier = container.read(notificationsNotifierProvider.notifier);
      await notifier.loadNotifications();

      final state = container.read(notificationsNotifierProvider);
      expect(state.notifications, isNotEmpty);
      expect(state.unreadCount, greaterThan(0));

      final directUnread = container.read(unreadNotificationCountProvider);
      expect(directUnread, state.unreadCount);
    });

    test('NotificationNotifier marks individual item as read', () async {
      final notifier = container.read(notificationsNotifierProvider.notifier);
      await notifier.loadNotifications();

      final initial = container.read(notificationsNotifierProvider);
      final unreadItem = initial.notifications.firstWhere((n) => !n.read);

      await notifier.markAsRead(unreadItem.id);

      final updated = container.read(notificationsNotifierProvider);
      final itemAfter =
          updated.notifications.firstWhere((n) => n.id == unreadItem.id);
      expect(itemAfter.read, isTrue);
      expect(updated.unreadCount, initial.unreadCount - 1);
    });

    test('NotificationNotifier markAllAsRead sets all items as read', () async {
      final notifier = container.read(notificationsNotifierProvider.notifier);
      await notifier.loadNotifications();

      await notifier.markAllAsRead();

      final state = container.read(notificationsNotifierProvider);
      expect(state.unreadCount, 0);
      expect(state.notifications.every((n) => n.read), isTrue);
    });

    test('NotificationNotifier filter category subsets filteredNotifications', () async {
      final notifier = container.read(notificationsNotifierProvider.notifier);
      await notifier.loadNotifications();

      notifier.setFilter('approval');
      final approvalState = container.read(notificationsNotifierProvider);
      expect(
        approvalState.filteredNotifications
            .every((n) => n.category.toLowerCase() == 'approval'),
        isTrue,
      );

      notifier.setFilter('unread');
      final unreadState = container.read(notificationsNotifierProvider);
      expect(
        unreadState.filteredNotifications.every((n) => !n.read),
        isTrue,
      );
    });
  });
}
