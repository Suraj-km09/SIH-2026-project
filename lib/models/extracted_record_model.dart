/// Extracted Parameter Record matching backend ExtractedRecord schema.
class ExtractedRecordModel {
  final String id;
  final String documentId;
  final int pageNumber;
  final String parameter;
  final String value;
  final String? unit;
  final String? period;
  final String? mineName;
  final String? subsidiary;
  final double confidenceScore;
  final String? sourceText;
  final String status; // pending, approved, rejected
  final String? originalValue;
  final List<EditHistoryEntry> editHistory;
  final List<LinkedEvidence> linkedEvidence;

  const ExtractedRecordModel({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.parameter,
    required this.value,
    this.unit,
    this.period,
    this.mineName,
    this.subsidiary,
    required this.confidenceScore,
    this.sourceText,
    required this.status,
    this.originalValue,
    this.editHistory = const [],
    this.linkedEvidence = const [],
  });

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  double get confidence => confidenceScore;

  factory ExtractedRecordModel.fromJson(Map<String, dynamic> json) {
    return ExtractedRecordModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      documentId: json['documentId'] as String? ?? '',
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      parameter: json['parameter'] as String? ?? '',
      value: json['value']?.toString() ?? '',
      unit: json['unit'] as String?,
      period: json['period'] as String?,
      mineName: json['mineName'] as String?,
      subsidiary: json['subsidiary'] as String?,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      sourceText: json['sourceText'] as String?,
      status: json['status'] as String? ?? 'pending',
      originalValue: json['originalValue']?.toString(),
      editHistory: (json['editHistory'] as List<dynamic>?)
              ?.map((e) => EditHistoryEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      linkedEvidence: (json['linkedEvidence'] as List<dynamic>?)
              ?.map((l) => LinkedEvidence.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'documentId': documentId,
        'pageNumber': pageNumber,
        'parameter': parameter,
        'value': value,
        'unit': unit,
        'period': period,
        'mineName': mineName,
        'subsidiary': subsidiary,
        'confidenceScore': confidenceScore,
        'sourceText': sourceText,
        'status': status,
        'originalValue': originalValue,
        'editHistory': editHistory.map((e) => e.toJson()).toList(),
        'linkedEvidence': linkedEvidence.map((l) => l.toJson()).toList(),
      };

  ExtractedRecordModel copyWith({
    String? id,
    String? documentId,
    int? pageNumber,
    String? parameter,
    String? value,
    String? unit,
    String? period,
    String? mineName,
    String? subsidiary,
    double? confidenceScore,
    String? sourceText,
    String? status,
    String? originalValue,
    List<EditHistoryEntry>? editHistory,
    List<LinkedEvidence>? linkedEvidence,
  }) {
    return ExtractedRecordModel(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      parameter: parameter ?? this.parameter,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      period: period ?? this.period,
      mineName: mineName ?? this.mineName,
      subsidiary: subsidiary ?? this.subsidiary,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      sourceText: sourceText ?? this.sourceText,
      status: status ?? this.status,
      originalValue: originalValue ?? this.originalValue,
      editHistory: editHistory ?? this.editHistory,
      linkedEvidence: linkedEvidence ?? this.linkedEvidence,
    );
  }
}

/// Immutable audit entry of HITL record edits.
class EditHistoryEntry {
  final String? field;
  final String? oldValue;
  final String? newValue;
  final String? editedAt;
  final String? editedBy;

  const EditHistoryEntry({
    this.field,
    this.oldValue,
    this.newValue,
    this.editedAt,
    this.editedBy,
  });

  factory EditHistoryEntry.fromJson(Map<String, dynamic> json) {
    return EditHistoryEntry(
      field: json['field'] as String?,
      oldValue: json['oldValue']?.toString(),
      newValue: json['newValue']?.toString(),
      editedAt: json['editedAt'] as String?,
      editedBy: json['editedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'field': field,
        'oldValue': oldValue,
        'newValue': newValue,
        'editedAt': editedAt,
        if (editedBy != null) 'editedBy': editedBy,
      };
}

/// RAG linked evidence snippet linking record to source page.
class LinkedEvidence {
  final int? pageNumber;
  final String? snippet;
  final double? similarity;

  const LinkedEvidence({
    this.pageNumber,
    this.snippet,
    this.similarity,
  });

  factory LinkedEvidence.fromJson(Map<String, dynamic> json) {
    return LinkedEvidence(
      pageNumber: (json['pageNumber'] as num?)?.toInt(),
      snippet: json['snippet'] as String?,
      similarity: (json['similarity'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'pageNumber': pageNumber,
        'snippet': snippet,
        'similarity': similarity,
      };
}

/// Aggregate extraction statistics payload.
class ExtractionSummaryStats {
  final int total;
  final int approved;
  final int pending;
  final int rejected;
  final double avgConfidence;
  final List<String> parameters;

  const ExtractionSummaryStats({
    required this.total,
    required this.approved,
    required this.pending,
    required this.rejected,
    required this.avgConfidence,
    this.parameters = const [],
  });

  int get totalRecords => total;
  int get approvedRecords => approved;
  int get pendingRecords => pending;
  int get rejectedRecords => rejected;
  double get averageConfidence => avgConfidence;

  factory ExtractionSummaryStats.fromJson(Map<String, dynamic> json) {
    return ExtractionSummaryStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      approved: (json['approved'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      rejected: (json['rejected'] as num?)?.toInt() ?? 0,
      avgConfidence: (json['avgConfidence'] as num?)?.toDouble() ?? 0.0,
      parameters: (json['parameters'] as List<dynamic>?)
              ?.map((p) => p.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'approved': approved,
        'pending': pending,
        'rejected': rejected,
        'avgConfidence': avgConfidence,
        'parameters': parameters,
      };
}

/// Full extraction summary payload returned by GET /extraction/:documentId.
class ExtractionSummaryModel {
  final String documentId;
  final ExtractionSummaryStats summary;
  final List<ExtractedRecordModel> records;

  const ExtractionSummaryModel({
    required this.documentId,
    required this.summary,
    this.records = const [],
  });

  factory ExtractionSummaryModel.fromJson(Map<String, dynamic> json) {
    final summaryData = json['summary'] as Map<String, dynamic>? ?? {};
    final recordsList = (json['records'] as List<dynamic>?)
            ?.map((r) => ExtractedRecordModel.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    return ExtractionSummaryModel(
      documentId: json['documentId'] as String? ?? '',
      summary: ExtractionSummaryStats.fromJson(summaryData),
      records: recordsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'summary': summary.toJson(),
        'records': records.map((r) => r.toJson()).toList(),
      };
}

/// Pagination metadata for extracted records.
class ExtractionRecordsPaginationMeta {
  final int total;
  final int page;
  final int limit;
  final int pages;

  const ExtractionRecordsPaginationMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  factory ExtractionRecordsPaginationMeta.fromJson(Map<String, dynamic> json) {
    return ExtractionRecordsPaginationMeta(
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 50,
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

/// Paginated extracted records payload returned by GET /extraction/:documentId/records.
class ExtractionRecordsResponse {
  final List<ExtractedRecordModel> records;
  final ExtractionRecordsPaginationMeta meta;

  const ExtractionRecordsResponse({
    required this.records,
    required this.meta,
  });

  factory ExtractionRecordsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List<dynamic>?)
            ?.map((e) => ExtractedRecordModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final metaData = json['meta'] as Map<String, dynamic>? ??
        {'total': list.length, 'page': 1, 'limit': 50, 'pages': 1};

    return ExtractionRecordsResponse(
      records: list,
      meta: ExtractionRecordsPaginationMeta.fromJson(metaData),
    );
  }
}

/// Filter query parameters for GET /extraction/:documentId/records.
class ExtractionFilter {
  final String? status; // pending, approved, rejected
  final String? parameter;
  final String? mineName;
  final double? minConfidence;
  final int page;
  final int limit;

  const ExtractionFilter({
    this.status,
    this.parameter,
    this.mineName,
    this.minConfidence,
    this.page = 1,
    this.limit = 50,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null && status!.isNotEmpty) {
      params['status'] = status;
    }
    if (parameter != null && parameter!.trim().isNotEmpty) {
      params['parameter'] = parameter!.trim();
    }
    if (mineName != null && mineName!.trim().isNotEmpty) {
      params['mineName'] = mineName!.trim();
    }
    if (minConfidence != null) {
      params['minConfidence'] = minConfidence;
    }
    return params;
  }

  ExtractionFilter copyWith({
    String? status,
    String? parameter,
    String? mineName,
    double? minConfidence,
    int? page,
    int? limit,
    bool clearStatus = false,
    bool clearParameter = false,
    bool clearMineName = false,
    bool clearMinConfidence = false,
  }) {
    return ExtractionFilter(
      status: clearStatus ? null : (status ?? this.status),
      parameter: clearParameter ? null : (parameter ?? this.parameter),
      mineName: clearMineName ? null : (mineName ?? this.mineName),
      minConfidence: clearMinConfidence ? null : (minConfidence ?? this.minConfidence),
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

/// Request payload for updating an extracted record: PUT /extraction/:documentId/records/:recordId.
class ExtractedRecordUpdateRequest {
  final String? value;
  final String? unit;
  final String? parameter;
  final String? status;
  final String? period;
  final String? mineName;
  final String? subsidiary;

  const ExtractedRecordUpdateRequest({
    this.value,
    this.unit,
    this.parameter,
    this.status,
    this.period,
    this.mineName,
    this.subsidiary,
  });

  Map<String, dynamic> toJson() => {
        if (value != null) 'value': value,
        if (unit != null) 'unit': unit,
        if (parameter != null) 'parameter': parameter,
        if (status != null) 'status': status,
        if (period != null) 'period': period,
        if (mineName != null) 'mineName': mineName,
        if (subsidiary != null) 'subsidiary': subsidiary,
      };
}

/// Response payload from bulk-approving records: POST /extraction/records/bulk-approve.
class BulkApproveResponse {
  final int matchedCount;
  final int modifiedCount;

  const BulkApproveResponse({
    required this.matchedCount,
    required this.modifiedCount,
  });

  factory BulkApproveResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return BulkApproveResponse(
      matchedCount: (data['matchedCount'] as num?)?.toInt() ?? 0,
      modifiedCount: (data['modifiedCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'matchedCount': matchedCount,
        'modifiedCount': modifiedCount,
      };
}
