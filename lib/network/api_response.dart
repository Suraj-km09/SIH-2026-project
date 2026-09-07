/// Standard API Response Envelope matching backend Express format.
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;
  final PaginationMeta? meta;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.meta,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message'] as String?,
      error: json['error'] as String?,
      meta: json['meta'] != null
          ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : (json['pagination'] != null
              ? PaginationMeta.fromJson(json['pagination'] as Map<String, dynamic>)
              : null),
    );
  }
}

/// Standard Pagination Metadata.
class PaginationMeta {
  final int total;
  final int page;
  final int limit;
  final int pages;

  const PaginationMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
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
