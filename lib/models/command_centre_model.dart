/// Data models for Command Centre Telemetry & Monitoring APIs (/api/v1/command-centre/*).
library;

class CommandCentreStatItem {
  final num value;
  final String display;
  final String label;

  const CommandCentreStatItem({
    required this.value,
    required this.display,
    required this.label,
  });

  factory CommandCentreStatItem.fromJson(Map<String, dynamic> json) {
    return CommandCentreStatItem(
      value: json['value'] as num? ?? 0,
      display: json['display']?.toString() ?? '0',
      label: json['label']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'display': display,
        'label': label,
      };
}

class CommandCentreSystemMetrics {
  final int totalDocuments;
  final int totalExtractedRecords;
  final int activeUsers;
  final int failedDocuments;
  final int uptimeSeconds;
  final int memoryUsageMb;

  const CommandCentreSystemMetrics({
    required this.totalDocuments,
    required this.totalExtractedRecords,
    required this.activeUsers,
    required this.failedDocuments,
    required this.uptimeSeconds,
    required this.memoryUsageMb,
  });

  factory CommandCentreSystemMetrics.fromJson(Map<String, dynamic> json) {
    return CommandCentreSystemMetrics(
      totalDocuments: json['totalDocuments'] as int? ?? 0,
      totalExtractedRecords: json['totalExtractedRecords'] as int? ?? 0,
      activeUsers: json['activeUsers'] as int? ?? 0,
      failedDocuments: json['failedDocuments'] as int? ?? 0,
      uptimeSeconds: json['uptimeSeconds'] as int? ?? 0,
      memoryUsageMb: json['memoryUsageMb'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalDocuments': totalDocuments,
        'totalExtractedRecords': totalExtractedRecords,
        'activeUsers': activeUsers,
        'failedDocuments': failedDocuments,
        'uptimeSeconds': uptimeSeconds,
        'memoryUsageMb': memoryUsageMb,
      };
}

class CommandCentreOverviewModel {
  final CommandCentreStatItem docsProcessed;
  final CommandCentreStatItem validationScore;
  final CommandCentreStatItem openIssues;
  final CommandCentreStatItem reportsGenerated;
  final CommandCentreSystemMetrics systemMetrics;
  final String timestamp;

  const CommandCentreOverviewModel({
    required this.docsProcessed,
    required this.validationScore,
    required this.openIssues,
    required this.reportsGenerated,
    required this.systemMetrics,
    required this.timestamp,
  });

  factory CommandCentreOverviewModel.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final metrics = json['systemMetrics'] as Map<String, dynamic>? ?? {};

    return CommandCentreOverviewModel(
      docsProcessed: CommandCentreStatItem.fromJson(
          stats['docsProcessed'] as Map<String, dynamic>? ?? {}),
      validationScore: CommandCentreStatItem.fromJson(
          stats['validationScore'] as Map<String, dynamic>? ?? {}),
      openIssues: CommandCentreStatItem.fromJson(
          stats['openIssues'] as Map<String, dynamic>? ?? {}),
      reportsGenerated: CommandCentreStatItem.fromJson(
          stats['reportsGenerated'] as Map<String, dynamic>? ?? {}),
      systemMetrics: CommandCentreSystemMetrics.fromJson(metrics),
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'stats': {
          'docsProcessed': docsProcessed.toJson(),
          'validationScore': validationScore.toJson(),
          'openIssues': openIssues.toJson(),
          'reportsGenerated': reportsGenerated.toJson(),
        },
        'systemMetrics': systemMetrics.toJson(),
        'timestamp': timestamp,
      };
}

class PipelineStageItem {
  final int count;
  final String status;
  final String description;

  const PipelineStageItem({
    required this.count,
    required this.status,
    required this.description,
  });

  factory PipelineStageItem.fromJson(Map<String, dynamic> json) {
    return PipelineStageItem(
      count: (json['count'] ?? json['totalIndexedChunks'] ?? 0) as int,
      status: json['status']?.toString() ?? 'normal',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'count': count,
        'status': status,
        'description': description,
      };
}

class CommandCentreHealthSummary {
  final int totalInPipeline;
  final int failedExtractions;
  final num pipelineSuccessRate;
  final int activeWorkers;

  const CommandCentreHealthSummary({
    required this.totalInPipeline,
    required this.failedExtractions,
    required this.pipelineSuccessRate,
    required this.activeWorkers,
  });

  factory CommandCentreHealthSummary.fromJson(Map<String, dynamic> json) {
    return CommandCentreHealthSummary(
      totalInPipeline: json['totalInPipeline'] as int? ?? 0,
      failedExtractions: json['failedExtractions'] as int? ?? 0,
      pipelineSuccessRate: json['pipelineSuccessRate'] as num? ?? 0,
      activeWorkers: json['activeWorkers'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalInPipeline': totalInPipeline,
        'failedExtractions': failedExtractions,
        'pipelineSuccessRate': pipelineSuccessRate,
        'activeWorkers': activeWorkers,
      };
}

class CommandCentrePipelineModel {
  final PipelineStageItem upload;
  final PipelineStageItem extraction;
  final PipelineStageItem validation;
  final PipelineStageItem indexing;
  final PipelineStageItem completed;
  final CommandCentreHealthSummary healthSummary;
  final String timestamp;

  const CommandCentrePipelineModel({
    required this.upload,
    required this.extraction,
    required this.validation,
    required this.indexing,
    required this.completed,
    required this.healthSummary,
    required this.timestamp,
  });

  factory CommandCentrePipelineModel.fromJson(Map<String, dynamic> json) {
    final stages = json['pipelineStages'] as Map<String, dynamic>? ?? {};
    final health = json['healthSummary'] as Map<String, dynamic>? ?? {};

    return CommandCentrePipelineModel(
      upload: PipelineStageItem.fromJson(
          stages['upload'] as Map<String, dynamic>? ?? {}),
      extraction: PipelineStageItem.fromJson(
          stages['extraction'] as Map<String, dynamic>? ?? {}),
      validation: PipelineStageItem.fromJson(
          stages['validation'] as Map<String, dynamic>? ?? {}),
      indexing: PipelineStageItem.fromJson(
          stages['indexing'] as Map<String, dynamic>? ?? {}),
      completed: PipelineStageItem.fromJson(
          stages['completed'] as Map<String, dynamic>? ?? {}),
      healthSummary: CommandCentreHealthSummary.fromJson(health),
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'pipelineStages': {
          'upload': upload.toJson(),
          'extraction': extraction.toJson(),
          'validation': validation.toJson(),
          'indexing': indexing.toJson(),
          'completed': completed.toJson(),
        },
        'healthSummary': healthSummary.toJson(),
        'timestamp': timestamp,
      };
}

class MicroserviceItem {
  final String name;
  final String status;
  final int? latencyMs;
  final String? model;
  final int? totalIndexedChunks;
  final List<String> supportedAgents;

  const MicroserviceItem({
    required this.name,
    required this.status,
    this.latencyMs,
    this.model,
    this.totalIndexedChunks,
    this.supportedAgents = const [],
  });

  factory MicroserviceItem.fromJson(Map<String, dynamic> json) {
    return MicroserviceItem(
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'unknown',
      latencyMs: json['latencyMs'] as int?,
      model: json['model']?.toString(),
      totalIndexedChunks: json['totalIndexedChunks'] as int?,
      supportedAgents: (json['supportedAgents'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'status': status,
        if (latencyMs != null) 'latencyMs': latencyMs,
        if (model != null) 'model': model,
        if (totalIndexedChunks != null)
          'totalIndexedChunks': totalIndexedChunks,
        if (supportedAgents.isNotEmpty) 'supportedAgents': supportedAgents,
      };
}

class CommandCentreStatusModel {
  final String overallStatus;
  final MicroserviceItem database;
  final MicroserviceItem ragEngine;
  final MicroserviceItem llmEngine;
  final MicroserviceItem agentOrchestrator;
  final String nodeVersion;
  final String platform;
  final int uptimeSeconds;
  final String timestamp;

  const CommandCentreStatusModel({
    required this.overallStatus,
    required this.database,
    required this.ragEngine,
    required this.llmEngine,
    required this.agentOrchestrator,
    required this.nodeVersion,
    required this.platform,
    required this.uptimeSeconds,
    required this.timestamp,
  });

  factory CommandCentreStatusModel.fromJson(Map<String, dynamic> json) {
    final services = json['services'] as Map<String, dynamic>? ?? {};
    final runtime = json['runtime'] as Map<String, dynamic>? ?? {};

    return CommandCentreStatusModel(
      overallStatus: json['overallStatus']?.toString() ?? 'OPERATIONAL',
      database: MicroserviceItem.fromJson(
          services['database'] as Map<String, dynamic>? ?? {}),
      ragEngine: MicroserviceItem.fromJson(
          services['ragEngine'] as Map<String, dynamic>? ?? {}),
      llmEngine: MicroserviceItem.fromJson(
          services['llmEngine'] as Map<String, dynamic>? ?? {}),
      agentOrchestrator: MicroserviceItem.fromJson(
          services['agentOrchestrator'] as Map<String, dynamic>? ?? {}),
      nodeVersion: runtime['nodeVersion']?.toString() ?? 'v20',
      platform: runtime['platform']?.toString() ?? 'linux',
      uptimeSeconds: runtime['uptimeSeconds'] as int? ?? 0,
      timestamp: runtime['timestamp']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'overallStatus': overallStatus,
        'services': {
          'database': database.toJson(),
          'ragEngine': ragEngine.toJson(),
          'llmEngine': llmEngine.toJson(),
          'agentOrchestrator': agentOrchestrator.toJson(),
        },
        'runtime': {
          'nodeVersion': nodeVersion,
          'platform': platform,
          'uptimeSeconds': uptimeSeconds,
          'timestamp': timestamp,
        },
      };
}

class AttentionItemModel {
  final String id;
  final String category;
  final String priority;
  final String title;
  final String description;
  final String actionRequired;
  final String resourceId;
  final String timestamp;

  const AttentionItemModel({
    required this.id,
    required this.category,
    required this.priority,
    required this.title,
    required this.description,
    required this.actionRequired,
    required this.resourceId,
    required this.timestamp,
  });

  factory AttentionItemModel.fromJson(Map<String, dynamic> json) {
    return AttentionItemModel(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? 'GENERAL',
      priority: json['priority']?.toString() ?? 'medium',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      actionRequired: json['actionRequired']?.toString() ?? '',
      resourceId: json['resourceId']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'priority': priority,
        'title': title,
        'description': description,
        'actionRequired': actionRequired,
        'resourceId': resourceId,
        'timestamp': timestamp,
      };
}

class CommandCentreAttentionModel {
  final int totalItems;
  final int highPriorityCount;
  final int mediumPriorityCount;
  final List<AttentionItemModel> items;

  const CommandCentreAttentionModel({
    required this.totalItems,
    required this.highPriorityCount,
    required this.mediumPriorityCount,
    required this.items,
  });

  factory CommandCentreAttentionModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['items'] as List<dynamic>? ?? [];
    return CommandCentreAttentionModel(
      totalItems: json['totalItems'] as int? ?? 0,
      highPriorityCount: json['highPriorityCount'] as int? ?? 0,
      mediumPriorityCount: json['mediumPriorityCount'] as int? ?? 0,
      items: rawList
          .whereType<Map>()
          .map((e) => AttentionItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalItems': totalItems,
        'highPriorityCount': highPriorityCount,
        'mediumPriorityCount': mediumPriorityCount,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class CommandCentreActivityModel {
  final String id;
  final String source;
  final String action;
  final String actor;
  final String description;
  final Map<String, dynamic> details;
  final String timestamp;

  const CommandCentreActivityModel({
    required this.id,
    required this.source,
    required this.action,
    required this.actor,
    required this.description,
    this.details = const {},
    required this.timestamp,
  });

  factory CommandCentreActivityModel.fromJson(Map<String, dynamic> json) {
    return CommandCentreActivityModel(
      id: json['id']?.toString() ?? '',
      source: json['source']?.toString() ?? 'SYSTEM',
      action: json['action']?.toString() ?? 'EVENT',
      actor: json['actor']?.toString() ?? 'system',
      description: json['description']?.toString() ?? '',
      details: json['details'] is Map
          ? Map<String, dynamic>.from(json['details'] as Map)
          : {},
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'action': action,
        'actor': actor,
        'description': description,
        'details': details,
        'timestamp': timestamp,
      };
}
