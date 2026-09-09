/// Statutory Report model matching backend Report schema.
class ReportModel {
  final String id;
  final String title;
  final String type;
  final dynamic content; // String or Map
  final String status; // draft, review, approved, rejected
  final String? fileUrl;
  final String? generatedBy;
  final String? reviewerId;
  final String? reviewerComments;
  final String? reviewedAt;
  final String? approvedBy;
  final String? approvedAt;
  final int version;
  final double? confidenceScore;
  final String language; // en, hi
  final String? createdAt;
  final List<String> documentIds;

  const ReportModel({
    required this.id,
    required this.title,
    required this.type,
    this.content,
    required this.status,
    this.fileUrl,
    this.generatedBy,
    this.reviewerId,
    this.reviewerComments,
    this.reviewedAt,
    this.approvedBy,
    this.approvedAt,
    this.version = 1,
    this.confidenceScore,
    this.language = 'en',
    this.createdAt,
    this.documentIds = const [],
  });

  bool get isApproved => status == 'approved' || status == 'completed';
  bool get isReview => status == 'review';
  bool get isDraft => status == 'draft';
  bool get isRejected => status == 'rejected';
  bool get isCompleted => status == 'completed';

  List<ReportSourceDocument> get sources {
    if (content is Map && (content as Map).containsKey('sources')) {
      final rawList = (content as Map)['sources'];
      if (rawList is List) {
        return rawList
            .whereType<Map<String, dynamic>>()
            .map((e) => ReportSourceDocument.fromJson(e))
            .toList();
      }
    }
    return const [];
  }

  String get contentAsString {
    if (content == null) return '';
    if (content is String) return content as String;
    if (content is Map) {
      final map = content as Map;
      if (map.containsKey('markdown')) return map['markdown'].toString();
      if (map.containsKey('text')) return map['text'].toString();
      if (map.containsKey('body')) return map['body'].toString();
      return map.entries.map((e) => '## ${e.key}\n${e.value}').join('\n\n');
    }
    return content.toString();
  }

