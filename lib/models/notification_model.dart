/// In-App User Notification model matching backend Notification schema.
class NotificationModel {
  final String id;
  final String userId;
  final String message;
  final String? type;
  final String category; // report, review, approval, system, alert, upload
  final String? relatedId;
  final bool read;
  final String? createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.message,
    this.type,
    required this.category,
    this.relatedId,
    required this.read,
    this.createdAt,
  });

  bool get isRead => read;

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? message,
    String? type,
    String? category,
    String? relatedId,
    bool? read,
    String? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      type: type ?? this.type,
      category: category ?? this.category,
      relatedId: relatedId ?? this.relatedId,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String?,
      category: json['category'] as String? ?? 'system',
      relatedId: json['relatedId'] as String? ?? json['referenceId'] as String?,
      read: json['read'] as bool? ?? false,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'userId': userId,
        'message': message,
        'type': type,
        'category': category,
        'relatedId': relatedId,
        'read': read,
        'createdAt': createdAt,
      };
}

/// Response envelope for GET /notifications
class NotificationListResponse {
  final List<NotificationModel> notifications;
  final int unreadCount;

  const NotificationListResponse({
    required this.notifications,
    required this.unreadCount,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] as List? ?? [];
    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();

    final unread = json['unreadCount'] as int? ??
        items.where((n) => !n.read).length;

    return NotificationListResponse(
      notifications: items,
      unreadCount: unread,
    );
  }
}

