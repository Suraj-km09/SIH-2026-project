/// Algorithmic validation issue model matching backend ValidationResult schema.
class ValidationIssueModel {
  final String id;
  final String documentId;
  final String? recordId;
  final String type; // range_check, math_discrepancy, outlier, missing_data, duplicate, conflict, unit_mismatch, invalid_value, suspicious_value, cross_document_mismatch, cross_table
  final String severity; // info, warning, error, critical
  final String? field;
  final String message;
  final String status; // open, resolved, ignored
  final String? resolution;
  final String? correctedValue;
  final String? currentValue;
  final String? suggestedValue;
  final String? notes;
  final String? resolvedAt;
  final String? resolvedBy;

  const ValidationIssueModel({
    required this.id,
    required this.documentId,
    this.recordId,
    required this.type,
    required this.severity,
    this.field,
    required this.message,
    required this.status,
    this.resolution,
    this.correctedValue,
    this.currentValue,
    this.suggestedValue,
    this.notes,
    this.resolvedAt,
    this.resolvedBy,
  });

  bool get isOpen => status == 'open';
  bool get isResolved => status == 'resolved';
  bool get isIgnored => status == 'ignored';
  bool get isCritical => severity == 'critical';
  bool get isError => severity == 'error';
  bool get isWarning => severity == 'warning';
  bool get isInfo => severity == 'info';
  String? get resolutionNotes => notes;

  /// Safely converts a JSON value to String, handling Map/List/num/bool from backend.
  static String? safeStr(dynamic v) {
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    if (v is Map) {
      final id = v['_id'] ?? v['id'] ?? v['filename'] ?? v['name'] ?? v['title'] ?? v['message'];
      if (id != null) return id.toString();
      return null;
    }
    if (v is List) return null;
    return v.toString();
  }

  factory ValidationIssueModel.fromJson(Map<String, dynamic> json) {
    return ValidationIssueModel(
      id: safeStr(json['_id']) ?? safeStr(json['id']) ?? '',
      documentId: safeStr(json['documentId']) ?? '',
      recordId: safeStr(json['recordId']),
      type: safeStr(json['type']) ?? 'invalid_value',
      severity: safeStr(json['severity']) ?? 'warning',
      field: safeStr(json['field']),
      message: safeStr(json['message']) ?? '',
      status: safeStr(json['status']) ?? 'open',
      resolution: safeStr(json['resolution']),
      correctedValue: safeStr(json['correctedValue']),
      currentValue: safeStr(json['currentValue']),
      suggestedValue: safeStr(json['suggestedValue']),
      notes: safeStr(json['notes']),
      resolvedAt: safeStr(json['resolvedAt']),
      resolvedBy: safeStr(json['resolvedBy']),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'documentId': documentId,
        'recordId': recordId,
        'type': type,
        'severity': severity,
        'field': field,
        'message': message,
        'status': status,
        'resolution': resolution,
        'correctedValue': correctedValue,
        if (currentValue != null) 'currentValue': currentValue,
        if (suggestedValue != null) 'suggestedValue': suggestedValue,
        'notes': notes,
        'resolvedAt': resolvedAt,
        if (resolvedBy != null) 'resolvedBy': resolvedBy,
      };

  ValidationIssueModel copyWith({
    String? id,
    String? documentId,
    String? recordId,
    String? type,
    String? severity,
    String? field,
    String? message,
    String? status,
    String? resolution,
    String? correctedValue,
    String? currentValue,
    String? suggestedValue,
    String? notes,
    String? resolvedAt,
    String? resolvedBy,
  }) {
    return ValidationIssueModel(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      recordId: recordId ?? this.recordId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      field: field ?? this.field,
      message: message ?? this.message,
      status: status ?? this.status,
      resolution: resolution ?? this.resolution,
      correctedValue: correctedValue ?? this.correctedValue,
      currentValue: currentValue ?? this.currentValue,
      suggestedValue: suggestedValue ?? this.suggestedValue,
      notes: notes ?? this.notes,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
    );
  }
}

/// Aggregate validation summary and Quality Score.
class ValidationSummaryModel {
  final String documentId;
  final String? documentName;
  final String? documentStatus;
  final int qualityScore;
  final double avgConfidence;
  final int totalIssues;
  final int openIssues;
  final int resolvedIssues;
  final int recordsCount;
  final Map<String, int> bySeverity;
  final Map<String, int> byType;
  final List<ValidationIssueModel> issues;

