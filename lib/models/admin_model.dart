/// Models for Admin Management & System Health (Module 03).
/// Conforms to OpenAPI 3.0.3 specification and API_DOCUMENTATION.md.
library;

/// Platform overview statistics returned by GET /api/v1/admin/stats.
class AdminStatsModel {
  final int totalUsers;
  final int totalDocuments;
  final int indexedDocuments;
  final int reportsGenerated;
  final int totalValidations;
  final int openValidations;

  const AdminStatsModel({
    this.totalUsers = 0,
    this.totalDocuments = 0,
    this.indexedDocuments = 0,
    this.reportsGenerated = 0,
    this.totalValidations = 0,
    this.openValidations = 0,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminStatsModel(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      totalDocuments: (json['totalDocuments'] as num?)?.toInt() ?? 0,
      indexedDocuments: (json['indexedDocuments'] as num?)?.toInt() ?? 0,
      reportsGenerated: (json['reportsGenerated'] as num?)?.toInt() ?? 0,
      totalValidations: (json['totalValidations'] as num?)?.toInt() ?? 0,
      openValidations: (json['openValidations'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalUsers': totalUsers,
        'totalDocuments': totalDocuments,
        'indexedDocuments': indexedDocuments,
        'reportsGenerated': reportsGenerated,
        'totalValidations': totalValidations,
        'openValidations': openValidations,
      };
}

/// Detailed subsystem health returned by GET /api/v1/admin/system-health.
class SystemHealthModel {
  final String backend;
  final String mongoDB;
  final String aiProvider;
  final String vectorDB;
  final String? timestamp;
  final String? version;
  final int? uptime;

  const SystemHealthModel({
    this.backend = 'Online',
    this.mongoDB = 'Connected',
    this.aiProvider = 'Online',
    this.vectorDB = 'Online',
    this.timestamp,
    this.version = 'v1',
    this.uptime,
  });

  bool get isBackendOnline => backend.toLowerCase() == 'online' || backend.toLowerCase() == 'healthy';
  bool get isMongoConnected => mongoDB.toLowerCase() == 'connected' || mongoDB.toLowerCase() == 'online';
  bool get isAiOnline => aiProvider.toLowerCase() == 'online' || aiProvider.toLowerCase() == 'ready';
  bool get isVectorDbOnline => vectorDB.toLowerCase() == 'online' || vectorDB.toLowerCase() == 'ready';

  bool get isAllHealthy => isBackendOnline && isMongoConnected && isAiOnline;

  factory SystemHealthModel.fromJson(Map<String, dynamic> json) {
    return SystemHealthModel(
      backend: json['backend'] as String? ?? json['server'] as String? ?? 'Online',
      mongoDB: json['mongoDB'] as String? ?? json['database'] as String? ?? 'Connected',
      aiProvider: json['aiProvider'] as String? ?? 'Online',
      vectorDB: json['vectorDB'] as String? ?? 'Online',
      timestamp: json['timestamp'] as String?,
      version: json['version'] as String? ?? 'v1',
      uptime: (json['uptime'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'backend': backend,
        'mongoDB': mongoDB,
        'aiProvider': aiProvider,
        'vectorDB': vectorDB,
        if (timestamp != null) 'timestamp': timestamp,
        if (version != null) 'version': version,
        if (uptime != null) 'uptime': uptime,
      };
}
