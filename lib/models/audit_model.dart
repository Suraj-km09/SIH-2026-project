// Models for Module 19: Audit Trail & Provenance (/api/v1/audit/*).

/// User identity embedded within an audit log entry.
class AuditUser {
  final String id;
  final String username;
  final String? role;

  const AuditUser({
    required this.id,
    required this.username,
    this.role,
  });

  factory AuditUser.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return AuditUser(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        username: json['username'] as String? ?? 'system',
        role: json['role'] as String?,
      );
    } else if (json is String) {
      return AuditUser(id: json, username: json);
    }
    return const AuditUser(id: '', username: 'unknown');
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'username': username,
        if (role != null) 'role': role,
      };
}

/// A single immutable audit log record.
class AuditLogEntry {
  final String id;
  final AuditUser user;
  final String action;
  final String resource;
  final String? resourceId;
  final String status; // 'SUCCESS' | 'FAILED' | 'PROCESSING'
  final String? ipAddress;
  final Map<String, dynamic> details;
  final String timestamp;

  const AuditLogEntry({
    required this.id,
    required this.user,
    required this.action,
    required this.resource,
    this.resourceId,
    required this.status,
    this.ipAddress,
    this.details = const {},
    required this.timestamp,
  });

  bool get isSuccess => status.toUpperCase() == 'SUCCESS';
  bool get isFailed => status.toUpperCase() == 'FAILED';

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      user: AuditUser.fromJson(json['user'] ?? json['userId']),
      action: json['action'] as String? ?? 'UNKNOWN_ACTION',
      resource: json['resource'] as String? ?? 'System',
      resourceId: json['resourceId'] as String?,
      status: json['status'] as String? ?? 'SUCCESS',
      ipAddress: json['ipAddress'] as String?,
      details: json['details'] is Map<String, dynamic>
          ? json['details'] as Map<String, dynamic>
          : {},
      timestamp: json['timestamp'] as String? ??
          json['createdAt'] as String? ??
          DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'user': user.toJson(),
        'action': action,
        'resource': resource,
        'resourceId': resourceId,
        'status': status,
        'ipAddress': ipAddress,
        'details': details,
        'timestamp': timestamp,
      };
}

/// Statistics aggregated across system audit trail.
class AuditStats {
  final int totalEvents;
  final int successful;
  final int failed;
  final int activeUsers;

  const AuditStats({
    required this.totalEvents,
    required this.successful,
    required this.failed,
    required this.activeUsers,
  });

  factory AuditStats.fromJson(Map<String, dynamic> json) {
    return AuditStats(
      totalEvents: json['totalEvents'] as int? ?? 0,
      successful: json['successful'] as int? ?? 0,
      failed: json['failed'] as int? ?? 0,
      activeUsers: json['activeUsers'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalEvents': totalEvents,
        'successful': successful,
        'failed': failed,
        'activeUsers': activeUsers,
      };
}

/// Pagination metadata for audit queries.
class AuditMeta {
  final int total;
  final int limit;
  final int skip;
  final int page;
  final int pages;

  const AuditMeta({
    required this.total,
    required this.limit,
    required this.skip,
    required this.page,
    required this.pages,
  });

  factory AuditMeta.fromJson(Map<String, dynamic> json) {
    return AuditMeta(
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 100,
      skip: json['skip'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pages: json['pages'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'limit': limit,
        'skip': skip,
        'page': page,
        'pages': pages,
      };
}

/// Paginated audit response envelope.
class AuditLogsResponse {
  final List<AuditLogEntry> logs;
  final AuditMeta? meta;

  const AuditLogsResponse({
    required this.logs,
    this.meta,
  });

  factory AuditLogsResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] as List? ?? [];
    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map(AuditLogEntry.fromJson)
        .toList();

    AuditMeta? meta;
    if (json['meta'] is Map<String, dynamic>) {
      meta = AuditMeta.fromJson(json['meta'] as Map<String, dynamic>);
    }

    return AuditLogsResponse(
      logs: items,
      meta: meta,
    );
  }
}

/// Export response model.
class AuditExportResult {
  final String content;
  final String format; // 'csv' or 'json'
  final String filename;

  const AuditExportResult({
    required this.content,
    required this.format,
    required this.filename,
  });
}
