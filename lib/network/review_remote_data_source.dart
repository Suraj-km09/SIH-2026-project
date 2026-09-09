import '../core/constants/api_endpoints.dart';
import '../models/report_model.dart';
import 'api_client.dart';

/// Remote data source for Review Governance APIs: /api/v1/reviews.
class ReviewRemoteDataSource {
  final ApiClient _apiClient;

  ReviewRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// GET /api/v1/reviews/pending
  Future<List<ReviewItemModel>> getPendingReviews() async {
    final response = await _apiClient.dio.get(ApiEndpoints.reviewsPending);
    final raw = response.data['data'] ?? response.data;
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => ReviewItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  /// GET /api/v1/reviews/:id
  Future<ReviewItemModel> getReviewById(String id) async {
    final response = await _apiClient.dio.get(ApiEndpoints.reviewDetail(id));
    final data = response.data['data'] ?? response.data;
    final map = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data as Map);
    return ReviewItemModel.fromJson(map);
  }

  /// POST /api/v1/reviews/:id/approve (Admin only)
  Future<ReportModel> approveReview(String id) async {
    final response = await _apiClient.dio.post(ApiEndpoints.reviewApprove(id));
    final data = response.data['data'] ?? response.data;
    final map = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data as Map);
    return ReportModel.fromJson(map);
  }

  /// POST /api/v1/reviews/:id/reject (Reviewer/Admin)
  Future<ReportModel> rejectReview(String id, String reason) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.reviewReject(id),
      data: {'reason': reason},
    );
    final data = response.data['data'] ?? response.data;
    final map = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data as Map);
    return ReportModel.fromJson(map);
  }
}
