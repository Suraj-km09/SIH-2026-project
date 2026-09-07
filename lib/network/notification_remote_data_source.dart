import '../core/constants/api_endpoints.dart';
import '../models/notification_model.dart';
import 'api_client.dart';

/// Remote data source for Notification Center APIs (/api/v1/notifications/*).
class NotificationRemoteDataSource {
  final ApiClient _apiClient;

  NotificationRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// GET /notifications
  Future<NotificationListResponse> getNotifications({
    bool? unread,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{};
    if (unread != null) queryParams['unread'] = unread.toString();
    if (limit != null) queryParams['limit'] = limit;

    final response = await _apiClient.dio.get(
      ApiEndpoints.notifications,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return NotificationListResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// PUT /notifications/:id/read
  Future<NotificationModel> markAsRead(String id) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.notificationMarkRead(id),
    );
    final rawData = response.data['data'] ?? response.data;
    return NotificationModel.fromJson(rawData as Map<String, dynamic>);
  }

  /// PUT /notifications/read-all
  Future<bool> markAllAsRead() async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.notificationsReadAll,
    );
    return response.data['success'] as bool? ?? true;
  }
}
