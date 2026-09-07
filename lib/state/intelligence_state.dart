import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/intelligence_model.dart';
import '../models/topic_model.dart';
import '../repositories/intelligence_repository.dart';
import 'app_state.dart';

@immutable
class IntelligenceState {
  final ViewStatus status;
  final IntelligenceOverview? overview;
  final List<TopicTrend> trends;
  final List<IntelligenceEntity> entities;
  final String entityTypeFilter;
  final List<IntelligenceCluster> clusters;
  final IntelligenceSimilarityResult? similarity;
  final String? selectedDocForSimilarity;
  final IntelligenceChangesResponse? changes;
  final String? selectedDocA;
  final String? selectedDocB;
  final DocumentEntitiesResponse? documentEntities;
  final DocumentSimilarityResponse? documentSimilarity;
  final bool isAnalyzing;
  final bool isLinkingEvidence;
  final String? errorMessage;
  final String? actionMessage;

  const IntelligenceState({
    this.status = ViewStatus.initial,
    this.overview,
    this.trends = const [],
    this.entities = const [],
    this.entityTypeFilter = 'ALL',
    this.clusters = const [],
    this.similarity,
    this.selectedDocForSimilarity,
    this.changes,
    this.selectedDocA,
    this.selectedDocB,
    this.documentEntities,
    this.documentSimilarity,
    this.isAnalyzing = false,
    this.isLinkingEvidence = false,
    this.errorMessage,
    this.actionMessage,
  });

  bool get isLoading => status == ViewStatus.loading;

  List<IntelligenceEntity> get filteredEntities {
    if (entityTypeFilter == 'ALL' || entityTypeFilter.isEmpty) {
      return entities;
    }
    return entities
        .where((e) => e.type.toUpperCase() == entityTypeFilter.toUpperCase())
        .toList();
  }

  IntelligenceState copyWith({
    ViewStatus? status,
    IntelligenceOverview? overview,
    List<TopicTrend>? trends,
    List<IntelligenceEntity>? entities,
    String? entityTypeFilter,
    List<IntelligenceCluster>? clusters,
    IntelligenceSimilarityResult? similarity,
    String? selectedDocForSimilarity,
    IntelligenceChangesResponse? changes,
    String? selectedDocA,
    String? selectedDocB,
    DocumentEntitiesResponse? documentEntities,
    DocumentSimilarityResponse? documentSimilarity,
    bool? isAnalyzing,
    bool? isLinkingEvidence,
    String? errorMessage,
    String? actionMessage,
    bool clearError = false,
    bool clearActionMessage = false,
  }) {
    return IntelligenceState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      trends: trends ?? this.trends,
      entities: entities ?? this.entities,
      entityTypeFilter: entityTypeFilter ?? this.entityTypeFilter,
      clusters: clusters ?? this.clusters,
      similarity: similarity ?? this.similarity,
      selectedDocForSimilarity:
          selectedDocForSimilarity ?? this.selectedDocForSimilarity,
      changes: changes ?? this.changes,
      selectedDocA: selectedDocA ?? this.selectedDocA,
      selectedDocB: selectedDocB ?? this.selectedDocB,
      documentEntities: documentEntities ?? this.documentEntities,
      documentSimilarity: documentSimilarity ?? this.documentSimilarity,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isLinkingEvidence: isLinkingEvidence ?? this.isLinkingEvidence,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionMessage: clearActionMessage
          ? null
          : (actionMessage ?? this.actionMessage),
    );
  }
}

/// Provider for IntelligenceNotifier.
final intelligenceNotifierProvider =
    NotifierProvider<IntelligenceNotifier, IntelligenceState>(
        IntelligenceNotifier.new);

class IntelligenceNotifier extends Notifier<IntelligenceState> {
  late final IntelligenceRepository _repository;

  @override
  IntelligenceState build() {
    _repository = ref.watch(intelligenceRepositoryProvider);
    return const IntelligenceState();
  }

