import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/command_centre_model.dart';
import '../repositories/command_centre_repository.dart';
import 'app_state.dart';

@immutable
class CommandCentreState {
  final ViewStatus status;
  final bool isRefreshing;
  final CommandCentreOverviewModel? overview;
  final CommandCentrePipelineModel? pipeline;
  final CommandCentreStatusModel? systemStatus;
  final CommandCentreAttentionModel? attention;
  final List<CommandCentreActivityModel> activities;
  final String attentionFilter;
  final String? errorMessage;

  const CommandCentreState({
    this.status = ViewStatus.initial,
    this.isRefreshing = false,
    this.overview,
    this.pipeline,
    this.systemStatus,
    this.attention,
    this.activities = const [],
    this.attentionFilter = 'ALL',
    this.errorMessage,
  });

  bool get isLoading => status == ViewStatus.loading && overview == null;

  List<AttentionItemModel> get filteredAttentionItems {
    final all = attention?.items ?? [];
    if (attentionFilter == 'ALL') return all;
    if (attentionFilter == 'HIGH') {
      return all.where((e) => e.priority.toLowerCase() == 'high').toList();
    }
    return all.where((e) => e.category == attentionFilter).toList();
  }

  CommandCentreState copyWith({
    ViewStatus? status,
    bool? isRefreshing,
    CommandCentreOverviewModel? overview,
    CommandCentrePipelineModel? pipeline,
    CommandCentreStatusModel? systemStatus,
    CommandCentreAttentionModel? attention,
    List<CommandCentreActivityModel>? activities,
    String? attentionFilter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CommandCentreState(
      status: status ?? this.status,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      overview: overview ?? this.overview,
      pipeline: pipeline ?? this.pipeline,
      systemStatus: systemStatus ?? this.systemStatus,
      attention: attention ?? this.attention,
      activities: activities ?? this.activities,
      attentionFilter: attentionFilter ?? this.attentionFilter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Provider for CommandCentreNotifier.
final commandCentreNotifierProvider =
    NotifierProvider<CommandCentreNotifier, CommandCentreState>(
        CommandCentreNotifier.new);

class CommandCentreNotifier extends Notifier<CommandCentreState> {
  late final CommandCentreRepository _repository;

  @override
  CommandCentreState build() {
    _repository = ref.watch(commandCentreRepositoryProvider);
    return const CommandCentreState();
  }

  /// Loads all Command Centre telemetry and monitoring data in parallel.
  Future<void> loadAll({bool isSilent = false}) async {
    if (!isSilent && state.overview == null) {
      state = state.copyWith(status: ViewStatus.loading, clearError: true);
    } else {
      state = state.copyWith(isRefreshing: true, clearError: true);
    }

    try {
      final results = await Future.wait([
        _repository.getOverview(),
        _repository.getPipeline(),
        _repository.getStatus(),
        _repository.getAttentionItems(),
        _repository.getActivity(),
      ]);

      if (!ref.mounted) return;

      state = state.copyWith(
        status: ViewStatus.success,
        isRefreshing: false,
        overview: results[0] as CommandCentreOverviewModel,
        pipeline: results[1] as CommandCentrePipelineModel,
        systemStatus: results[2] as CommandCentreStatusModel,
        attention: results[3] as CommandCentreAttentionModel,
        activities: results[4] as List<CommandCentreActivityModel>,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: state.overview != null ? ViewStatus.success : ViewStatus.error,
        isRefreshing: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sets active filter for attention queue.
  void setAttentionFilter(String filter) {
    state = state.copyWith(attentionFilter: filter);
  }
}
