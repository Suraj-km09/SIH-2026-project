import 'package:flutter/foundation.dart';

/// Filter parameters for GET /api/v1/knowledge-base.
@immutable
class KnowledgeBaseFilter {
  final String? search;
  final String? category;
  final String? classification;
  final int page;
  final int limit;

  const KnowledgeBaseFilter({
    this.search,
    this.category,
    this.classification,
    this.page = 1,
    this.limit = 20,
  });

  KnowledgeBaseFilter copyWith({
    String? search,
    String? category,
    String? classification,
    int? page,
    int? limit,
  }) {
    return KnowledgeBaseFilter(
      search: search ?? this.search,
      category: category ?? this.category,
      classification: classification ?? this.classification,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null && search!.trim().isNotEmpty) {
      params['search'] = search!.trim();
    }
    if (category != null && category!.trim().isNotEmpty) {
      params['category'] = category!.trim();
    }
    if (classification != null && classification!.trim().isNotEmpty) {
      params['classification'] = classification!.trim();
    }
    return params;
  }
}

/// Document representation within the Knowledge Base indexing directory.
@immutable
class KnowledgeBaseDocumentModel {
  final String id;
  final String originalName;
  final bool isIndexed;
  final int chunksCount;
  final String? lastIndexedAt;
  final String? category;
  final String? classification;
  final String? mimeType;
  final int? size;

  const KnowledgeBaseDocumentModel({
    required this.id,
    required this.originalName,
    required this.isIndexed,
    this.chunksCount = 0,
    this.lastIndexedAt,
    this.category,
    this.classification,
    this.mimeType,
    this.size,
  });

  factory KnowledgeBaseDocumentModel.fromJson(Map<String, dynamic> json) {
    return KnowledgeBaseDocumentModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      originalName: json['originalName'] as String? ?? json['name'] as String? ?? 'Document',
      isIndexed: json['isIndexed'] as bool? ?? (json['chunksCount'] as num? ?? 0) > 0,
      chunksCount: (json['chunksCount'] as num?)?.toInt() ?? 0,
      lastIndexedAt: json['lastIndexedAt']?.toString() ?? json['indexedAt']?.toString(),
      category: json['category'] as String?,
      classification: json['classification'] as String?,
      mimeType: json['mimeType'] as String?,
      size: (json['size'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalName': originalName,
        'isIndexed': isIndexed,
        'chunksCount': chunksCount,
        if (lastIndexedAt != null) 'lastIndexedAt': lastIndexedAt,
        if (category != null) 'category': category,
        if (classification != null) 'classification': classification,
        if (mimeType != null) 'mimeType': mimeType,
        if (size != null) 'size': size,
      };

  KnowledgeBaseDocumentModel copyWith({
    String? id,
    String? originalName,
    bool? isIndexed,
    int? chunksCount,
    String? lastIndexedAt,
    String? category,
    String? classification,
    String? mimeType,
    int? size,
  }) {
    return KnowledgeBaseDocumentModel(
      id: id ?? this.id,
      originalName: originalName ?? this.originalName,
      isIndexed: isIndexed ?? this.isIndexed,
      chunksCount: chunksCount ?? this.chunksCount,
      lastIndexedAt: lastIndexedAt ?? this.lastIndexedAt,
      category: category ?? this.category,
      classification: classification ?? this.classification,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
    );
  }
}

/// Metadata stats returned with GET /api/v1/knowledge-base.
@immutable
class KnowledgeBaseMeta {
  final int total;
  final int page;
  final int limit;
  final int pages;
  final int totalIndexedDocuments;
  final int totalVectorChunks;

  const KnowledgeBaseMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
    this.totalIndexedDocuments = 0,
    this.totalVectorChunks = 0,
  });