  static String? _safeStr(dynamic v) {
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    if (v is Map) {
      final val = v['username'] ?? v['name'] ?? v['title'] ?? v['filename'] ?? v['_id'] ?? v['id'];
      if (val != null) return val.toString();
      return null;
    }
    if (v is List) return null;
    return v.toString();
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final docList = (json['documentIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final genBy = json['generatedBy'];
    String? generatedByStr;
    if (genBy is String) {
      generatedByStr = genBy;
    } else if (genBy is Map) {
      generatedByStr = _safeStr(genBy);
    }

    final appBy = json['approvedBy'];
    String? approvedByStr;
    if (appBy is String) {
      approvedByStr = appBy;
    } else if (appBy is Map) {
      approvedByStr = _safeStr(appBy);
    }

    final revId = json['reviewerId'];
    String? reviewerIdStr;
    if (revId is String) {
      reviewerIdStr = revId;
    } else if (revId is Map) {
      reviewerIdStr = _safeStr(revId);
    }

    return ReportModel(
      id: _safeStr(json['_id']) ?? _safeStr(json['id']) ?? '',
      title: _safeStr(json['title']) ?? 'Untitled Report',
      type: _safeStr(json['type']) ?? 'production_summary',
      content: json['content'],
      status: _safeStr(json['status']) ?? 'draft',
      fileUrl: _safeStr(json['fileUrl']),
      generatedBy: generatedByStr,
      reviewerId: reviewerIdStr,
      reviewerComments: _safeStr(json['reviewerComments']),
      reviewedAt: _safeStr(json['reviewedAt']),
      approvedBy: approvedByStr,
      approvedAt: _safeStr(json['approvedAt']),
      version: (json['version'] as num?)?.toInt() ?? num.tryParse(json['version']?.toString() ?? '')?.toInt() ?? 1,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? double.tryParse(json['confidenceScore']?.toString() ?? ''),
      language: _safeStr(json['language']) ?? 'en',
      createdAt: _safeStr(json['createdAt']),
      documentIds: docList,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'title': title,
        'type': type,
        if (content != null) 'content': content,
        'status': status,
        'fileUrl': fileUrl,
        'generatedBy': generatedBy,
        'reviewerId': reviewerId,
        'reviewerComments': reviewerComments,
        'reviewedAt': reviewedAt,
        'approvedBy': approvedBy,
        'approvedAt': approvedAt,
        'version': version,
        'confidenceScore': confidenceScore,
        'language': language,
        'createdAt': createdAt,
        'documentIds': documentIds,
      };

  ReportModel copyWith({
    String? id,
    String? title,
    String? type,
    dynamic content,
    String? status,
    String? fileUrl,
    String? generatedBy,
    String? reviewerId,
    String? reviewerComments,
    String? reviewedAt,
    String? approvedBy,
    String? approvedAt,
    int? version,
    double? confidenceScore,
    String? language,
    String? createdAt,
    List<String>? documentIds,
  }) {
    return ReportModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      content: content ?? this.content,
      status: status ?? this.status,
      fileUrl: fileUrl ?? this.fileUrl,
      generatedBy: generatedBy ?? this.generatedBy,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerComments: reviewerComments ?? this.reviewerComments,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      version: version ?? this.version,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      documentIds: documentIds ?? this.documentIds,
    );
  }
}

/// Filter query parameters for GET /api/v1/reports.
class ReportFilter {
  final String? type;
  final String? status;
  final int page;
  final int limit;

  const ReportFilter({
    this.type,
    this.status,
    this.page = 1,
    this.limit = 20,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (type != null && type!.isNotEmpty && type != 'all') {
      params['type'] = type;
    }
    if (status != null && status!.isNotEmpty && status != 'all') {
      params['status'] = status;
    }
    return params;
  }

  ReportFilter copyWith({
    String? type,
    String? status,
    int? page,
    int? limit,
    bool clearType = false,
    bool clearStatus = false,
  }) {
    return ReportFilter(
      type: clearType ? null : (type ?? this.type),
      status: clearStatus ? null : (status ?? this.status),
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

/// Pagination metadata for reports.
class ReportPaginationMeta {
  final int total;
  final int page;
  final int limit;
  final int pages;

  const ReportPaginationMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  factory ReportPaginationMeta.fromJson(Map<String, dynamic> json) {
    return ReportPaginationMeta(
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

/// Paginated reports response payload returned by GET /api/v1/reports.
class ReportsResponse {
  final List<ReportModel> reports;
  final ReportPaginationMeta meta;

  const ReportsResponse({
    required this.reports,
    required this.meta,
  });

  factory ReportsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List<dynamic>?)
            ?.map((e) => ReportModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final metaData = json['meta'] as Map<String, dynamic>? ??
        {'total': list.length, 'page': 1, 'limit': 20, 'pages': 1};

    return ReportsResponse(
      reports: list,
      meta: ReportPaginationMeta.fromJson(metaData),
    );
  }
}

/// Source document referenced in report content.
class ReportSourceDocument {
  final String id;
  final String originalName;
  final String? filename;

  const ReportSourceDocument({
    required this.id,
    required this.originalName,
    this.filename,
  });

  factory ReportSourceDocument.fromJson(Map<String, dynamic> json) {
    return ReportSourceDocument(
      id: ReportModel._safeStr(json['_id']) ?? ReportModel._safeStr(json['id']) ?? '',
      originalName: ReportModel._safeStr(json['originalName']) ??
          ReportModel._safeStr(json['filename']) ??
          'Source Document',
      filename: ReportModel._safeStr(json['filename']),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'originalName': originalName,
        if (filename != null) 'filename': filename,
      };
}

/// Request payload for generating report: POST /api/v1/reports/generate.
class ReportGenerateRequest {
  final String type;
  final String title;
  final List<String> documentIds;
  final String language;
  final String? period;
  final String? mine;
  final String? instructions;

  const ReportGenerateRequest({
    required this.type,
    required this.title,
    this.documentIds = const [],
    this.language = 'en',
    this.period,
    this.mine,
    this.instructions,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'documentIds': documentIds,
        'language': language,
        if (period != null && period!.trim().isNotEmpty) 'period': period!.trim(),
        if (mine != null && mine!.trim().isNotEmpty) 'mine': mine!.trim(),
        if (instructions != null && instructions!.trim().isNotEmpty) 'instructions': instructions!.trim(),
      };
}

/// Request payload for updating report: PUT /api/v1/reports/:id.
class ReportUpdateRequest {
  final String? title;
  final dynamic content;
  final String? type;

  const ReportUpdateRequest({
    this.title,
    this.content,
    this.type,
  });

  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (type != null) 'type': type,
      };
}

/// Request payload for rejecting report: POST /api/v1/reports/:id/reject or /reviews/:id/reject.
class ReportRejectRequest {
  final String reason;

  const ReportRejectRequest({
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'reason': reason,
      };
}

/// Cited Evidence snippet linked to reports and AI assistant.
class CitedEvidenceModel {
  final String documentId;
  final String? documentName;
  final int? pageNumber;
  final String snippet;
  final double? similarity;

  const CitedEvidenceModel({
    required this.documentId,
    this.documentName,
    this.pageNumber,
    required this.snippet,
    this.similarity,
  });

  factory CitedEvidenceModel.fromJson(Map<String, dynamic> json) {
    return CitedEvidenceModel(
      documentId: json['documentId'] as String? ?? '',
      documentName: json['documentName'] as String?,
      pageNumber: (json['pageNumber'] as num?)?.toInt(),
      snippet: json['snippet'] as String? ?? '',
      similarity: (json['similarity'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'documentName': documentName,
        'pageNumber': pageNumber,
        'snippet': snippet,
        if (similarity != null) 'similarity': similarity,
      };
}

/// Historical version revision of a report.
class ReportVersionModel {
  final int version;
  final String title;
  final String? content;
  final String? updatedBy;
  final String? updatedAt;
  final String? changeSummary;

  const ReportVersionModel({
    required this.version,
    required this.title,
    this.content,
    this.updatedBy,
    this.updatedAt,
    this.changeSummary,
  });

  factory ReportVersionModel.fromJson(Map<String, dynamic> json) {
    return ReportVersionModel(
      version: (json['version'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? '',
      content: json['content'] as String?,
      updatedBy: json['updatedBy'] as String?,
      updatedAt: json['updatedAt'] as String?,
      changeSummary: json['changeSummary'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'title': title,
        if (content != null) 'content': content,
        'updatedBy': updatedBy,
        'updatedAt': updatedAt,
        'changeSummary': changeSummary,
      };
}

/// Field-level change diff comparison between revisions.
class ReportChangeModel {
  final String field;
  final String? oldValue;
  final String? newValue;
  final String? timestamp;
  final String? author;

  const ReportChangeModel({
    required this.field,
    this.oldValue,
    this.newValue,
    this.timestamp,
    this.author,
  });

  factory ReportChangeModel.fromJson(Map<String, dynamic> json) {
    return ReportChangeModel(
      field: json['field'] as String? ?? '',
      oldValue: json['oldValue']?.toString(),
      newValue: json['newValue']?.toString(),
      timestamp: json['timestamp'] as String?,
      author: json['author'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'field': field,
        'oldValue': oldValue,
        'newValue': newValue,
        'timestamp': timestamp,
        'author': author,
      };
}

/// Item in the governance review queue: GET /api/v1/reviews/pending.
class ReviewItemModel {
  final String id;
  final String reportId;
  final String title;
  final String type;
  final String submittedBy;
  final String submittedAt;
  final double confidenceScore;
  final int evidenceCount;
  final int daysPending;
  final ReportModel? report;

  const ReviewItemModel({
    required this.id,
    required this.reportId,
    required this.title,
    required this.type,
    required this.submittedBy,
    required this.submittedAt,
    this.confidenceScore = 0.95,
    this.evidenceCount = 0,
    this.daysPending = 0,
    this.report,
  });

  factory ReviewItemModel.fromJson(Map<String, dynamic> json) {
    String submittedByStr = 'Analyst';
    final rawSubmitted = json['submittedBy'] ?? json['generatedBy'];
    if (rawSubmitted is String && rawSubmitted.isNotEmpty) {
      submittedByStr = rawSubmitted;
    } else if (rawSubmitted is Map) {
      submittedByStr = rawSubmitted['username']?.toString() ??
          rawSubmitted['name']?.toString() ??
          rawSubmitted['_id']?.toString() ??
          'Analyst';
    }

    ReportModel? reportObj;
    if (json['report'] is Map) {
      reportObj = ReportModel.fromJson(
          Map<String, dynamic>.from(json['report'] as Map));
    } else if (json['content'] != null) {
      try {
        reportObj = ReportModel.fromJson(json);
      } catch (_) {}
    }

    int evCount = (json['evidenceCount'] as num?)?.toInt() ?? 0;
    if (evCount == 0 && json['content'] is Map) {
      final contentMap = json['content'] as Map;
      if (contentMap['sources'] is List) {
        evCount = (contentMap['sources'] as List).length;
      }
    } else if (evCount == 0 && reportObj != null) {
      evCount = reportObj.sources.length;
    }

    int days = (json['daysPending'] as num?)?.toInt() ?? 0;
    final createdRaw =
        json['createdAt']?.toString() ?? json['submittedAt']?.toString() ?? '';
    if (days == 0 && createdRaw.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdRaw);
        days = DateTime.now().difference(dt).inDays.clamp(0, 999);
      } catch (_) {}
    }

    return ReviewItemModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      reportId: json['reportId'] as String? ?? json['_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Pending Review',
      type: json['type'] as String? ?? 'production_summary',
      submittedBy: submittedByStr,
      submittedAt: json['submittedAt'] as String? ??
          json['createdAt'] as String? ??
          '',
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.95,
      evidenceCount: evCount,
      daysPending: days,
      report: reportObj,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'reportId': reportId,
        'title': title,
        'type': type,
        'submittedBy': submittedBy,
        'submittedAt': submittedAt,
        'confidenceScore': confidenceScore,
        'evidenceCount': evidenceCount,
        'daysPending': daysPending,
        if (report != null) 'report': report!.toJson(),
      };
}
