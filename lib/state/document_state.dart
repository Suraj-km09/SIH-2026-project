import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/failures.dart';
import '../models/document_model.dart';
import '../repositories/document_repository.dart';
import 'app_state.dart';

/// Provider for DocumentRepository.
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepositoryImpl(
    mockRepository: MockDocumentRepository(),
  );
});

// ============================================================================
// 1. DOCUMENT LIST STATE & NOTIFIER
// ============================================================================

/// Immutable state for Document List.
class DocumentListState {
  final ViewStatus status;
  final List<DocumentModel> documents;
  final DocumentPaginationMeta meta;
  final DocumentFilter filter;
  final String? errorMessage;
  final bool isActionLoading;

  const DocumentListState({
    this.status = ViewStatus.initial,
    this.documents = const [],
    this.meta = const DocumentPaginationMeta(total: 0, page: 1, limit: 20, pages: 1),
    this.filter = const DocumentFilter(),
    this.errorMessage,
    this.isActionLoading = false,
  });

  bool get isLoading => status == ViewStatus.loading;
  bool get isSuccess => status == ViewStatus.success;
  bool get isError => status == ViewStatus.error;
  bool get isEmpty => isSuccess && documents.isEmpty;

  DocumentListState copyWith({
    ViewStatus? status,
    List<DocumentModel>? documents,
    DocumentPaginationMeta? meta,
    DocumentFilter? filter,
    String? errorMessage,
    bool? isActionLoading,
  }) {
    return DocumentListState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      meta: meta ?? this.meta,
      filter: filter ?? this.filter,
      errorMessage: errorMessage ?? this.errorMessage,
      isActionLoading: isActionLoading ?? this.isActionLoading,
    );
  }
}

final documentListNotifierProvider =
    NotifierProvider<DocumentListNotifier, DocumentListState>(DocumentListNotifier.new);

class DocumentListNotifier extends Notifier<DocumentListState> {
  late final DocumentRepository _repository;

  @override
  DocumentListState build() {
    _repository = ref.watch(documentRepositoryProvider);
    return const DocumentListState();
  }

  Future<void> loadDocuments({bool resetPage = false}) async {
    final currentFilter = resetPage ? state.filter.copyWith(page: 1) : state.filter;
    state = state.copyWith(
      status: ViewStatus.loading,
      filter: currentFilter,
      errorMessage: null,
    );

    try {
      final response = await _repository.getDocuments(currentFilter);
      state = state.copyWith(
        status: ViewStatus.success,
        documents: response.documents,
        meta: response.meta,
      );
    } catch (e) {
      state = state.copyWith(
        status: ViewStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void setSearch(String? search) {
    state = state.copyWith(
      filter: state.filter.copyWith(search: search, page: 1),
    );
    loadDocuments();
  }

  void setType(String? type) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        type: type,
        clearType: type == null || type.isEmpty,
        page: 1,
      ),
    );
    loadDocuments();
  }

