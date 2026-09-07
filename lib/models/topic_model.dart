import 'intelligence_model.dart';

/// Data models for Topic Modeling, Taxonomy Discovery, Emerging Topics,
/// and Cross-Period Evolution.
class TopicModel {
  final String id;
  final String name;
  final String description;
  final List<String> keywords;
  final double weight;
  final int documentCount;
  final int mentionCount;
  final double relevanceScore;

  const TopicModel({
    required this.id,
    required this.name,
    required this.description,
    required this.keywords,
    required this.weight,
    required this.documentCount,
    required this.mentionCount,
    required this.relevanceScore,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    final kw = (json['keywords'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    return TopicModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Topic',
      description: json['description'] as String? ?? '',
      keywords: kw,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.5,
      documentCount: (json['documentCount'] as num?)?.toInt() ?? 0,
      mentionCount: (json['mentionCount'] as num?)?.toInt() ?? 0,
      relevanceScore: (json['relevanceScore'] as num?)?.toDouble() ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'keywords': keywords,
        'weight': weight,
        'documentCount': documentCount,
        'mentionCount': mentionCount,
        'relevanceScore': relevanceScore,
      };
}

class TopicAnalysisResult {
  final String documentId;
  final int topicsFound;
  final List<TopicModel> topics;

  const TopicAnalysisResult({
    required this.documentId,
    required this.topicsFound,
    required this.topics,
  });

  factory TopicAnalysisResult.fromJson(Map<String, dynamic> json) {
    final list = json['topics'] as List<dynamic>? ?? [];
    return TopicAnalysisResult(
      documentId: json['documentId'] as String? ?? '',
      topicsFound: (json['topicsFound'] as num?)?.toInt() ?? list.length,
      topics: list
          .map((e) => TopicModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'topicsFound': topicsFound,
        'topics': topics.map((e) => e.toJson()).toList(),
      };
}

class TopicTrendPeriod {
  final String period;
  final int count;

  const TopicTrendPeriod({
    required this.period,
    required this.count,
  });

  factory TopicTrendPeriod.fromJson(Map<String, dynamic> json) {
    return TopicTrendPeriod(
      period: json['period'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'period': period,
        'count': count,
      };
}

class TopicTrend {
  final String id;
  final String name;
  final double weight;
  final List<TopicTrendPeriod> periods;

  const TopicTrend({
    required this.id,
    required this.name,
    required this.weight,
    required this.periods,
  });

  factory TopicTrend.fromJson(Map<String, dynamic> json) {
    final pList = (json['periods'] as List<dynamic>?)
            ?.map((e) => TopicTrendPeriod.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return TopicTrend(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Topic',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.5,
      periods: pList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'weight': weight,
        'periods': periods.map((e) => e.toJson()).toList(),
      };
}

class TopicCluster {
  final String clusterId;
  final String name;
  final double weight;
  final List<String> keywords;
  final int documentsCount;
  final List<RelatedTopicItem> relatedTopics;

  const TopicCluster({
    required this.clusterId,
    required this.name,
    required this.weight,
    required this.keywords,
    required this.documentsCount,
    required this.relatedTopics,
  });

  factory TopicCluster.fromJson(Map<String, dynamic> json) {
    final kwList = (json['keywords'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final relList = (json['relatedTopics'] as List<dynamic>?)
            ?.map((e) => RelatedTopicItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return TopicCluster(
      clusterId: json['clusterId'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Cluster',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.5,
      keywords: kwList,
      documentsCount: (json['documentsCount'] as num?)?.toInt() ?? 0,
      relatedTopics: relList,
    );
  }

  Map<String, dynamic> toJson() => {
        'clusterId': clusterId,
        'name': name,
        'weight': weight,
        'keywords': keywords,
        'documentsCount': documentsCount,
        'relatedTopics': relatedTopics.map((e) => e.toJson()).toList(),
      };
}

class TopicEntityItem {
  final String name;
  final String type;
  final int mentions;

  const TopicEntityItem({
    required this.name,
    required this.type,
    required this.mentions,
  });

  factory TopicEntityItem.fromJson(Map<String, dynamic> json) {
    return TopicEntityItem(
      name: json['name'] as String? ?? '',
      type: (json['type'] as String? ?? 'MINE').toUpperCase(),
      mentions: (json['mentions'] as num?)?.toInt() ??
          (json['count'] as num?)?.toInt() ??
          1,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'mentions': mentions,
      };
}

class TopicEntityAssociation {
  final String topicId;
  final String topicName;
  final int entitiesCount;
  final List<TopicEntityItem> entities;

  const TopicEntityAssociation({
    required this.topicId,
    required this.topicName,
    required this.entitiesCount,
    required this.entities,
  });

  factory TopicEntityAssociation.fromJson(Map<String, dynamic> json) {
    final list = json['entities'] as List<dynamic>? ?? [];
    return TopicEntityAssociation(
      topicId: json['topicId'] as String? ?? json['_id'] as String? ?? '',
      topicName: json['topicName'] as String? ?? 'Topic',
      entitiesCount: (json['entitiesCount'] as num?)?.toInt() ?? list.length,
      entities: list
          .map((e) => TopicEntityItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'topicId': topicId,
        'topicName': topicName,
        'entitiesCount': entitiesCount,
        'entities': entities.map((e) => e.toJson()).toList(),
      };
}

class EmergingTopic {
  final String topicId;
  final String name;
  final double weight;
  final double growthRate;
  final String latestPeriod;
  final String status; // ACCELERATING, STABLE, SURGING

  const EmergingTopic({
    required this.topicId,
    required this.name,
    required this.weight,
    required this.growthRate,
    required this.latestPeriod,
    required this.status,
  });

  factory EmergingTopic.fromJson(Map<String, dynamic> json) {
    return EmergingTopic(
      topicId: json['topicId'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Emerging Topic',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.5,
      growthRate: (json['growthRate'] as num?)?.toDouble() ?? 0.0,
      latestPeriod: json['latestPeriod'] as String? ?? 'Recent',
      status: json['status'] as String? ?? 'ACCELERATING',
    );
  }

  Map<String, dynamic> toJson() => {
        'topicId': topicId,
        'name': name,
        'weight': weight,
        'growthRate': growthRate,
        'latestPeriod': latestPeriod,
        'status': status,
      };
}

class TopicChange {
  final String topicId;
  final String name;
  final String fromPeriod;
  final String toPeriod;
  final int countChange;
  final double weightChange;
  final String direction; // EXPANDING, CONTRACTING, STABLE

  const TopicChange({
    required this.topicId,
    required this.name,
    required this.fromPeriod,
    required this.toPeriod,
    required this.countChange,
    required this.weightChange,
    required this.direction,
  });

  factory TopicChange.fromJson(Map<String, dynamic> json) {
    return TopicChange(
      topicId: json['topicId'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Topic Change',
      fromPeriod: json['fromPeriod'] as String? ?? '',
      toPeriod: json['toPeriod'] as String? ?? '',
      countChange: (json['countChange'] as num?)?.toInt() ?? 0,
      weightChange: (json['weightChange'] as num?)?.toDouble() ?? 0.0,
      direction: json['direction'] as String? ?? 'EXPANDING',
    );
  }

  Map<String, dynamic> toJson() => {
        'topicId': topicId,
        'name': name,
        'fromPeriod': fromPeriod,
        'toPeriod': toPeriod,
        'countChange': countChange,
        'weightChange': weightChange,
        'direction': direction,
      };
}