  const ValidationSummaryModel({
    required this.documentId,
    this.documentName,
    this.documentStatus,
    required this.qualityScore,
    required this.avgConfidence,
    required this.totalIssues,
    required this.openIssues,
    required this.resolvedIssues,
    this.recordsCount = 0,
    this.bySeverity = const {},
    this.byType = const {},
    this.issues = const [],
  });

  factory ValidationSummaryModel.fromJson(Map<String, dynamic> json) {
    final sev = json['bySeverity'];
    final sevMap = <String, int>{};
    if (sev is Map) {
      sev.forEach((k, v) => sevMap[k.toString()] = num.tryParse(v?.toString() ?? '')?.toInt() ?? 0);
    }

    final types = json['byType'];
    final typeMap = <String, int>{};
    if (types is Map) {
      types.forEach((k, v) => typeMap[k.toString()] = num.tryParse(v?.toString() ?? '')?.toInt() ?? 0);
    }

    final docMap = json['documentId'] is Map ? json['documentId'] as Map : null;
    final docId = ValidationIssueModel.safeStr(json['documentId']) ??
        ValidationIssueModel.safeStr(json['id']) ??
        ValidationIssueModel.safeStr(json['_id']) ??
        '';
    final docName = ValidationIssueModel.safeStr(json['documentName']) ??
        (docMap != null ? ValidationIssueModel.safeStr(docMap['filename'] ?? docMap['name']) : null);
    final docStatus = ValidationIssueModel.safeStr(json['documentStatus']) ??
        (docMap != null ? ValidationIssueModel.safeStr(docMap['status']) : null);

    final rawIssues = json['issues'] ?? json['data'] ?? json['results'];
    final List<ValidationIssueModel> issuesList = [];
    if (rawIssues is List) {
      for (final item in rawIssues) {
        if (item is Map<String, dynamic>) {
          issuesList.add(ValidationIssueModel.fromJson(item));
        } else if (item is Map) {
          issuesList.add(ValidationIssueModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return ValidationSummaryModel(
      documentId: docId,
      documentName: docName,
      documentStatus: docStatus,
      qualityScore: num.tryParse(json['qualityScore']?.toString() ?? '')?.toInt() ?? 100,
      avgConfidence: double.tryParse(json['avgConfidence']?.toString() ?? '') ?? 1.0,
      totalIssues: num.tryParse(json['totalIssues']?.toString() ?? '')?.toInt() ?? issuesList.length,
      openIssues: num.tryParse(json['openIssues']?.toString() ?? '')?.toInt() ?? issuesList.where((i) => i.isOpen).length,
      resolvedIssues: num.tryParse(json['resolvedIssues']?.toString() ?? '')?.toInt() ?? issuesList.where((i) => i.isResolved).length,
      recordsCount: num.tryParse(json['recordsCount']?.toString() ?? '')?.toInt() ?? 0,
      bySeverity: sevMap,
      byType: typeMap,
      issues: issuesList,
    );
  }

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'documentName': documentName,
        'documentStatus': documentStatus,
        'qualityScore': qualityScore,
        'avgConfidence': avgConfidence,
        'totalIssues': totalIssues,
        'openIssues': openIssues,
        'resolvedIssues': resolvedIssues,
        'recordsCount': recordsCount,
        'bySeverity': bySeverity,
        'byType': byType,
        'issues': issues.map((i) => i.toJson()).toList(),
      };
}

/// Request payload for resolving an issue: PUT /validation/issues/:issueId.
class ValidationIssueUpdateRequest {
  final String status; // open | resolved | ignored
  final String? resolution;
  final String? correctedValue;
  final String? notes;

  const ValidationIssueUpdateRequest({
    this.status = 'resolved',
    this.resolution,
    this.correctedValue,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'status': status,
        if (resolution != null) 'resolution': resolution,
        if (correctedValue != null) 'correctedValue': correctedValue,
        if (notes != null) 'notes': notes,
      };
}

/// Filter query parameters for GET /validation/:documentId/issues or GET /validation.
class ValidationFilter {
  final String? documentId;
  final String? status; // open | resolved | ignored | all
  final String? severity; // info | warning | error | critical
  final String? type;
  final int page;
  final int limit;

  const ValidationFilter({
    this.documentId,
    this.status,
    this.severity,
    this.type,
    this.page = 1,
    this.limit = 50,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (documentId != null && documentId!.isNotEmpty) {
      params['documentId'] = documentId;
    }
    if (status != null && status!.isNotEmpty && status != 'all') {
      params['status'] = status;
    }
    if (severity != null && severity!.isNotEmpty) {
      params['severity'] = severity;
    }
    if (type != null && type!.isNotEmpty) {
      params['type'] = type;
    }
    return params;
  }

  ValidationFilter copyWith({
    String? documentId,
    String? status,
    String? severity,
    String? type,
    int? page,
    int? limit,
    bool clearStatus = false,
    bool clearSeverity = false,
    bool clearType = false,
  }) {
    return ValidationFilter(
      documentId: documentId ?? this.documentId,
      status: clearStatus ? null : (status ?? this.status),
      severity: clearSeverity ? null : (severity ?? this.severity),
      type: clearType ? null : (type ?? this.type),
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

/// Pagination metadata for validation issues.
class ValidationPaginationMeta {
  final int total;
  final int page;
  final int limit;
  final int pages;
  final int qualityScore;
  final Map<String, int> bySeverity;
  final Map<String, int> byType;

  const ValidationPaginationMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
    this.qualityScore = 100,
    this.bySeverity = const {},
    this.byType = const {},
  });

  factory ValidationPaginationMeta.fromJson(Map<String, dynamic> json) {
    final sev = json['bySeverity'];
    final sevMap = <String, int>{};
    if (sev is Map) {
      sev.forEach((k, v) => sevMap[k.toString()] = num.tryParse(v?.toString() ?? '')?.toInt() ?? 0);
    }

    final types = json['byType'];
    final typeMap = <String, int>{};
    if (types is Map) {
      types.forEach((k, v) => typeMap[k.toString()] = num.tryParse(v?.toString() ?? '')?.toInt() ?? 0);
    }

    return ValidationPaginationMeta(
      total: num.tryParse(json['total']?.toString() ?? '')?.toInt() ?? 0,
      page: num.tryParse(json['page']?.toString() ?? '')?.toInt() ?? 1,
      limit: num.tryParse(json['limit']?.toString() ?? '')?.toInt() ?? 50,
      pages: num.tryParse(json['pages']?.toString() ?? json['totalPages']?.toString() ?? '')?.toInt() ?? 1,
      qualityScore: num.tryParse(json['qualityScore']?.toString() ?? '')?.toInt() ?? 100,
      bySeverity: sevMap,
      byType: typeMap,
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'page': page,
        'limit': limit,
        'pages': pages,
        'qualityScore': qualityScore,
        'bySeverity': bySeverity,
        'byType': byType,
      };
}

/// Paginated validation issues payload returned by GET /validation/:documentId/issues.
class ValidationIssuesResponse {
  final List<ValidationIssueModel> issues;
  final ValidationPaginationMeta meta;

  const ValidationIssuesResponse({
    required this.issues,
    required this.meta,
  });

  factory ValidationIssuesResponse.fromJson(Map<String, dynamic> json) {
    dynamic rawList;
    Map<String, dynamic>? metaData;

    if (json['data'] is List) {
      rawList = json['data'];
      if (json['meta'] is Map<String, dynamic>) {
        metaData = json['meta'] as Map<String, dynamic>;
      }
    } else if (json['data'] is Map) {
      final inner = json['data'] as Map<String, dynamic>;
      rawList = inner['issues'] ?? inner['data'] ?? inner['results'];
      metaData = inner['meta'] as Map<String, dynamic>? ?? inner['pagination'] as Map<String, dynamic>?;
    } else if (json['issues'] is List) {
      rawList = json['issues'];
      metaData = json['meta'] as Map<String, dynamic>?;
    }

    final issues = <ValidationIssueModel>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          issues.add(ValidationIssueModel.fromJson(item));
        } else if (item is Map) {
          issues.add(ValidationIssueModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    metaData ??= {'total': issues.length, 'page': 1, 'limit': 50, 'pages': 1};

    return ValidationIssuesResponse(
      issues: issues,
      meta: ValidationPaginationMeta.fromJson(metaData),
    );
  }
}

/// Response payload for POST /validation/:documentId/approve.
class ValidationApprovalResponse {
  final String documentId;
  final String? documentName;
  final String status;
  final String approvedBy;
  final String approvedAt;
  final int recordsApproved;

  const ValidationApprovalResponse({
    required this.documentId,
    this.documentName,
    required this.status,
    required this.approvedBy,
    required this.approvedAt,
    this.recordsApproved = 0,
  });

  factory ValidationApprovalResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    final docMap = data['documentId'] is Map ? data['documentId'] as Map : null;
    return ValidationApprovalResponse(
      documentId: ValidationIssueModel.safeStr(data['documentId']) ??
          (docMap != null ? ValidationIssueModel.safeStr(docMap['_id'] ?? docMap['id']) : null) ??
          '',
      documentName: ValidationIssueModel.safeStr(data['documentName']) ??
          (docMap != null ? ValidationIssueModel.safeStr(docMap['filename'] ?? docMap['name']) : null),
      status: ValidationIssueModel.safeStr(data['status']) ?? 'approved',
      approvedBy: ValidationIssueModel.safeStr(data['approvedBy']) ?? 'admin',
      approvedAt: ValidationIssueModel.safeStr(data['approvedAt']) ?? '',
      recordsApproved: num.tryParse(data['recordsApproved']?.toString() ?? '')?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'documentName': documentName,
        'status': status,
        'approvedBy': approvedBy,
        'approvedAt': approvedAt,
        'recordsApproved': recordsApproved,
      };
}

/// Single issue resolution entry in POST /validation/:documentId/review request.
class ValidationIssueResolution {
  final String issueId;
  final String? correctedValue;
  final String status; // resolved, ignored
  final String? resolution;
  final String? notes;

  const ValidationIssueResolution({
    required this.issueId,
    this.correctedValue,
    this.status = 'resolved',
    this.resolution,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'issueId': issueId,
        if (correctedValue != null) 'correctedValue': correctedValue,
        'status': status,
        if (resolution != null) 'resolution': resolution,
        if (notes != null) 'notes': notes,
      };
}

/// Request payload for submitting review decision: POST /validation/:documentId/review.
class ValidationReviewRequest {
  final String decision; // approved | rejected | needs_correction | in_review
  final String? comments;
  final List<ValidationIssueResolution> issueResolutions;

  const ValidationReviewRequest({
    this.decision = 'approved',
    this.comments,
    this.issueResolutions = const [],
  });

  Map<String, dynamic> toJson() => {
        'decision': decision,
        if (comments != null) 'comments': comments,
        if (issueResolutions.isNotEmpty)
          'issueResolutions': issueResolutions.map((r) => r.toJson()).toList(),
      };
}

/// Response payload from submitting review: POST /validation/:documentId/review.
class ValidationReviewResponse {
  final String documentId;
  final String? documentName;
  final String status;
  final String decision;
  final String? comments;

  const ValidationReviewResponse({
    required this.documentId,
    this.documentName,
    required this.status,
    required this.decision,
    this.comments,
  });

  factory ValidationReviewResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    final docMap = data['documentId'] is Map ? data['documentId'] as Map : null;
    return ValidationReviewResponse(
      documentId: ValidationIssueModel.safeStr(data['documentId']) ??
          (docMap != null ? ValidationIssueModel.safeStr(docMap['_id'] ?? docMap['id']) : null) ??
          '',
      documentName: ValidationIssueModel.safeStr(data['documentName']) ??
          (docMap != null ? ValidationIssueModel.safeStr(docMap['filename'] ?? docMap['name']) : null),
      status: ValidationIssueModel.safeStr(data['status']) ?? 'in_review',
      decision: ValidationIssueModel.safeStr(data['decision']) ?? 'approved',
      comments: ValidationIssueModel.safeStr(data['comments']),
    );
  }

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'documentName': documentName,
        'status': status,
        'decision': decision,
        if (comments != null) 'comments': comments,
      };
}