  void setStatus(String? status) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        status: status,
        clearStatus: status == null || status.isEmpty,
        page: 1,
      ),
    );
    loadDocuments();
  }

  void setCategory(String? category) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        category: category,
        clearCategory: category == null || category.isEmpty,
        page: 1,
      ),
    );
    loadDocuments();
  }

  void setClassification(String? classification) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        classification: classification,
        clearClassification: classification == null || classification.isEmpty,
        page: 1,
      ),
    );
    loadDocuments();
  }

  void clearFilters() {
    state = state.copyWith(
      filter: const DocumentFilter(),
    );
    loadDocuments();
  }

  void setPage(int page) {
    if (page < 1 || page > state.meta.pages) return;
    state = state.copyWith(
      filter: state.filter.copyWith(page: page),
    );
    loadDocuments();
  }

  Future<bool> deleteDocument(String id) async {
    state = state.copyWith(isActionLoading: true);
    try {
      await _repository.deleteDocument(id);
      final updatedList = state.documents.where((d) => d.id != id).toList();
      state = state.copyWith(
        documents: updatedList,
        meta: DocumentPaginationMeta(
          total: (state.meta.total - 1).clamp(0, 99999),
          page: state.meta.page,
          limit: state.meta.limit,
          pages: state.meta.pages,
        ),
        isActionLoading: false,
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

  Future<void> refresh() async {
    await loadDocuments();
  }
}

// ============================================================================
// 2. DOCUMENT DETAIL STATE & NOTIFIER
// ============================================================================

/// Immutable state for Document Detail & OCR viewer.
class DocumentDetailState {
  final ViewStatus status;
  final DocumentDetailModel? detail;
  final DocumentMetadataModel? metadata;
  final DocumentStatusModel? processingStatus;
  final String? errorMessage;
  final String? actionMessage;
  final bool isActionLoading;

  const DocumentDetailState({
    this.status = ViewStatus.initial,
    this.detail,
    this.metadata,
    this.processingStatus,
    this.errorMessage,
    this.actionMessage,
    this.isActionLoading = false,
  });

  bool get isLoading => status == ViewStatus.loading;
  bool get isSuccess => status == ViewStatus.success;
  bool get isError => status == ViewStatus.error;

  DocumentDetailState copyWith({
    ViewStatus? status,
    DocumentDetailModel? detail,
    DocumentMetadataModel? metadata,
    DocumentStatusModel? processingStatus,
    String? errorMessage,
    String? actionMessage,
    bool? isActionLoading,
  }) {
    return DocumentDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      metadata: metadata ?? this.metadata,
      processingStatus: processingStatus ?? this.processingStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      actionMessage: actionMessage ?? this.actionMessage,
      isActionLoading: isActionLoading ?? this.isActionLoading,
    );
  }
}

final documentDetailNotifierProvider =
    NotifierProvider<DocumentDetailNotifier, DocumentDetailState>(DocumentDetailNotifier.new);

class DocumentDetailNotifier extends Notifier<DocumentDetailState> {
  late final DocumentRepository _repository;

  @override
  DocumentDetailState build() {
    _repository = ref.watch(documentRepositoryProvider);
    return const DocumentDetailState();
  }

  Future<void> loadDocument(String id) async {
    state = state.copyWith(status: ViewStatus.loading, errorMessage: null);

    try {
      final results = await Future.wait([
        _repository.getDocumentDetail(id),
        _repository.getDocumentMetadata(id),
        _repository.getDocumentStatus(id),
      ]);

      final detail = results[0] as DocumentDetailModel;
      final metadata = results[1] as DocumentMetadataModel;
      final processingStatus = results[2] as DocumentStatusModel;

      state = state.copyWith(
        status: ViewStatus.success,
        detail: detail,
        metadata: metadata,
        processingStatus: processingStatus,
      );

      // If document is in processing state, trigger safe polling via processing notifier
      if (processingStatus.isProcessing) {
        ref.read(documentProcessingNotifierProvider.notifier).startPolling(id);
      }
    } catch (e) {
      state = state.copyWith(
        status: ViewStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> updateMetadata(String id, DocumentMetadataUpdateRequest request) async {
    state = state.copyWith(isActionLoading: true, errorMessage: null);
    try {
      final updatedDoc = await _repository.updateDocumentMetadata(id, request);
      if (state.detail != null) {
        state = state.copyWith(
          detail: DocumentDetailModel(
            document: updatedDoc,
            pages: state.detail!.pages,
          ),
          actionMessage: 'Document metadata updated successfully.',
          isActionLoading: false,
        );
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

  Future<bool> reprocess(String id) async {
    state = state.copyWith(isActionLoading: true, errorMessage: null);
    try {
      final updatedDoc = await _repository.reprocessDocument(id);
      if (state.detail != null) {
        state = state.copyWith(
          detail: DocumentDetailModel(
            document: updatedDoc,
            pages: state.detail!.pages,
          ),
          actionMessage: 'Reprocessing queued.',
          isActionLoading: false,
        );
      }
      // Start polling status
      ref.read(documentProcessingNotifierProvider.notifier).startPolling(id);
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> retry(String id) async {
    return reprocess(id);
  }

  void updateProcessingStatus(DocumentStatusModel status) {
    state = state.copyWith(processingStatus: status);
    if (state.detail != null) {
      state = state.copyWith(
        detail: DocumentDetailModel(
          document: state.detail!.document.copyWith(status: status.status),
          pages: state.detail!.pages,
        ),
      );
    }
  }
}

// ============================================================================
// 3. DOCUMENT PROCESSING & POLLING STATE & NOTIFIER
// ============================================================================

/// Immutable state for Ingestion Jobs and File Upload progress.
class DocumentProcessingState {
  final Map<String, DocumentStatusModel> statuses;
  final Set<String> activePollingIds;
  final double uploadProgress; // 0.0 to 1.0
  final bool isUploading;
  final bool isDuplicateConflict;
  final String? conflictMessage;
  final String? errorMessage;
  final DocumentModel? lastUploadedDocument;

  const DocumentProcessingState({
    this.statuses = const {},
    this.activePollingIds = const {},
    this.uploadProgress = 0.0,
    this.isUploading = false,
    this.isDuplicateConflict = false,
    this.conflictMessage,
    this.errorMessage,
    this.lastUploadedDocument,
  });

  bool isPolling(String id) => activePollingIds.contains(id);

  DocumentProcessingState copyWith({
    Map<String, DocumentStatusModel>? statuses,
    Set<String>? activePollingIds,
    double? uploadProgress,
    bool? isUploading,
    bool? isDuplicateConflict,
    String? conflictMessage,
    String? errorMessage,
    DocumentModel? lastUploadedDocument,
    bool clearConflict = false,
    bool clearError = false,
  }) {
    return DocumentProcessingState(
      statuses: statuses ?? this.statuses,
      activePollingIds: activePollingIds ?? this.activePollingIds,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isUploading: isUploading ?? this.isUploading,
      isDuplicateConflict: clearConflict ? false : (isDuplicateConflict ?? this.isDuplicateConflict),
      conflictMessage: clearConflict ? null : (conflictMessage ?? this.conflictMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUploadedDocument: lastUploadedDocument ?? this.lastUploadedDocument,
    );
  }
}

final documentProcessingNotifierProvider =
    NotifierProvider<DocumentProcessingNotifier, DocumentProcessingState>(
        DocumentProcessingNotifier.new);

class DocumentProcessingNotifier extends Notifier<DocumentProcessingState> {
  late final DocumentRepository _repository;
  final Map<String, Timer> _activeTimers = {};

  @override
  DocumentProcessingState build() {
    _repository = ref.watch(documentRepositoryProvider);

    // Guarantee safe cleanup of any active polling timers upon notifier disposal
    ref.onDispose(_cancelTimers);

    return const DocumentProcessingState();
  }

  /// Upload document with 50MB check, format check, progress tracking, and 409 conflict handling.
  Future<DocumentModel?> uploadDocument(File file) async {
    // 1. Client-side format validation
    final fileName = file.path.split(Platform.pathSeparator).last;
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    if (!AppConstants.supportedDocumentExtensions.contains(ext)) {
      state = state.copyWith(
        errorMessage:
            'Unsupported file format (.$ext). Supported: ${AppConstants.supportedDocumentExtensions.join(', ')}',
        clearConflict: true,
      );
      return null;
    }

    // 2. Client-side 50 MB limit validation
    final fileSize = await file.length();
    if (fileSize > DocumentRepositoryImpl.maxFileSizeBytes) {
      state = state.copyWith(
        errorMessage:
            'File size exceeds the 50 MB limit (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB).',
        clearConflict: true,
      );
      return null;
    }

    state = state.copyWith(
      isUploading: true,
      uploadProgress: 0.0,
      clearConflict: true,
      clearError: true,
    );

    try {
      final doc = await _repository.uploadDocument(
        file,
        onSendProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(uploadProgress: sent / total);
          }
        },
      );

      state = state.copyWith(
        isUploading: false,
        uploadProgress: 1.0,
        lastUploadedDocument: doc,
      );

      // Refresh document list
      ref.read(documentListNotifierProvider.notifier).loadDocuments();

      // Start controlled polling if document is queued or processing
      if (doc.isProcessing) {
        startPolling(doc.id);
      }

      return doc;
    } on ConflictFailure catch (e) {
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        isDuplicateConflict: true,
        conflictMessage: e.message,
      );
      return null;
    } catch (e) {
      final message = e is Failure ? e.message : e.toString();
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        errorMessage: message,
      );
      return null;
    }
  }

  /// Start polling status approximately every 2–3 seconds.
  /// Rules:
  /// 1. NEVER poll from widget rebuilds (guaranteed by explicit invocation).
  /// 2. Stop immediately on terminal state (completed or failed).
  /// 3. Prevent duplicate polling.
  Future<void> startPolling(
    String documentId, {
    Duration interval = const Duration(seconds: 3),
  }) async {
    // Prevent duplicate polling for the same document
    if (_activeTimers.containsKey(documentId)) {
      return;
    }

    final newActive = Set<String>.from(state.activePollingIds)..add(documentId);
    state = state.copyWith(activePollingIds: newActive);

    // Initial immediate fetch before starting periodic timer
    try {
      final status = await _repository.getDocumentStatus(documentId);
      final newStatuses = Map<String, DocumentStatusModel>.from(state.statuses)..[documentId] = status;
      state = state.copyWith(statuses: newStatuses);

      // Inform detail notifier if active
      ref.read(documentDetailNotifierProvider.notifier).updateProcessingStatus(status);

      // If already terminal state, STOP IMMEDIATELY and do NOT start timer!
      if (status.isTerminal) {
        stopPolling(documentId);
        ref.read(documentListNotifierProvider.notifier).loadDocuments();
        return;
      }
    } catch (_) {
      stopPolling(documentId);
      return;
    }

    // Start 2–3s periodic polling timer
    _activeTimers[documentId] = Timer.periodic(interval, (_) async {
      try {
        final status = await _repository.getDocumentStatus(documentId);
        final newStatuses = Map<String, DocumentStatusModel>.from(state.statuses)..[documentId] = status;
        state = state.copyWith(statuses: newStatuses);

        ref.read(documentDetailNotifierProvider.notifier).updateProcessingStatus(status);

        // STOP IMMEDIATELY ON TERMINAL STATE!
        if (status.isTerminal) {
          stopPolling(documentId);
          ref.read(documentListNotifierProvider.notifier).loadDocuments();
        }
      } catch (_) {
        stopPolling(documentId);
      }
    });
  }

  /// Stop polling for a specific document and release its timer.
  void stopPolling(String documentId) {
    _activeTimers[documentId]?.cancel();
    _activeTimers.remove(documentId);

    if (state.activePollingIds.contains(documentId)) {
      final newActive = Set<String>.from(state.activePollingIds)..remove(documentId);
      state = state.copyWith(activePollingIds: newActive);
    }
  }

  void _cancelTimers() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
  }

  /// Stop all active polling timers (e.g. on screen exit or logout).
  void stopAllPolling() {
    _cancelTimers();
    state = state.copyWith(activePollingIds: const {});
  }

  void clearConflict() {
    state = state.copyWith(clearConflict: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
