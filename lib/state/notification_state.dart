import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

/// State representation for Notification Center.
class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? errorMessage;
  final String activeCategoryFilter;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.errorMessage,
    this.activeCategoryFilter = 'all',
  });

  List<NotificationModel> get filteredNotifications {
    if (activeCategoryFilter == 'unread') {
      return notifications.where((n) => !n.read).toList();
    } else if (activeCategoryFilter != 'all') {
      return notifications
          .where((n) =>
              n.category.toLowerCase() == activeCategoryFilter.toLowerCase())
          .toList();
    }
    return notifications;
  }

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? errorMessage,
    String? activeCategoryFilter,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      activeCategoryFilter:
          activeCategoryFilter ?? this.activeCategoryFilter,
    );
  }
}

/// Provider for notification state.
final notificationsNotifierProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
        NotificationNotifier.new);

/// Direct provider for active unread notification counter.
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsNotifierProvider).unreadCount;
});

/// Notifier driving user notifications, unread counts, and read status updates.
class NotificationNotifier extends Notifier<NotificationState> {
  late final NotificationRepository _repository;

  @override
  NotificationState build() {
    _repository = ref.watch(notificationRepositoryProvider);
    return const NotificationState();
  }

  /// Fetches in-app alerts and notifications.
  Future<void> loadNotifications({bool? unreadOnly}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response =
          await _repository.getNotifications(unread: unreadOnly);
      if (!ref.mounted) return;
      state = state.copyWith(
        notifications: response.notifications,
        unreadCount: response.unreadCount,
        isLoading: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Marks an individual notification as read.
  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      if (!ref.mounted) return;
      final updatedList = state.notifications.map((n) {
        if (n.id == id) {
          return n.copyWith(read: true);
        }
        return n;
      }).toList();

      final newUnread = updatedList.where((n) => !n.read).length;

      state = state.copyWith(
        notifications: updatedList,
        unreadCount: newUnread,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Batch marks all notifications as read.
  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      if (!ref.mounted) return;
      final updatedList = state.notifications
          .map((n) => n.copyWith(read: true))
          .toList();

      state = state.copyWith(
        notifications: updatedList,
        unreadCount: 0,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Changes the category filter.
  void setFilter(String filter) {
    state = state.copyWith(activeCategoryFilter: filter);
  }
}
