import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/extracted_record_model.dart';
import '../repositories/extraction_repository.dart';
import 'app_state.dart';

/// Provider for ExtractionRepository.
final extractionRepositoryProvider = Provider<ExtractionRepository>((ref) {
  return ExtractionRepositoryImpl(
    mockRepository: MockExtractionRepository(),
  );
});

/// Immutable state for Extraction workspace.
class ExtractionState {
  final ViewStatus status;
  final String? activeDocumentId;
  final ExtractionSummaryStats? summary;
  final List<ExtractedRecordModel> records;
  final Set<String> selectedRecordIds;
  final ExtractionFilter filter;
  final ExtractionRecordsPaginationMeta meta;
  final String? errorMessage;
  final String? actionMessage;
  final bool isActionLoading;

  const ExtractionState({
    this.status = ViewStatus.initial,
    this.activeDocumentId,
    this.summary,
    this.records = const [],
    this.selectedRecordIds = const {},
    this.filter = const ExtractionFilter(),
    this.meta = const ExtractionRecordsPaginationMeta(total: 0, page: 1, limit: 50, pages: 1),
    this.errorMessage,
    this.actionMessage,
    this.isActionLoading = false,
  });

  bool get isLoading => status == ViewStatus.loading;
  bool get isSuccess => status == ViewStatus.success;
  bool get isError => status == ViewStatus.error;
  bool get isEmpty => isSuccess && records.isEmpty;

  ExtractionState copyWith({
    ViewStatus? status,
    String? activeDocumentId,
    ExtractionSummaryStats? summary,
    List<ExtractedRecordModel>? records,
    Set<String>? selectedRecordIds,
    ExtractionFilter? filter,
    ExtractionRecordsPaginationMeta? meta,
    String? errorMessage,
    String? actionMessage,
    bool? isActionLoading,
  }) {
    return ExtractionState(
      status: status ?? this.status,
      activeDocumentId: activeDocumentId ?? this.activeDocumentId,
      summary: summary ?? this.summary,
      records: records ?? this.records,
      selectedRecordIds: selectedRecordIds ?? this.selectedRecordIds,
      filter: filter ?? this.filter,
      meta: meta ?? this.meta,
      errorMessage: errorMessage ?? this.errorMessage,
      actionMessage: actionMessage ?? this.actionMessage,
      isActionLoading: isActionLoading ?? this.isActionLoading,
    );
  }
}

final extractionNotifierProvider =
    NotifierProvider<ExtractionNotifier, ExtractionState>(ExtractionNotifier.new);

class ExtractionNotifier extends Notifier<ExtractionState> {
  late final ExtractionRepository _repository;

  @override
  ExtractionState build() {
    _repository = ref.watch(extractionRepositoryProvider);
    return const ExtractionState();
  }

  Future<void> loadDocument(String documentId, {bool resetPage = false}) async {
    final currentFilter = resetPage ? state.filter.copyWith(page: 1) : state.filter;

    state = state.copyWith(
      status: ViewStatus.loading,
      activeDocumentId: documentId,
      filter: currentFilter,
      errorMessage: null,
      selectedRecordIds: const {},
    );

    try {
      final results = await Future.wait([
        _repository.getExtractionSummary(documentId),
        _repository.getExtractionRecords(documentId, currentFilter),
      ]);

      final summaryModel = results[0] as ExtractionSummaryModel;
      final recordsResponse = results[1] as ExtractionRecordsResponse;

      state = state.copyWith(
        status: ViewStatus.success,
        summary: summaryModel.summary,
        records: recordsResponse.records,
        meta: recordsResponse.meta,
      );
    } catch (e) {
      state = state.copyWith(
        status: ViewStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> runExtraction(String documentId) async {
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    try {
      await _repository.runExtraction(documentId);
      state = state.copyWith(
        isActionLoading: false,
        actionMessage: 'Extraction pipeline completed successfully.',
      );
      await loadDocument(documentId);
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setFilter(ExtractionFilter filter) {
    state = state.copyWith(filter: filter);
    if (state.activeDocumentId != null) {
      loadDocument(state.activeDocumentId!);
    }
  }

  void toggleRecordSelection(String id) {
    final current = Set<String>.from(state.selectedRecordIds);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    state = state.copyWith(selectedRecordIds: current);
  }

  void selectAllRecords() {
    final allIds = state.records.map((r) => r.id).toSet();
    state = state.copyWith(selectedRecordIds: allIds);
  }

  void clearSelection() {
    state = state.copyWith(selectedRecordIds: const {});
  }

  Future<bool> updateRecord(String recordId, ExtractedRecordUpdateRequest request) async {
    if (state.activeDocumentId == null) return false;
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    try {
      final updated = await _repository.updateExtractionRecord(
        state.activeDocumentId!,
        recordId,
        request,
      );

      final updatedList = state.records.map((r) => r.id == recordId ? updated : r).toList();
      state = state.copyWith(
        records: updatedList,
        isActionLoading: false,
        actionMessage: 'Record updated successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> approveRecord(String recordId) async {
    try {
      final updated = await _repository.approveRecord(recordId);
      final updatedList = state.records.map((r) => r.id == recordId ? updated : r).toList();
      state = state.copyWith(records: updatedList);
      if (state.activeDocumentId != null) {
        final summary = await _repository.getExtractionSummary(state.activeDocumentId!);
        state = state.copyWith(summary: summary.summary);
      }
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> rejectRecord(String recordId) async {
    try {
      final updated = await _repository.rejectRecord(recordId);
      final updatedList = state.records.map((r) => r.id == recordId ? updated : r).toList();
      state = state.copyWith(records: updatedList);
      if (state.activeDocumentId != null) {
        final summary = await _repository.getExtractionSummary(state.activeDocumentId!);
        state = state.copyWith(summary: summary.summary);
      }
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> bulkApprove() async {
    if (state.selectedRecordIds.isEmpty) return false;
    state = state.copyWith(isActionLoading: true, errorMessage: null);

    try {
      final res = await _repository.bulkApproveRecords(state.selectedRecordIds.toList());
      final updatedList = state.records.map((r) {
        if (state.selectedRecordIds.contains(r.id)) {
          return r.copyWith(status: 'approved');
        }
        return r;
      }).toList();

      state = state.copyWith(
        records: updatedList,
        selectedRecordIds: const {},
        isActionLoading: false,
        actionMessage: '${res.modifiedCount} records approved successfully.',
      );

      if (state.activeDocumentId != null) {
        final summary = await _repository.getExtractionSummary(state.activeDocumentId!);
        state = state.copyWith(summary: summary.summary);
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
}
