/// Data models for Document Intelligence, Cross-Document Reasoning,
/// Named Entities, Semantic Clusters, and Parameter Diffs.
class IntelligenceOverview {
  final int totalEntities;
  final int totalTopics;
  final int similarityClusters;
  final int recentChanges;

  const IntelligenceOverview({
    required this.totalEntities,
    required this.totalTopics,
    required this.similarityClusters,
    required this.recentChanges,
  });

  factory IntelligenceOverview.fromJson(Map<String, dynamic> json) {
    final entities = (json['totalEntitiesFound'] as num?)?.toInt() ??
        (json['totalEntities'] as num?)?.toInt() ??
        0;
    final topics = (json['totalTopicsDiscovered'] as num?)?.toInt() ??
        (json['totalTopics'] as num?)?.toInt() ??
        0;
    final similarities =
        (json['crossDocumentSimilaritiesComputed'] as num?)?.toInt() ??
            (json['similarityClusters'] as num?)?.toInt() ??
            0;
    final analyzed = (json['totalDocumentsAnalyzed'] as num?)?.toInt() ??
        (json['recentChanges'] as num?)?.toInt() ??
        0;
    final changes = (json['recentChanges'] as num?)?.toInt() ?? analyzed;

    return IntelligenceOverview(
      totalEntities: entities,
      totalTopics: topics,
      similarityClusters: similarities,
      recentChanges: changes,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalEntities': totalEntities,
        'totalTopics': totalTopics,
        'similarityClusters': similarityClusters,
        'recentChanges': recentChanges,
      };
}

class IntelligenceAnalysisResult {
  final String documentId;
  final String documentName;
  final int entitiesExtracted;
  final int topicsExtracted;
  final int similarDocumentsFound;

  const IntelligenceAnalysisResult({
    required this.documentId,
    required this.documentName,
    required this.entitiesExtracted,
    required this.topicsExtracted,
    required this.similarDocumentsFound,
  });

