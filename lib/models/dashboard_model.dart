/// Models for Dashboard Analytics module (Module 04).
/// Conforms strictly to OpenAPI 3.0.3 specification & API_DOCUMENTATION.md.
library;

class DashboardOverviewModel {
  final DashboardStatsModel stats;
  final List<DashboardRecentDocumentModel> recentDocuments;
  final List<DashboardActivityModel> recentActivity;
  final List<DashboardAlertModel> alerts;

  const DashboardOverviewModel({
    required this.stats,
    this.recentDocuments = const [],
    this.recentActivity = const [],
    this.alerts = const [],
  });

  factory DashboardOverviewModel.fromJson(Map<String, dynamic> json) {
    return DashboardOverviewModel(
      stats: json['stats'] != null
          ? DashboardStatsModel.fromJson(json['stats'] as Map<String, dynamic>)
          : const DashboardStatsModel(),
      recentDocuments: (json['recentDocuments'] as List<dynamic>?)
              ?.map((e) => DashboardRecentDocumentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      recentActivity: (json['recentActivity'] as List<dynamic>?)
              ?.map((e) => DashboardActivityModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      alerts: (json['alerts'] as List<dynamic>?)
              ?.map((e) => DashboardAlertModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'stats': stats.toJson(),
        'recentDocuments': recentDocuments.map((e) => e.toJson()).toList(),
        'recentActivity': recentActivity.map((e) => e.toJson()).toList(),
        'alerts': alerts.map((e) => e.toJson()).toList(),
      };
}

class DashboardStatsModel {
  final int totalDocuments;
  final int validatedDocuments;
  final int pendingReviews;
  final double avgQualityScore;

  const DashboardStatsModel({
    this.totalDocuments = 0,
    this.validatedDocuments = 0,
    this.pendingReviews = 0,
    this.avgQualityScore = 0.0,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalDocuments: (json['totalDocuments'] as num?)?.toInt() ?? 0,
      validatedDocuments: (json['validatedDocuments'] as num?)?.toInt() ?? 0,
      pendingReviews: (json['pendingReviews'] as num?)?.toInt() ?? 0,
      avgQualityScore: (json['avgQualityScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalDocuments': totalDocuments,
        'validatedDocuments': validatedDocuments,
        'pendingReviews': pendingReviews,
        'avgQualityScore': avgQualityScore,
      };
}

class DashboardKpisModel {
  final int documentCount;
  final int processedCount;
  final int errorCount;
  final double extractionAccuracy;
  final double complianceRate;

  const DashboardKpisModel({
    this.documentCount = 0,
    this.processedCount = 0,
    this.errorCount = 0,
    this.extractionAccuracy = 0.0,
    this.complianceRate = 0.0,
  });

  factory DashboardKpisModel.fromJson(Map<String, dynamic> json) {
    return DashboardKpisModel(
      documentCount: (json['documentCount'] as num?)?.toInt() ?? 0,
      processedCount: (json['processedCount'] as num?)?.toInt() ?? 0,
      errorCount: (json['errorCount'] as num?)?.toInt() ?? 0,
      extractionAccuracy: (json['extractionAccuracy'] as num?)?.toDouble() ?? 0.0,
      complianceRate: (json['complianceRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'documentCount': documentCount,
        'processedCount': processedCount,
        'errorCount': errorCount,
        'extractionAccuracy': extractionAccuracy,
        'complianceRate': complianceRate,
      };
}

class DashboardActivityModel {
  final String id;
  final String action;
  final String resource;
  final String timestamp;
  final String user;

  const DashboardActivityModel({
    required this.id,
    required this.action,
    required this.resource,
    required this.timestamp,
    required this.user,
  });

  factory DashboardActivityModel.fromJson(Map<String, dynamic> json) {
    return DashboardActivityModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      resource: json['resource'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      user: json['user'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
        'resource': resource,
        'timestamp': timestamp,
        'user': user,
      };
}

class DashboardAlertModel {
  final String id;
  final String severity; // 'critical' | 'warning' | 'info'
  final String title;
  final String message;
  final String timestamp;

  const DashboardAlertModel({
    required this.id,
    required this.severity,
    required this.title,
    required this.message,
    required this.timestamp,
  });

  bool get isCritical => severity.toLowerCase() == 'critical';
  bool get isWarning => severity.toLowerCase() == 'warning';
  bool get isInfo => severity.toLowerCase() == 'info';

  factory DashboardAlertModel.fromJson(Map<String, dynamic> json) {
    return DashboardAlertModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      severity: json['severity'] as String? ?? 'info',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'severity': severity,
        'title': title,
        'message': message,
        'timestamp': timestamp,
      };
}

class DashboardRecentDocumentModel {
  final String id;
  final String originalName;
  final String fileType;
  final String status;
  final String? uploadedAt;

  const DashboardRecentDocumentModel({
    required this.id,
    required this.originalName,
    required this.fileType,
    required this.status,
    this.uploadedAt,
  });

  factory DashboardRecentDocumentModel.fromJson(Map<String, dynamic> json) {
    return DashboardRecentDocumentModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      originalName: json['originalName'] as String? ?? 'Untitled Document',
      fileType: json['fileType'] as String? ?? 'pdf',
      status: json['status'] as String? ?? 'pending',
      uploadedAt: json['uploadedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'originalName': originalName,
        'fileType': fileType,
        'status': status,
        if (uploadedAt != null) 'uploadedAt': uploadedAt,
      };
}
