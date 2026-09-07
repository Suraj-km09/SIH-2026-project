import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/knowledge_base_model.dart';
import '../repositories/knowledge_base_repository.dart';
import 'app_state.dart';

@immutable
class KnowledgeBaseState {
  final ViewStatus status;
  final List<KnowledgeBaseDocumentModel> documents;
  final KnowledgeBaseMeta meta;
  final KnowledgeBaseFilter filter;
  final Set<String> indexingDocIds;
  final KnowledgeBaseDetailModel? activeDetail;
  final bool isDetailLoading;
  final List<KnowledgeBaseSearchResult> searchResults;
  final bool isSearching;
  final String? lastSearchQuery;
  final String? errorMessage;
  final String? actionMessage;

  const KnowledgeBaseState({
    this.status = ViewStatus.initial,
    this.documents = const [],
    this.meta = const KnowledgeBaseMeta(
      total: 0,
      page: 1,
      limit: 20,
      pages: 1,
      totalIndexedDocuments: 0,
      totalVectorChunks: 0,
    ),
    this.filter = const KnowledgeBaseFilter(),
    this.indexingDocIds = const {},
    this.activeDetail,
    this.isDetailLoading = false,
    this.searchResults = const [],
    this.isSearching = false,
    this.lastSearchQuery,
    this.errorMessage,
    this.actionMessage,
  });

  bool get isLoading => status == ViewStatus.loading;
  bool isIndexing(String documentId) => indexingDocIds.contains(documentId);

  KnowledgeBaseState copyWith({
    ViewStatus? status,
    List<KnowledgeBaseDocumentModel>? documents,
    KnowledgeBaseMeta? meta,
    KnowledgeBaseFilter? filter,
    Set<String>? indexingDocIds,
    KnowledgeBaseDetailModel? activeDetail,
    bool? isDetailLoading,
    List<KnowledgeBaseSearchResult>? searchResults,
    bool? isSearching,
    String? lastSearchQuery,
    String? errorMessage,
    String? actionMessage,
    bool clearDetail = false,
    bool clearError = false,
    bool clearAction = false,
  }) {
    return KnowledgeBaseState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      meta: meta ?? this.meta,
      filter: filter ?? this.filter,
      indexingDocIds: indexingDocIds ?? this.indexingDocIds,
      activeDetail: clearDetail ? null : (activeDetail ?? this.activeDetail),
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      lastSearchQuery: lastSearchQuery ?? this.lastSearchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionMessage: clearAction ? null : (actionMessage ?? this.actionMessage),
    );
  }
}

/// Provider for KnowledgeBaseNotifier.
final knowledgeBaseNotifierProvider =
    NotifierProvider<KnowledgeBaseNotifier, KnowledgeBaseState>(KnowledgeBaseNotifier.new);

class KnowledgeBaseNotifier extends Notifier<KnowledgeBaseState> {
  late final KnowledgeBaseRepository _repository;

  @override
  KnowledgeBaseState build() {
    _repository = ref.watch(knowledgeBaseRepositoryProvider);
    return const KnowledgeBaseState();
  }

  /// Loads documents directory with vector indexing status.
  Future<void> loadDocuments({bool resetPage = false}) async {
    final effectiveFilter = resetPage ? state.filter.copyWith(page: 1) : state.filter;
    state = state.copyWith(
      status: ViewStatus.loading,
      filter: effectiveFilter,
      clearError: true,
    );

    try {
      final response = await _repository.getKnowledgeBase(effectiveFilter);
      if (!ref.mounted) return;
      state = state.copyWith(
        status: ViewStatus.success,
        documents: response.documents,
        meta: response.meta,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: ViewStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Updates filtering query parameters.
  void setFilter(KnowledgeBaseFilter filter) {
    state = state.copyWith(filter: filter);
    loadDocuments(resetPage: true);
  }

  /// Triggers document chunking and vector embedding generation.
  /// Prevents accidental repeated indexing requests for the same document.
  Future<bool> indexDocument(String documentId) async {
    if (state.isIndexing(documentId)) return false;

    // Concurrency lock for this document
    final newIndexing = Set<String>.from(state.indexingDocIds)..add(documentId);
    state = state.copyWith(indexingDocIds: newIndexing, clearError: true);

    try {
      final result = await _repository.indexDocument(documentId);
      if (!ref.mounted) return true;

      // Update document item in current state
      final updatedDocs = state.documents.map((d) {
        if (d.id == documentId) {
          return d.copyWith(
            isIndexed: true,
            chunksCount: result.chunksIndexed,
            lastIndexedAt: result.indexedAt,
          );
        }
        return d;
      }).toList();

      final updatedIndexing = Set<String>.from(state.indexingDocIds)..remove(documentId);
      final newIndexedCount = state.meta.totalIndexedDocuments +
          (state.documents.any((d) => d.id == documentId && !d.isIndexed) ? 1 : 0);
      final newChunkCount = state.meta.totalVectorChunks + result.chunksIndexed;

      state = state.copyWith(
        documents: updatedDocs,
        indexingDocIds: updatedIndexing,
        meta: KnowledgeBaseMeta(
          total: state.meta.total,
          page: state.meta.page,
          limit: state.meta.limit,
          pages: state.meta.pages,
          totalIndexedDocuments: newIndexedCount,
          totalVectorChunks: newChunkCount,
        ),
        actionMessage: 'Document "${result.documentName ?? documentId}" indexed (${result.chunksIndexed} chunks).',
      );
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      final updatedIndexing = Set<String>.from(state.indexingDocIds)..remove(documentId);
      state = state.copyWith(
        indexingDocIds: updatedIndexing,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Removes document chunks from vector index.
  Future<bool> deleteDocumentIndex(String documentId) async {
    state = state.copyWith(clearError: true);

    try {
      await _repository.deleteDocumentIndex(documentId);
      if (!ref.mounted) return true;

      final updatedDocs = state.documents.map((d) {
        if (d.id == documentId) {
          return d.copyWith(
            isIndexed: false,
            chunksCount: 0,
            lastIndexedAt: null,
          );
        }
        return d;
      }).toList();

      state = state.copyWith(
        documents: updatedDocs,
        actionMessage: 'Vector index deleted for document $documentId.',
      );
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Inspects vector chunks for a specific document.
  Future<void> loadDocumentChunks(String documentId) async {
    state = state.copyWith(isDetailLoading: true, clearDetail: true, clearError: true);

    try {
      final detail = await _repository.getDocumentChunks(documentId);
      if (!ref.mounted) return;
      state = state.copyWith(
        activeDetail: detail,
        isDetailLoading: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isDetailLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Performs semantic RAG search across indexed document chunks.
  Future<void> performSemanticSearch(
    String query, {
    int topK = 5,
    Map<String, dynamic>? filters,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return;

    state = state.copyWith(
      isSearching: true,
      lastSearchQuery: q,
      clearError: true,
    );

    try {
      final response = await _repository.search(q, topK: topK, filters: filters);
      if (!ref.mounted) return;
      state = state.copyWith(
        searchResults: response.results,
        isSearching: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isSearching: false,
        errorMessage: e.toString(),
      );
    }
  }

  void clearSearch() {
    state = state.copyWith(
      searchResults: const [],
      lastSearchQuery: null,
      isSearching: false,
    );
  }
}