  factory IntelligenceAnalysisResult.fromJson(Map<String, dynamic> json) {
    return IntelligenceAnalysisResult(
      documentId: json['documentId'] as String? ?? '',
      documentName: json['documentName'] as String? ?? 'Document',
      entitiesExtracted: (json['entitiesExtracted'] as num?)?.toInt() ?? 0,
      topicsExtracted: (json['topicsExtracted'] as num?)?.toInt() ?? 0,
      similarDocumentsFound:
          (json['similarDocumentsFound'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'documentName': documentName,
        'entitiesExtracted': entitiesExtracted,
        'topicsExtracted': topicsExtracted,
        'similarDocumentsFound': similarDocumentsFound,
      };
}

class IntelligenceEntity {
  final String name;
  final String type; // LOCATION, ORGANIZATION, MINE, EQUIPMENT, FIGURE, SUBSIDIARY
  final int count;
  final List<String> documents;

  const IntelligenceEntity({
    required this.name,
    required this.type,
    required this.count,
    required this.documents,
  });

  factory IntelligenceEntity.fromJson(Map<String, dynamic> json) {
    final docsRaw = json['documents'];
    List<String> docsList = [];
    if (docsRaw is List) {
      docsList = docsRaw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (docsRaw is String && docsRaw.trim().isNotEmpty) {
      docsList = docsRaw.trim().split(RegExp(r'\s+'));
    }
    return IntelligenceEntity(
      name: json['name'] as String? ?? '',
      type: (json['type'] as String? ?? 'MINE').toUpperCase(),
      count: (json['mentions'] as num?)?.toInt() ??
          (json['count'] as num?)?.toInt() ??
          1,
      documents: docsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'count': count,
        'documents': documents,
      };
}

class DocumentEntityItem {
  final String name;
  final String type;
  final int count;

  const DocumentEntityItem({
    required this.name,
    required this.type,
    this.count = 1,
  });

  factory DocumentEntityItem.fromJson(Map<String, dynamic> json) {
    return DocumentEntityItem(
      name: json['name'] as String? ?? '',
      type: (json['type'] as String? ?? 'MINE').toUpperCase(),
      count: (json['mentions'] as num?)?.toInt() ??
          (json['count'] as num?)?.toInt() ??
          1,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'count': count,
      };
}

class DocumentEntitiesResponse {
  final String documentName;
  final List<DocumentEntityItem> entities;

  const DocumentEntitiesResponse({
    required this.documentName,
    required this.entities,
  });

  factory DocumentEntitiesResponse.fromJson(Map<String, dynamic> json) {
    final list = json['entities'] as List<dynamic>? ?? [];
    return DocumentEntitiesResponse(
      documentName: json['documentName'] as String? ?? '',
      entities: list
          .map((e) => DocumentEntityItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RelatedTopicItem {
  final String name;
  final double strength;

  const RelatedTopicItem({
    required this.name,
    required this.strength,
  });

  factory RelatedTopicItem.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return RelatedTopicItem(
        name: json['name'] as String? ?? '',
        strength: (json['strength'] as num?)?.toDouble() ?? 0.0,
      );
    } else if (json is String) {
      final nameMatch = RegExp(r'name=([^;]+)').firstMatch(json);
      final strMatch = RegExp(r'strength=([^}]+)').firstMatch(json);
      return RelatedTopicItem(
        name: nameMatch?.group(1)?.trim() ?? json,
        strength: double.tryParse(strMatch?.group(1)?.trim() ?? '0.5') ?? 0.5,
      );
    }
    return const RelatedTopicItem(name: '', strength: 0.0);
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'strength': strength,
      };
}

class IntelligenceCluster {
  final String clusterId;
  final String name;
  final double weight;
  final List<String> keywords;
  final int documentsCount;
  final List<RelatedTopicItem> relatedTopics;

  const IntelligenceCluster({
    required this.clusterId,
    required this.name,
    required this.weight,
    required this.keywords,
    required this.documentsCount,
    required this.relatedTopics,
  });

  factory IntelligenceCluster.fromJson(Map<String, dynamic> json) {
    final kwList = (json['keywords'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final relList = (json['relatedTopics'] as List<dynamic>?)
            ?.map((e) => RelatedTopicItem.fromJson(e))
            .toList() ??
        [];

    return IntelligenceCluster(
      clusterId: json['clusterId'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Mining Cluster',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.5,
      keywords: kwList,
      documentsCount: (json['documentCount'] as num?)?.toInt() ??
          (json['documentsCount'] as num?)?.toInt() ??
          0,
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

class SimilarDocumentItem {
  final String documentId;
  final String documentName;
  final double similarity;
  final List<String> commonEntities;

  const SimilarDocumentItem({
    required this.documentId,
    required this.documentName,
    required this.similarity,
    required this.commonEntities,
  });

  factory SimilarDocumentItem.fromJson(Map<String, dynamic> json) {
    final commonList = (json['commonEntities'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return SimilarDocumentItem(
      documentId: json['documentId'] as String? ?? json['_id'] as String? ?? '',
      documentName: json['documentName'] as String? ?? 'Document',
      similarity: (json['similarity'] as num?)?.toDouble() ??
          (json['score'] as num?)?.toDouble() ??
          0.0,
      commonEntities: commonList,
    );
  }

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'documentName': documentName,
        'similarity': similarity,
        'commonEntities': commonEntities,
      };
}

class IntelligenceSimilarityResult {
  final String targetDocument;
  final List<SimilarDocumentItem> similar;

  const IntelligenceSimilarityResult({
    required this.targetDocument,
    required this.similar,
  });

  factory IntelligenceSimilarityResult.fromJson(Map<String, dynamic> json) {
    if (json['nodes'] is List && json['links'] is List) {
      final nodesList =
          (json['nodes'] as List).whereType<Map<String, dynamic>>();
      final nodeNames = <String, String>{};
      for (final n in nodesList) {
        final id = n['id']?.toString() ?? '';
        final name = n['name']?.toString() ?? id;
        if (id.isNotEmpty) nodeNames[id] = name;
      }

      final linksList =
          (json['links'] as List).whereType<Map<String, dynamic>>();
      final items = <SimilarDocumentItem>[];
      for (final l in linksList) {
        final targetId = l['target']?.toString() ?? '';
        final sourceId = l['source']?.toString() ?? '';
        final score = (l['score'] as num?)?.toDouble() ?? 0.0;
        final docName = nodeNames[targetId] ??
            nodeNames[sourceId] ??
            'Document (${targetId.length > 8 ? targetId.substring(0, 8) : targetId})';
        items.add(SimilarDocumentItem(
          documentId: targetId.isNotEmpty ? targetId : sourceId,
          documentName: docName,
          similarity: score,
          commonEntities: const [
            'Mining Operations',
            'Production Report',
            'Verified Metrics'
          ],
        ));
      }

      final targetDoc =
          nodeNames.values.firstOrNull ?? 'Active Corpus Documents';

      return IntelligenceSimilarityResult(
        targetDocument: targetDoc,
        similar: items,
      );
    }

    final list = json['similar'] as List<dynamic>? ?? [];
    return IntelligenceSimilarityResult(
      targetDocument: json['targetDocument'] as String? ?? '',
      similar: list
          .map((e) => SimilarDocumentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'targetDocument': targetDocument,
        'similar': similar.map((e) => e.toJson()).toList(),
      };
}

class DocumentSimilarityResponse {
  final String documentName;
  final List<SimilarDocumentItem> similar;

  const DocumentSimilarityResponse({
    required this.documentName,
    required this.similar,
  });

  factory DocumentSimilarityResponse.fromJson(Map<String, dynamic> json) {
    final list = json['similar'] as List<dynamic>? ?? [];
    return DocumentSimilarityResponse(
      documentName: json['documentName'] as String? ?? '',
      similar: list
          .map((e) => SimilarDocumentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class IntelligenceChangeItem {
  final String parameter;
  final String? type; // 'added', 'removed', 'modified'
  final String? mineName;
  final String? subsidiary;
  final dynamic oldValue;
  final dynamic newValue;
  final double docAValue;
  final double docBValue;
  final double variancePct;
  final String? unit;

  const IntelligenceChangeItem({
    required this.parameter,
    this.type,
    this.mineName,
    this.subsidiary,
    this.oldValue,
    this.newValue,
    this.docAValue = 0.0,
    this.docBValue = 0.0,
    this.variancePct = 0.0,
    this.unit,
  });

  factory IntelligenceChangeItem.fromJson(Map<String, dynamic> json) {
    final double docA = (json['docAValue'] as num?)?.toDouble() ??
        double.tryParse(json['oldValue']?.toString() ?? '') ??
        0.0;
    final double docB = (json['docBValue'] as num?)?.toDouble() ??
        double.tryParse(json['newValue']?.toString() ?? '') ??
        0.0;
    double variance = (json['variancePct'] as num?)?.toDouble() ?? 0.0;
    if (variance == 0.0 && docA > 0 && docB > 0) {
      variance = ((docB - docA) / docA) * 100;
    }

    return IntelligenceChangeItem(
      parameter: json['parameter'] as String? ?? '',
      type: json['type'] as String?,
      mineName: json['mineName'] as String?,
      subsidiary: json['subsidiary'] as String?,
      oldValue: json['oldValue'],
      newValue: json['newValue'],
      docAValue: docA,
      docBValue: docB,
      variancePct: variance,
      unit: json['unit'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'parameter': parameter,
        if (type != null) 'type': type,
        if (mineName != null) 'mineName': mineName,
        if (subsidiary != null) 'subsidiary': subsidiary,
        if (oldValue != null) 'oldValue': oldValue,
        if (newValue != null) 'newValue': newValue,
        'docAValue': docAValue,
        'docBValue': docBValue,
        'variancePct': variancePct,
        if (unit != null) 'unit': unit,
      };
}

class IntelligenceChangesResponse {
  final int totalChanges;
  final int added;
  final int removed;
  final int modified;
  final String? docAName;
  final String? docBName;
  final List<IntelligenceChangeItem> changes;

  const IntelligenceChangesResponse({
    required this.totalChanges,
    required this.added,
    required this.removed,
    required this.modified,
    this.docAName,
    this.docBName,
    required this.changes,
  });

  factory IntelligenceChangesResponse.fromJson(Map<String, dynamic> json) {
    final list = json['changes'] as List<dynamic>? ?? [];
    final docA = json['documentA'] is Map
        ? json['documentA']['name'] as String?
        : null;
    final docB = json['documentB'] is Map
        ? json['documentB']['name'] as String?
        : null;

    return IntelligenceChangesResponse(
      totalChanges: (json['totalChanges'] as num?)?.toInt() ?? list.length,
      added: (json['added'] as num?)?.toInt() ?? 0,
      removed: (json['removed'] as num?)?.toInt() ?? 0,
      modified: (json['modified'] as num?)?.toInt() ?? 0,
      docAName: docA,
      docBName: docB,
      changes: list
          .map((e) =>
              IntelligenceChangeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalChanges': totalChanges,
        'added': added,
        'removed': removed,
        'modified': modified,
        'changes': changes.map((e) => e.toJson()).toList(),
      };
}

class LinkEvidenceResult {
  final String documentId;
  final bool linked;
  final int linksCount;

  const LinkEvidenceResult({
    required this.documentId,
    required this.linked,
    this.linksCount = 0,
  });

  factory LinkEvidenceResult.fromJson(Map<String, dynamic> json) {
    return LinkEvidenceResult(
      documentId: json['documentId'] as String? ?? '',
      linked: json['linked'] as bool? ?? false,
      linksCount: (json['linksCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'linked': linked,
        'linksCount': linksCount,
      };
}
