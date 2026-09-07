import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/topic_model.dart';
import '../repositories/topic_repository.dart';
import 'app_state.dart';

@immutable
class TopicState {
  final ViewStatus status;
  final List<TopicModel> topics;
  final String searchQuery;
  final List<TopicTrend> trends;
  final List<TopicCluster> clusters;
  final List<TopicEntityAssociation> entities;
  final List<EmergingTopic> emerging;
  final List<TopicChange> changes;
  final bool isAnalyzing;
  final String? errorMessage;
  final String? actionMessage;

  const TopicState({
    this.status = ViewStatus.initial,
    this.topics = const [],
    this.searchQuery = '',
    this.trends = const [],
    this.clusters = const [],
    this.entities = const [],
    this.emerging = const [],
    this.changes = const [],
    this.isAnalyzing = false,
    this.errorMessage,
    this.actionMessage,
  });

  bool get isLoading => status == ViewStatus.loading;

  List<TopicModel> get filteredTopics {
    if (searchQuery.trim().isEmpty) return topics;
    final q = searchQuery.toLowerCase();
    return topics.where((t) {
      return t.name.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q) ||
          t.keywords.any((k) => k.toLowerCase().contains(q));
    }).toList();
  }

  TopicState copyWith({
    ViewStatus? status,
    List<TopicModel>? topics,
    String? searchQuery,
    List<TopicTrend>? trends,
    List<TopicCluster>? clusters,
    List<TopicEntityAssociation>? entities,
    List<EmergingTopic>? emerging,
    List<TopicChange>? changes,
    bool? isAnalyzing,
    String? errorMessage,
    String? actionMessage,
    bool clearError = false,
    bool clearActionMessage = false,
  }) {
    return TopicState(
      status: status ?? this.status,
      topics: topics ?? this.topics,
      searchQuery: searchQuery ?? this.searchQuery,
      trends: trends ?? this.trends,
      clusters: clusters ?? this.clusters,
      entities: entities ?? this.entities,
      emerging: emerging ?? this.emerging,
      changes: changes ?? this.changes,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionMessage: clearActionMessage
          ? null
          : (actionMessage ?? this.actionMessage),
    );
  }
}

/// Provider for TopicNotifier.
final topicNotifierProvider =
    NotifierProvider<TopicNotifier, TopicState>(TopicNotifier.new);

class TopicNotifier extends Notifier<TopicState> {
  late final TopicRepository _repository;

  @override
  TopicState build() {
    _repository = ref.watch(topicRepositoryProvider);
    return const TopicState();
  }

  /// Loads all topics modules concurrently.
  Future<void> loadAll() async {
    state = state.copyWith(status: ViewStatus.loading, clearError: true);

    try {
      final topicsFuture = _repository.getTopics();
      final trendsFuture = _repository.getTrends();
      final clustersFuture = _repository.getClusters();
      final entitiesFuture = _repository.getEntities();
      final emergingFuture = _repository.getEmerging();
      final changesFuture = _repository.getChanges();

      final results = await Future.wait([
        topicsFuture,
        trendsFuture,
        clustersFuture,
        entitiesFuture,
        emergingFuture,
        changesFuture,
      ]);

      if (!ref.mounted) return;

      state = state.copyWith(
        status: ViewStatus.success,
        topics: results[0] as List<TopicModel>,
        trends: results[1] as List<TopicTrend>,
        clusters: results[2] as List<TopicCluster>,
        entities: results[3] as List<TopicEntityAssociation>,
        emerging: results[4] as List<EmergingTopic>,
        changes: results[5] as List<TopicChange>,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: ViewStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Trigger LLM topic discovery (POST /topics/analyze).
  /// Guarded against accidental concurrent duplicate requests.
  Future<void> analyzeTopics({
    String? documentId,
    List<String>? documentIds,
  }) async {
    if (state.isAnalyzing) return;

    state = state.copyWith(
      isAnalyzing: true,
      clearError: true,
      clearActionMessage: true,
    );

    try {
      final result = await _repository.analyzeTopics(
        documentId: documentId,
        documentIds: documentIds,
      );
      if (!ref.mounted) return;

      state = state.copyWith(
        isAnalyzing: false,
        actionMessage:
            'Topic analysis complete: ${result.topicsFound} statutory mining topics discovered.',
      );

      // Refresh topics list
      await loadAll();
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: 'Topic analysis failed: $e',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearActionMessage: true);
  }
}
