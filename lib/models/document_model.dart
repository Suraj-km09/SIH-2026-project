/// Document model matching backend Document schema.
class DocumentModel {
  final String id;
  final String? filename;
  final String originalName;
  final String? mimeType;
  final int fileSize;
  final String fileType;
  final String? hash;
  final String category;
  final String classification;
  final String status;
  final int totalPages;
  final GisMetadata? gisMetadata;
  final String? uploadedAt;
  final String? userId;
  final List<DocumentEntity>? entities;
  final List<String>? topicIds;

  const DocumentModel({
    required this.id,
    this.filename,
    required this.originalName,
    this.mimeType,
    required this.fileSize,
    required this.fileType,
    this.hash,
    required this.category,
    required this.classification,
    required this.status,
    this.totalPages = 0,
    this.gisMetadata,
    this.uploadedAt,
    this.userId,
    this.entities,
    this.topicIds,
  });

  bool get isPending => status == 'pending';
  bool get isQueued => status == 'queued';
  bool get isProcessing => status == 'queued' || status == 'processing';
  bool get isCompleted => status == 'completed' || status == 'extracted';
  bool get isFailed => status == 'failed';

  /// Terminal processing state reached (stops polling)
  bool get isTerminal => isCompleted || isFailed;

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      filename: json['filename'] as String?,
      originalName: json['originalName'] as String? ?? 'Untitled Document',
      mimeType: json['mimeType'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      fileType: json['fileType'] as String? ?? 'pdf',
      hash: json['hash'] as String?,
      category: json['category'] as String? ?? 'Uncategorized',
      classification: json['classification'] as String? ?? 'internal',
      status: json['status'] as String? ?? 'pending',
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      gisMetadata: json['gisMetadata'] != null
          ? GisMetadata.fromJson(json['gisMetadata'] as Map<String, dynamic>)
          : null,
      uploadedAt: json['uploadedAt'] as String?,
      userId: json['userId'] as String?,
      entities: (json['entities'] as List<dynamic>?)
          ?.map((e) => DocumentEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      topicIds: (json['topicIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'filename': filename,
        'originalName': originalName,
        'mimeType': mimeType,
        'fileSize': fileSize,
        'fileType': fileType,
        'hash': hash,
        'category': category,
        'classification': classification,
        'status': status,
        'totalPages': totalPages,
        if (gisMetadata != null) 'gisMetadata': gisMetadata!.toJson(),
        'uploadedAt': uploadedAt,
        'userId': userId,
        if (entities != null) 'entities': entities!.map((e) => e.toJson()).toList(),
        if (topicIds != null) 'topicIds': topicIds,
      };

  DocumentModel copyWith({
    String? id,
    String? filename,
    String? originalName,
    String? mimeType,
    int? fileSize,
    String? fileType,
    String? hash,
    String? category,
    String? classification,
    String? status,
    int? totalPages,
    GisMetadata? gisMetadata,
    String? uploadedAt,
    String? userId,
    List<DocumentEntity>? entities,
    List<String>? topicIds,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      originalName: originalName ?? this.originalName,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      hash: hash ?? this.hash,
      category: category ?? this.category,
      classification: classification ?? this.classification,
      status: status ?? this.status,
      totalPages: totalPages ?? this.totalPages,
      gisMetadata: gisMetadata ?? this.gisMetadata,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      userId: userId ?? this.userId,
      entities: entities ?? this.entities,
      topicIds: topicIds ?? this.topicIds,
    );
  }
}

/// Geographic coordinates metadata for GIS integration.
class GisMetadata {
  final double? latitude;
  final double? longitude;
  final double? elevation;
  final String? mineCode;
  final String? region;

  const GisMetadata({
    this.latitude,
    this.longitude,
    this.elevation,
    this.mineCode,
    this.region,
  });

  factory GisMetadata.fromJson(Map<String, dynamic> json) {
    return GisMetadata(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      elevation: (json['elevation'] as num?)?.toDouble(),
      mineCode: json['mineCode'] as String?,
      region: json['region'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (elevation != null) 'elevation': elevation,
        if (mineCode != null) 'mineCode': mineCode,
        if (region != null) 'region': region,
      };
}

/// Extracted Named Entity inside a document.
class DocumentEntity {
  final String name;
  final String type;

  const DocumentEntity({
    required this.name,
    required this.type,
  });

  factory DocumentEntity.fromJson(Map<String, dynamic> json) {
    return DocumentEntity(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'GENERAL',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
      };
}

/// Individual extracted OCR text page of a document.
class DocumentPageModel {
  final String id;
  final String documentId;
  final int pageNumber;
  final String text;

  const DocumentPageModel({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.text,
  });

  factory DocumentPageModel.fromJson(Map<String, dynamic> json) {
    return DocumentPageModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      documentId: json['documentId'] as String? ?? '',
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'documentId': documentId,
        'pageNumber': pageNumber,
        'text': text,
      };
}

/// Full document detail payload returned by GET /documents/:id.
class DocumentDetailModel {
  final DocumentModel document;
  final List<DocumentPageModel> pages;

  const DocumentDetailModel({
    required this.document,
    required this.pages,
  });

  factory DocumentDetailModel.fromJson(Map<String, dynamic> json) {
    final docData = json['document'] as Map<String, dynamic>? ?? json;
    final pagesList = (json['pages'] as List<dynamic>?)
            ?.map((p) => DocumentPageModel.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    return DocumentDetailModel(
      document: DocumentModel.fromJson(docData),
      pages: pagesList,
    );
  }

  Map<String, dynamic> toJson() => {
        'document': document.toJson(),
        'pages': pages.map((p) => p.toJson()).toList(),
      };
}

/// Detailed metadata returned by GET /documents/:id/metadata.
class DocumentMetadataModel {
  final String id;
  final String originalName;
  final String? filename;
  final String? mimeType;
  final String fileType;
  final int fileSize;
  final String? hash;
  final String status;
  final String category;
  final String classification;
  final int totalPages;
  final List<DocumentEntity> entities;
  final List<String> topicIds;
  final List<dynamic> similarDocuments;
  final GisMetadata? gisMetadata;
  final String? retentionDate;
  final String? uploadedAt;
  final String? processedAt;

  const DocumentMetadataModel({
    required this.id,
    required this.originalName,
    this.filename,
    this.mimeType,
    required this.fileType,
    required this.fileSize,
    this.hash,
    required this.status,
    required this.category,
    required this.classification,
    this.totalPages = 0,
    this.entities = const [],
    this.topicIds = const [],
    this.similarDocuments = const [],
    this.gisMetadata,
    this.retentionDate,
    this.uploadedAt,
    this.processedAt,
  });

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory DocumentMetadataModel.fromJson(Map<String, dynamic> json) {
    return DocumentMetadataModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      originalName: json['originalName'] as String? ?? 'Untitled Document',
      filename: json['filename'] as String?,
      mimeType: json['mimeType'] as String?,
      fileType: json['fileType'] as String? ?? 'pdf',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      hash: json['hash'] as String?,
      status: json['status'] as String? ?? 'pending',
      category: json['category'] as String? ?? 'Uncategorized',
      classification: json['classification'] as String? ?? 'internal',
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      entities: (json['entities'] as List<dynamic>?)
              ?.map((e) => DocumentEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topicIds: (json['topicIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      similarDocuments: json['similarDocuments'] as List<dynamic>? ?? [],
      gisMetadata: json['gisMetadata'] != null
          ? GisMetadata.fromJson(json['gisMetadata'] as Map<String, dynamic>)
          : null,
      retentionDate: json['retentionDate'] as String?,
      uploadedAt: json['uploadedAt'] as String?,
      processedAt: json['processedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'originalName': originalName,
        'filename': filename,
        'mimeType': mimeType,
        'fileType': fileType,
        'fileSize': fileSize,
        'hash': hash,
        'status': status,
        'category': category,
        'classification': classification,
        'totalPages': totalPages,
        'entities': entities.map((e) => e.toJson()).toList(),
        'topicIds': topicIds,
        'similarDocuments': similarDocuments,
        if (gisMetadata != null) 'gisMetadata': gisMetadata!.toJson(),
        'retentionDate': retentionDate,
        'uploadedAt': uploadedAt,
        'processedAt': processedAt,
      };
}

/// Request body for updating editable metadata fields: PUT /documents/:id/metadata.
class DocumentMetadataUpdateRequest {
  final String? category;
  final String? classification;
  final GisMetadata? gisMetadata;
  final String? retentionDate;

  const DocumentMetadataUpdateRequest({
    this.category,
    this.classification,
    this.gisMetadata,
    this.retentionDate,
  });

  Map<String, dynamic> toJson() => {
        if (category != null) 'category': category,
        if (classification != null) 'classification': classification,
        if (gisMetadata != null) 'gisMetadata': gisMetadata!.toJson(),
        if (retentionDate != null) 'retentionDate': retentionDate,
      };
}

/// Ingestion Job Telemetry status returned by GET /documents/:id/status.
class DocumentStatusModel {
  final String id;
  final String documentId;
  final String status; // queued | processing | completed | failed
  final int progress; // 0 to 100
  final String? error;
  final String? createdAt;
  final String? updatedAt;

  const DocumentStatusModel({
    required this.id,
    required this.documentId,
    required this.status,
    required this.progress,
    this.error,
    this.createdAt,
    this.updatedAt,
  });

  bool get isQueued => status == 'queued';
  bool get isProcessing => status == 'processing' || status == 'queued';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isTerminal => isCompleted || isFailed;

  factory DocumentStatusModel.fromJson(Map<String, dynamic> json) {
    return DocumentStatusModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      documentId: json['documentId'] as String? ?? '',
      status: json['status'] as String? ?? 'queued',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      error: json['error'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'documentId': documentId,
        'status': status,
        'progress': progress,
        'error': error,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

/// Filter query parameters for GET /documents.
class DocumentFilter {
  final String? search;
  final String? type; // pdf, docx, xlsx, pptx, csv, image
  final String? status; // pending, processing, completed, failed
  final String? category;
  final String? classification; // public, internal, confidential, restricted
  final String? dateFrom;
  final String? dateTo;
  final int page;
  final int limit;

  const DocumentFilter({
    this.search,
    this.type,
    this.status,
    this.category,
    this.classification,
    this.dateFrom,
    this.dateTo,
    this.page = 1,
    this.limit = 20,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null && search!.trim().isNotEmpty) {
      params['search'] = search!.trim();
    }
    if (type != null && type!.isNotEmpty) {
      params['type'] = type;
    }
    if (status != null && status!.isNotEmpty) {
      params['status'] = status;
    }
    if (category != null && category!.isNotEmpty) {
      params['category'] = category;
    }
    if (classification != null && classification!.isNotEmpty) {
      params['classification'] = classification;
    }
    if (dateFrom != null && dateFrom!.isNotEmpty) {
      params['dateFrom'] = dateFrom;
    }
    if (dateTo != null && dateTo!.isNotEmpty) {
      params['dateTo'] = dateTo;
    }
    return params;
  }

  DocumentFilter copyWith({
    String? search,
    String? type,
    String? status,
    String? category,
    String? classification,
    String? dateFrom,
    String? dateTo,
    int? page,
    int? limit,
    bool clearSearch = false,
    bool clearType = false,
    bool clearStatus = false,
    bool clearCategory = false,
    bool clearClassification = false,
  }) {
    return DocumentFilter(
      search: clearSearch ? null : (search ?? this.search),
      type: clearType ? null : (type ?? this.type),
      status: clearStatus ? null : (status ?? this.status),
      category: clearCategory ? null : (category ?? this.category),
      classification: clearClassification ? null : (classification ?? this.classification),
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

/// Pagination metadata returned by GET /documents.
class DocumentPaginationMeta {
  final int total;
  final int page;
  final int limit;
  final int pages;

  const DocumentPaginationMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  factory DocumentPaginationMeta.fromJson(Map<String, dynamic> json) {
    return DocumentPaginationMeta(
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      pages: (json['pages'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'page': page,
        'limit': limit,
        'pages': pages,
      };
}

/// Paginated Document list response payload.
class DocumentListResponse {
  final List<DocumentModel> documents;
  final DocumentPaginationMeta meta;

  const DocumentListResponse({
    required this.documents,
    required this.meta,
  });

  factory DocumentListResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List<dynamic>?)
            ?.map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final metaData = json['meta'] as Map<String, dynamic>? ??
        {'total': list.length, 'page': 1, 'limit': 20, 'pages': 1};

    return DocumentListResponse(
      documents: list,
      meta: DocumentPaginationMeta.fromJson(metaData),
    );
  }
}