  factory KnowledgeBaseMeta.fromJson(Map<String, dynamic> json) {
    return KnowledgeBaseMeta(
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      pages: (json['pages'] as num?)?.toInt() ?? 1,
      totalIndexedDocuments: (json['totalIndexedDocuments'] as num?)?.toInt() ?? 0,
      totalVectorChunks: (json['totalVectorChunks'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'page': page,
        'limit': limit,
        'pages': pages,
        'totalIndexedDocuments': totalIndexedDocuments,
        'totalVectorChunks': totalVectorChunks,
      };
}

/// List response wrapper for GET /api/v1/knowledge-base.
@immutable
class KnowledgeBaseListResponse {
  final List<KnowledgeBaseDocumentModel> documents;
  final KnowledgeBaseMeta meta;

  const KnowledgeBaseListResponse({
    required this.documents,
    required this.meta,
  });

  factory KnowledgeBaseListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final List<dynamic> rawList = rawData is List ? rawData : [];
    final list = rawList
        .whereType<Map>()
        .map((e) => KnowledgeBaseDocumentModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final metaRaw = json['meta'] ?? json['pagination'];
    final metaJson = metaRaw is Map
        ? Map<String, dynamic>.from(metaRaw)
        : <String, dynamic>{};

    return KnowledgeBaseListResponse(
      documents: list,
      meta: KnowledgeBaseMeta.fromJson(metaJson),
    );
  }
}

/// Individual vector text chunk from GET /api/v1/knowledge-base/:documentId.
@immutable
class VectorChunkModel {
  final String id;
  final int chunkIndex;
  final int pageNumber;
  final String content;
  final String? createdAt;

  const VectorChunkModel({
    required this.id,
    required this.chunkIndex,
    required this.pageNumber,
    required this.content,
    this.createdAt,
  });

  factory VectorChunkModel.fromJson(Map<String, dynamic> json) {
    return VectorChunkModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      chunkIndex: (json['chunkIndex'] as num?)?.toInt() ?? 0,
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      content: json['content'] as String? ?? json['text'] as String? ?? json['snippet'] as String? ?? '',
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chunkIndex': chunkIndex,
        'pageNumber': pageNumber,
        'content': content,
        if (createdAt != null) 'createdAt': createdAt,
      };
}

/// Document knowledge base detail response from GET /api/v1/knowledge-base/:documentId.
@immutable
class KnowledgeBaseDetailModel {
  final String documentId;
  final String documentName;
  final int chunksCount;
  final List<VectorChunkModel> chunks;

  const KnowledgeBaseDetailModel({
    required this.documentId,
    required this.documentName,
    required this.chunksCount,
    required this.chunks,
  });

  factory KnowledgeBaseDetailModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json;

    final docMap = data['document'] is Map
        ? Map<String, dynamic>.from(data['document'] as Map)
        : <String, dynamic>{};

    final chunksRaw = data['chunks'] as List<dynamic>? ?? [];

    return KnowledgeBaseDetailModel(
      documentId: docMap['id']?.toString() ?? docMap['_id']?.toString() ?? data['documentId']?.toString() ?? '',
      documentName: docMap['originalName'] as String? ?? docMap['filename'] as String? ?? data['documentName'] as String? ?? 'Document',
      chunksCount: (data['chunksCount'] as num?)?.toInt() ?? chunksRaw.length,
      chunks: chunksRaw
          .whereType<Map>()
          .map((e) => VectorChunkModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

/// Indexing result response from POST /api/v1/knowledge-base/index and POST /api/v1/rag/:documentId/index.
@immutable
class IndexDocumentResponse {
  final String documentId;
  final String? documentName;
  final int chunksIndexed;
  final String? indexedAt;

  const IndexDocumentResponse({
    required this.documentId,
    this.documentName,
    required this.chunksIndexed,
    this.indexedAt,
  });

  factory IndexDocumentResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json;

    return IndexDocumentResponse(
      documentId: data['documentId']?.toString() ?? data['id']?.toString() ?? data['_id']?.toString() ?? '',
      documentName: data['documentName'] as String? ?? data['originalName'] as String?,
      chunksIndexed: (data['chunksIndexed'] as num?)?.toInt() ?? (data['chunksCount'] as num?)?.toInt() ?? 0,
      indexedAt: data['indexedAt']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        if (documentName != null) 'documentName': documentName,
        'chunksIndexed': chunksIndexed,
        if (indexedAt != null) 'indexedAt': indexedAt,
      };
}

/// Single search hit from POST /api/v1/knowledge-base/search or POST /api/v1/rag/search.
@immutable
class KnowledgeBaseSearchResult {
  final String chunkId;
  final String? documentId;
  final String documentName;
  final int pageNumber;
  final String text;
  final double similarity;

  const KnowledgeBaseSearchResult({
    required this.chunkId,
    this.documentId,
    required this.documentName,
    required this.pageNumber,
    required this.text,
    required this.similarity,
  });

  factory KnowledgeBaseSearchResult.fromJson(Map<String, dynamic> json) {
    return KnowledgeBaseSearchResult(
      chunkId: json['chunkId']?.toString() ?? json['_id']?.toString() ?? json['id']?.toString() ?? '',
      documentId: json['documentId']?.toString(),
      documentName: json['documentName'] as String? ?? json['originalName'] as String? ?? json['filename'] as String? ?? 'Mining Document',
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      text: json['snippet'] as String? ?? json['text'] as String? ?? json['content'] as String? ?? '',
      similarity: (json['similarityScore'] as num?)?.toDouble() ?? (json['similarity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'chunkId': chunkId,
        if (documentId != null) 'documentId': documentId,
        'documentName': documentName,
        'pageNumber': pageNumber,
        'text': text,
        'similarity': similarity,
      };
}

/// Response wrapper for POST /api/v1/knowledge-base/search.
@immutable
class KnowledgeBaseSearchResponse {
  final String query;
  final int topK;
  final Map<String, dynamic>? filters;
  final int totalResults;
  final List<KnowledgeBaseSearchResult> results;

  const KnowledgeBaseSearchResponse({
    required this.query,
    required this.topK,
    this.filters,
    required this.totalResults,
    required this.results,
  });

  factory KnowledgeBaseSearchResponse.fromJson(Map<String, dynamic> json) {
    List<dynamic> resultsRaw = [];
    if (json['data'] is List) {
      resultsRaw = json['data'] as List;
    } else if (json['data'] is Map && (json['data'] as Map)['results'] is List) {
      resultsRaw = (json['data'] as Map)['results'] as List;
    } else if (json['data'] is Map && (json['data'] as Map)['data'] is List) {
      resultsRaw = (json['data'] as Map)['data'] as List;
    } else if (json['results'] is List) {
      resultsRaw = json['results'] as List;
    }

    final queryStr = json['query'] as String? ??
        (json['data'] is Map ? (json['data'] as Map)['query'] as String? : null) ??
        '';

    final topKVal = (json['topK'] as num?)?.toInt() ??
        (json['data'] is Map ? ((json['data'] as Map)['topK'] as num?)?.toInt() : null) ??
        5;

    final filtersMap = json['filters'] is Map
        ? Map<String, dynamic>.from(json['filters'] as Map)
        : (json['data'] is Map && (json['data'] as Map)['filters'] is Map
            ? Map<String, dynamic>.from((json['data'] as Map)['filters'] as Map)
            : null);

    return KnowledgeBaseSearchResponse(
      query: queryStr,
      topK: topKVal,
      filters: filtersMap,
      totalResults: (json['totalResults'] as num?)?.toInt() ?? resultsRaw.length,
      results: resultsRaw
          .whereType<Map>()
          .map((e) => KnowledgeBaseSearchResult.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
