import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_model.dart';
import '../repositories/review_repository.dart';
import 'app_state.dart';
import 'report_state.dart';

/// Provider for ReviewRepository.
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final reportRepo = ref.watch(reportRepositoryProvider);
  return ReviewRepositoryImpl(
    mockRepository: MockReviewRepository(reportRepository: reportRepo),
  );
});

class ReviewQueueState {
  final ViewStatus status;
  final List<ReviewItemModel> items;
  final ReviewItemModel? activeItem;
  final String? errorMessage;
  final String? actionMessage;
  final bool isActionLoading;

  const ReviewQueueState({
    this.status = ViewStatus.initial,
    this.items = const [],
    this.activeItem,
    this.errorMessage,
    this.actionMessage,
    this.isActionLoading = false,
  });

  bool get isLoading => status == ViewStatus.loading;
  bool get isSuccess => status == ViewStatus.success;
  bool get isError => status == ViewStatus.error;
  bool get isEmpty => isSuccess && items.isEmpty;

  ReviewQueueState copyWith({
    ViewStatus? status,
    List<ReviewItemModel>? items,
    ReviewItemModel? activeItem,
    String? errorMessage,
    String? actionMessage,
    bool? isActionLoading,
  }) {
    return ReviewQueueState(
      status: status ?? this.status,
      items: items ?? this.items,
      activeItem: activeItem ?? this.activeItem,
      errorMessage: errorMessage ?? this.errorMessage,
      actionMessage: actionMessage ?? this.actionMessage,
      isActionLoading: isActionLoading ?? this.isActionLoading,
    );
  }
}

final reviewQueueNotifierProvider =
    NotifierProvider<ReviewQueueNotifier, ReviewQueueState>(ReviewQueueNotifier.new);

class ReviewQueueNotifier extends Notifier<ReviewQueueState> {
  late final ReviewRepository _repository;

  @override
  ReviewQueueState build() {
    _repository = ref.watch(reviewRepositoryProvider);
    return const ReviewQueueState();
  }

  Future<void> loadPendingReviews() async {
    state = state.copyWith(status: ViewStatus.loading, errorMessage: null);

    try {
      final items = await _repository.getPendingReviews();
      if (!ref.mounted) return;
      state = state.copyWith(
        status: ViewStatus.success,
        items: items,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: ViewStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadReview(String id) async {
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    try {
      final item = await _repository.getReviewById(id);
      if (!ref.mounted) return;
      state = state.copyWith(
        activeItem: item,
        isActionLoading: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> approveReview(String id) async {
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    try {
      await _repository.approveReview(id);
      if (!ref.mounted) return true;
      final updatedList = state.items.where((i) => i.id != id && i.reportId != id).toList();
      state = state.copyWith(
        items: updatedList,
        isActionLoading: false,
        actionMessage: 'Report successfully approved and published.',
      );
      // Synchronize reports list
      ref.read(reportListNotifierProvider.notifier).loadReports();
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> rejectReview(String id, String reason) async {
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    try {
      await _repository.rejectReview(id, reason);
      if (!ref.mounted) return true;
      final updatedList = state.items.where((i) => i.id != id && i.reportId != id).toList();
      state = state.copyWith(
        items: updatedList,
        isActionLoading: false,
        actionMessage: 'Report rejected and returned to author with feedback.',
      );
      // Synchronize reports list
      ref.read(reportListNotifierProvider.notifier).loadReports();
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}
