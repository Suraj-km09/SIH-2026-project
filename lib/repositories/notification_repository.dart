import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../network/notification_remote_data_source.dart';
import 'base_repository.dart';

/// Abstract contract for In-App Notification Center.
abstract class NotificationRepository {
  Future<NotificationListResponse> getNotifications({
    bool? unread,
    int? limit,
  });
  Future<NotificationModel> markAsRead(String id);
  Future<bool> markAllAsRead();
}

/// Concrete implementation delegating to live API or fallback Mock.
class NotificationRepositoryImpl extends BaseRepository
    implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;
  final NotificationRepository? mockRepository;

  NotificationRepositoryImpl({
    NotificationRemoteDataSource? remoteDataSource,
    this.mockRepository,
  }) : _remoteDataSource =
            remoteDataSource ?? NotificationRemoteDataSource();

  @override
  Future<NotificationListResponse> getNotifications({
    bool? unread,
    int? limit,
  }) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getNotifications(unread: unread, limit: limit);
    }
    return execute(() => _remoteDataSource.getNotifications(
          unread: unread,
          limit: limit,
        ));
  }

  @override
  Future<NotificationModel> markAsRead(String id) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.markAsRead(id);
    }
    return execute(() => _remoteDataSource.markAsRead(id));
  }

  @override
  Future<bool> markAllAsRead() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.markAllAsRead();
    }
    return execute(() => _remoteDataSource.markAllAsRead());
  }
}

/// High-fidelity in-memory Mock implementation for offline operation.
class MockNotificationRepository implements NotificationRepository {
  final List<NotificationModel> _mockNotifications = [
    const NotificationModel(
      id: 'notif-001',
      userId: '64e0a1b2c3d4e5f6a7b8c9d0',
      message:
          'Your statutory report "Quarterly Coal Production Compliance Q2" has been approved by the reviewer.',
      type: 'success',
      category: 'approval',
      relatedId: 'rep-q2-coal-2026',
      read: false,
      createdAt: '2026-09-07T04:25:01.000Z',
    ),
    const NotificationModel(
      id: 'notif-002',
      userId: '64e0a1b2c3d4e5f6a7b8c9d0',
      message:
          'Critical validation error detected: Stripping Ratio exceeds upper threshold in Pit-4 monthly declaration.',
      type: 'error',
      category: 'alert',
      relatedId: 'doc-pit4-decl-08',
      read: false,
      createdAt: '2026-09-07T03:10:15.000Z',
    ),
    const NotificationModel(
      id: 'notif-003',
      userId: '64e0a1b2c3d4e5f6a7b8c9d0',
      message:
          'Document OCR & Extraction completed for "Bokaro OpenCast Survey 2026.pdf" with 98.4% confidence.',
      type: 'info',
      category: 'upload',
      relatedId: 'doc-bokaro-survey-01',
      read: false,
      createdAt: '2026-09-06T18:45:00.000Z',
    ),
    const NotificationModel(
      id: 'notif-004',
      userId: '64e0a1b2c3d4e5f6a7b8c9d0',
      message:
          'DGMS Safety Inspection directive published for Eastern Coalfields leases.',
      type: 'warning',
      category: 'system',
      relatedId: 'doc-dgms-dir-2026',
      read: true,
      createdAt: '2026-09-06T11:20:00.000Z',
    ),
    const NotificationModel(
      id: 'notif-005',
      userId: '64e0a1b2c3d4e5f6a7b8c9d0',
      message:
          'Human-in-the-Loop review requested for 3 low-confidence tabular records in Jharia Basin dispatch sheet.',
      type: 'info',
      category: 'review',
      relatedId: 'ext-jharia-dispatch-03',
      read: true,
      createdAt: '2026-09-05T09:15:30.000Z',
    ),
    const NotificationModel(
      id: 'notif-006',
      userId: '64e0a1b2c3d4e5f6a7b8c9d0',
      message:
          'Scheduled database re-indexing and vector cluster maintenance will take place on Sunday at 02:00 IST.',
      type: 'info',
      category: 'system',
      relatedId: null,
      read: true,
      createdAt: '2026-09-04T14:00:00.000Z',
    ),
  ];

  @override
  Future<NotificationListResponse> getNotifications({
    bool? unread,
    int? limit,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    var list = List<NotificationModel>.from(_mockNotifications);
    if (unread == true) {
      list = list.where((n) => !n.read).toList();
    }
    if (limit != null && limit > 0 && list.length > limit) {
      list = list.sublist(0, limit);
    }
    final unreadCount = _mockNotifications.where((n) => !n.read).length;
    return NotificationListResponse(
      notifications: list,
      unreadCount: unreadCount,
    );
  }

  @override
  Future<NotificationModel> markAsRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _mockNotifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final updated = _mockNotifications[index].copyWith(read: true);
      _mockNotifications[index] = updated;
      return updated;
    }
    return NotificationModel(
      id: id,
      userId: '',
      message: 'Notification marked as read',
      category: 'system',
      read: true,
    );
  }

  @override
  Future<bool> markAllAsRead() async {
    await Future.delayed(const Duration(milliseconds: 150));
    for (int i = 0; i < _mockNotifications.length; i++) {
      _mockNotifications[i] = _mockNotifications[i].copyWith(read: true);
    }
    return true;
  }
}

/// Global provider for NotificationRepository.
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    mockRepository: MockNotificationRepository(),
  );
});