  /// Loads all intelligence data modules in parallel.
  Future<void> loadAll({String? documentId}) async {
    state = state.copyWith(status: ViewStatus.loading, clearError: true);

    try {
      final overviewFuture = _repository.getOverview(documentId: documentId);
      final trendsFuture = _repository.getTrends();
      final entitiesFuture =
          _repository.getEntities(type: state.entityTypeFilter);
      final clustersFuture = _repository.getClusters();
      final similarityFuture =
          _repository.getSimilarity(documentId: documentId);
      final changesFuture =
          _repository.getChanges(docA: state.selectedDocA, docB: state.selectedDocB);

      final results = await Future.wait([
        overviewFuture,
        trendsFuture,
        entitiesFuture,
        clustersFuture,
        similarityFuture,
        changesFuture,
      ]);

      if (!ref.mounted) return;

      state = state.copyWith(
        status: ViewStatus.success,
        overview: results[0] as IntelligenceOverview,
        trends: results[1] as List<TopicTrend>,
        entities: results[2] as List<IntelligenceEntity>,
        clusters: results[3] as List<IntelligenceCluster>,
        similarity: results[4] as IntelligenceSimilarityResult,
        changes: results[5] as IntelligenceChangesResponse,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: ViewStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Filter entities by category (ALL, MINE, LOCATION, ORGANIZATION, EQUIPMENT, FIGURE).
  Future<void> setEntityTypeFilter(String type) async {
    state = state.copyWith(entityTypeFilter: type);
    try {
      final entities = await _repository.getEntities(
        type: type == 'ALL' ? null : type,
      );
      if (!ref.mounted) return;
      state = state.copyWith(entities: entities);
    } catch (e) {
      // non-fatal, fallback to local filtering
    }
  }

  /// Request similarity analysis for a specific target document.
  Future<void> selectDocumentForSimilarity(String docId) async {
    state = state.copyWith(selectedDocForSimilarity: docId);
    try {
      final sim = await _repository.getSimilarity(documentId: docId);
      if (!ref.mounted) return;
      state = state.copyWith(similarity: sim);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Request parameter variance differences between two document IDs.
  Future<void> compareDocuments({required String docA, required String docB}) async {
    state = state.copyWith(selectedDocA: docA, selectedDocB: docB);
    try {
      final changes = await _repository.getChanges(docA: docA, docB: docB);
      if (!ref.mounted) return;
      state = state.copyWith(changes: changes);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Trigger multi-faceted intelligence extraction (POST /intelligence/analyze).
  /// Guarded against accidental concurrent duplicate requests.
  Future<void> analyzeDocument({String? documentId, List<String>? documentIds}) async {
    if (state.isAnalyzing) return;

    state = state.copyWith(
      isAnalyzing: true,
      clearError: true,
      clearActionMessage: true,
    );

    try {
      final result = await _repository.analyze(
        documentId: documentId,
        documentIds: documentIds,
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        isAnalyzing: false,
        actionMessage:
            'Intelligence analysis completed: ${result.entitiesExtracted} entities, ${result.topicsExtracted} topics discovered.',
      );
      // Refresh overview and clusters after analysis
      await loadAll(documentId: documentId);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: 'Analysis failed: $e',
      );
    }
  }

  /// Trigger bidirectional citation linking (POST /intelligence/link-evidence/:id).
  /// Guarded against accidental concurrent duplicate requests.
  Future<void> linkEvidence(String documentId) async {
    if (state.isLinkingEvidence) return;

    state = state.copyWith(
      isLinkingEvidence: true,
      clearError: true,
      clearActionMessage: true,
    );

    try {
      final result = await _repository.linkEvidence(documentId);
      if (!ref.mounted) return;
      state = state.copyWith(
        isLinkingEvidence: false,
        actionMessage: result.linked
            ? 'Evidence linked successfully: ${result.linksCount} bidirectional citation links established.'
            : 'Evidence linking concluded with no new citations.',
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLinkingEvidence: false,
        errorMessage: 'Evidence linking failed: $e',
      );
    }
  }

  /// Fetch document-specific entities (GET /intelligence/entities/:id)
  Future<void> loadDocumentEntities(String documentId) async {
    try {
      final docEntities = await _repository.getDocumentEntities(documentId);
      if (!ref.mounted) return;
      state = state.copyWith(documentEntities: docEntities);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Fetch document-specific similarity (GET /intelligence/similarity/:id)
  Future<void> loadDocumentSimilarity(String documentId) async {
    try {
      final docSim = await _repository.getDocumentSimilarity(documentId);
      if (!ref.mounted) return;
      state = state.copyWith(documentSimilarity: docSim);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearActionMessage: true);
  }
}
