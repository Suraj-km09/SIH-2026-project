import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/validation_issue_model.dart';
import '../repositories/validation_repository.dart';
import 'app_state.dart';

/// Provider for ValidationRepository.
final validationRepositoryProvider = Provider<ValidationRepository>((ref) {
  return ValidationRepositoryImpl(
    mockRepository: MockValidationRepository(),
  );
});

/// Immutable state for Validation workspace.
class ValidationState {
  final ViewStatus status;
  final String? activeDocumentId;
  final ValidationSummaryModel? summary;
  final List<ValidationIssueModel> issues;
  final ValidationFilter filter;
  final ValidationPaginationMeta meta;
  final String? errorMessage;
  final String? actionMessage;
  final bool isActionLoading;

  const ValidationState({
    this.status = ViewStatus.initial,
    this.activeDocumentId,
    this.summary,
    this.issues = const [],
    this.filter = const ValidationFilter(),
    this.meta = const ValidationPaginationMeta(total: 0, page: 1, limit: 50, pages: 1),
    this.errorMessage,
    this.actionMessage,
    this.isActionLoading = false,
  });

  bool get isLoading => status == ViewStatus.loading;
  bool get isSuccess => status == ViewStatus.success;
  bool get isError => status == ViewStatus.error;
  bool get isEmpty => isSuccess && issues.isEmpty;

  ValidationState copyWith({
    ViewStatus? status,
    String? activeDocumentId,
    ValidationSummaryModel? summary,
    List<ValidationIssueModel>? issues,
    ValidationFilter? filter,
    ValidationPaginationMeta? meta,
    String? errorMessage,
    String? actionMessage,
    bool? isActionLoading,
  }) {
    return ValidationState(
      status: status ?? this.status,
      activeDocumentId: activeDocumentId ?? this.activeDocumentId,
      summary: summary ?? this.summary,
      issues: issues ?? this.issues,
      filter: filter ?? this.filter,
      meta: meta ?? this.meta,
      errorMessage: errorMessage ?? this.errorMessage,
      actionMessage: actionMessage ?? this.actionMessage,
      isActionLoading: isActionLoading ?? this.isActionLoading,
    );
  }
}

final validationNotifierProvider =
    NotifierProvider<ValidationNotifier, ValidationState>(ValidationNotifier.new);

class ValidationNotifier extends Notifier<ValidationState> {
  late final ValidationRepository _repository;

  @override
  ValidationState build() {
    _repository = ref.watch(validationRepositoryProvider);
    return const ValidationState();
  }

  Future<void> loadDocument(String documentId, {bool resetPage = false}) async {
    final currentFilter = resetPage ? state.filter.copyWith(page: 1) : state.filter;

    state = state.copyWith(
      status: ViewStatus.loading,
      activeDocumentId: documentId,
      filter: currentFilter,
      errorMessage: null,
    );

    try {
      final results = await Future.wait([
        _repository.getValidationSummary(documentId),
        _repository.getValidationIssues(documentId, currentFilter),
      ]);

      final summaryModel = results[0] as ValidationSummaryModel;
      final issuesResponse = results[1] as ValidationIssuesResponse;

      state = state.copyWith(
        status: ViewStatus.success,
        summary: summaryModel,
        issues: issuesResponse.issues,
        meta: issuesResponse.meta,
      );
    } catch (e) {
      state = state.copyWith(
        status: ViewStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> runValidation(String documentId) async {
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    try {
      await _repository.runValidation(documentId);
      state = state.copyWith(
        isActionLoading: false,
        actionMessage: 'Algorithmic validation engine executed successfully.',
      );
      await loadDocument(documentId);
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setFilter(ValidationFilter filter) {
    state = state.copyWith(filter: filter);
    if (state.activeDocumentId != null) {
      loadDocument(state.activeDocumentId!);
    }
  }

  Future<bool> resolveIssue(String issueId, ValidationIssueUpdateRequest request) async {
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    try {
      final updated = await _repository.resolveIssue(issueId, request);
      final updatedList = state.issues.map((i) => i.id == issueId ? updated : i).toList();

      state = state.copyWith(
        issues: updatedList,
        isActionLoading: false,
        actionMessage: 'Validation issue updated to ${request.status}.',
      );

      if (state.activeDocumentId != null) {
        final summary = await _repository.getValidationSummary(state.activeDocumentId!);
        state = state.copyWith(summary: summary);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> approveValidation(String documentId) async {
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    try {
      final res = await _repository.approveValidation(documentId);
      state = state.copyWith(
        isActionLoading: false,
        actionMessage: 'Document validation approved by ${res.approvedBy}.',
      );
      await loadDocument(documentId);
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> submitReview(String documentId, ValidationReviewRequest request) async {
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    try {
      final res = await _repository.submitReview(documentId, request);
      state = state.copyWith(
        isActionLoading: false,
        actionMessage: 'Review submitted with decision: ${res.decision}.',
      );
      await loadDocument(documentId);
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}
