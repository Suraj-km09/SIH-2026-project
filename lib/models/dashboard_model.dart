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

  DashboardOverviewModel copyWith({
    DashboardStatsModel? stats,
    List<DashboardRecentDocumentModel>? recentDocuments,
    List<DashboardActivityModel>? recentActivity,
    List<DashboardAlertModel>? alerts,
  }) {
    return DashboardOverviewModel(
      stats: stats ?? this.stats,
      recentDocuments: recentDocuments ?? this.recentDocuments,
      recentActivity: recentActivity ?? this.recentActivity,
      alerts: alerts ?? this.alerts,
    );
  }

  factory DashboardOverviewModel.fromJson(Map<String, dynamic> json) {
    DashboardStatsModel stats;
    if (json['stats'] != null) {
      stats = DashboardStatsModel.fromJson(json['stats'] as Map<String, dynamic>);
    } else {
      stats = DashboardStatsModel.fromJson(json);
    }

    return DashboardOverviewModel(
      stats: stats,
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
    int total = (json['totalDocuments'] as num?)?.toInt() ?? 0;
    int validated = (json['validatedDocuments'] as num?)?.toInt() ?? 0;
    int pending = (json['pendingReviews'] as num?)?.toInt() ?? 0;
    double avgQuality = (json['avgQualityScore'] as num?)?.toDouble() ?? 0.0;

    // Support live Express backend nested payload
    if (json['documents'] is Map) {
      final docMap = json['documents'] as Map<String, dynamic>;
      final docTotal = (docMap['total'] as num?)?.toInt() ?? 0;
      if (docTotal > 0 || total == 0) total = docTotal;

      final docProcessed = (docMap['processed'] as num?)?.toInt() ?? 0;
      if (docProcessed > 0 || validated == 0) validated = docProcessed;

      final docPending = (docMap['pending'] as num?)?.toInt() ?? 0;
      if (docPending > 0 || pending == 0) pending = docPending;

      final docScore = (docMap['successRate'] as num?)?.toDouble() ?? 0.0;
      if (docScore > 0 && avgQuality == 0.0) avgQuality = docScore;
    }

    if (json['extraction'] is Map) {
      final extMap = json['extraction'] as Map<String, dynamic>;
      final extRecords = (extMap['totalRecords'] as num?)?.toInt() ?? 0;
      if (extRecords > 0 && total == 0) {
        total = extRecords;
      }
    }

    if (json['validation'] is Map) {
      final valMap = json['validation'] as Map<String, dynamic>;
      final openIssues = (valMap['openIssues'] as num?)?.toInt() ?? 0;
      if (openIssues > 0 && pending == 0) pending = openIssues;

      final valScoreStr = valMap['score']?.toString() ?? '';
      if (valScoreStr.isNotEmpty && avgQuality == 0.0) {
        final cleaned = valScoreStr.replaceAll('%', '').trim();
        final parsed = double.tryParse(cleaned);
        if (parsed != null) avgQuality = parsed;
      }
    }

    return DashboardStatsModel(
      totalDocuments: total,
      validatedDocuments: validated,
      pendingReviews: pending,
      avgQualityScore: avgQuality,
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
    int docCount = (json['documentCount'] as num?)?.toInt() ?? 0;
    int procCount = (json['processedCount'] as num?)?.toInt() ?? 0;
    int errCount = (json['errorCount'] as num?)?.toInt() ?? 0;
    double extAcc = (json['extractionAccuracy'] as num?)?.toDouble() ?? 0.0;
    double compRate = (json['complianceRate'] as num?)?.toDouble() ?? 0.0;

    // Support live Express backend KPI payload
    if (json['totalDocs'] is Map) {
      final val = (json['totalDocs']['value'] as num?)?.toInt();
      if (val != null && (val > 0 || docCount == 0)) docCount = val;
    }
    if (json['processedDocs'] is Map) {
      final val = (json['processedDocs']['value'] as num?)?.toInt();
      if (val != null && (val > 0 || procCount == 0)) procCount = val;
    }
    if (json['failedDocs'] is Map) {
      final val = (json['failedDocs']['value'] as num?)?.toInt();
      if (val != null && (val > 0 || errCount == 0)) errCount = val;
    }
    if (json['totalExtractedRecords'] is Map) {
      final val = (json['totalExtractedRecords']['value'] as num?)?.toInt();
      if (val != null && val > 0 && docCount == 0) {
        docCount = val;
      }
    }
    if (json['averageConfidenceScore'] is Map) {
      final val = (json['averageConfidenceScore']['value'] as num?)?.toDouble();
      if (val != null && val > 0 && extAcc == 0.0) {
        extAcc = val <= 1.0 ? val * 100 : val;
      }
      final pctStr = json['averageConfidenceScore']['percentage']?.toString();
      if (pctStr != null && extAcc == 0.0) {
        final parsed = double.tryParse(pctStr.replaceAll('%', '').trim());
        if (parsed != null) extAcc = parsed;
      }
    }
    if (compRate == 0.0 && extAcc > 0.0) {
      compRate = extAcc;
    }

    return DashboardKpisModel(
      documentCount: docCount,
      processedCount: procCount,
      errorCount: errCount,
      extractionAccuracy: extAcc,
      complianceRate: compRate,
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
  final String? type;
  final String? title;
  final String? description;
  final String? status;

  const DashboardActivityModel({
    required this.id,
    required this.action,
    required this.resource,
    required this.timestamp,
    required this.user,
    this.type,
    this.title,
    this.description,
    this.status,
  });

  factory DashboardActivityModel.fromJson(Map<String, dynamic> json) {
    String action = json['action'] as String? ?? json['type'] as String? ?? '';
    String resource = json['resource'] as String? ?? '';
    final title = json['title'] as String? ?? '';
    if (resource.isEmpty && title.contains(' on ')) {
      final parts = title.split(' on ');
      if (parts.length > 1) {
        resource = parts.last.trim();
        if (action.isEmpty) {
          action = parts.first.trim();
        }
      }
    }
    if (action.isEmpty && title.isNotEmpty) {
      action = title;
    }
    if (resource.isEmpty) {
      final statusStr = json['status'] as String? ?? '';
      if (statusStr.isNotEmpty) {
        resource = statusStr;
      } else {
        resource = 'System';
      }
    }

    String userStr = '';
    if (json['user'] is String) {
      userStr = json['user'] as String;
    } else if (json['user'] is Map) {
      final uMap = json['user'] as Map;
      userStr = uMap['username']?.toString() ?? uMap['name']?.toString() ?? '';
    } else if (json['userId'] != null) {
      userStr = json['userId'].toString();
    }

    return DashboardActivityModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      action: action,
      resource: resource,
      timestamp: json['timestamp'] as String? ??
          json['createdAt'] as String? ??
          '',
      user: userStr,
      type: json['type'] as String?,
      title: title.isNotEmpty ? title : null,
      description: json['description'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
        'resource': resource,
        'timestamp': timestamp,
        'user': user,
        if (type != null) 'type': type,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (status != null) 'status': status,
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
