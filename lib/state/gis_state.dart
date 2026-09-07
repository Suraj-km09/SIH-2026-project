import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gis_model.dart';
import '../repositories/gis_repository.dart';
import 'app_state.dart';

@immutable
class GisState {
  final ViewStatus status;
  final List<GisDocumentRecord> records;
  final GisDocumentRecord? selectedRecord;
  final String selectedRegion;
  final String? errorMessage;
  final String? actionMessage;

  const GisState({
    this.status = ViewStatus.initial,
    this.records = const [],
    this.selectedRecord,
    this.selectedRegion = 'ALL',
    this.errorMessage,
    this.actionMessage,
  });

  bool get isLoading => status == ViewStatus.loading;

  List<GisDocumentRecord> get validCoordinateRecords =>
      records.where((r) => r.hasValidCoordinates).toList();

  List<GisDocumentRecord> get filteredRecords {
    final valid = validCoordinateRecords;
    if (selectedRegion == 'ALL' || selectedRegion.isEmpty) {
      return valid;
    }
    return valid
        .where((r) =>
            r.region?.toLowerCase() == selectedRegion.toLowerCase())
        .toList();
  }

  List<String> get availableRegions {
    final regions = <String>{'ALL'};
    for (final r in validCoordinateRecords) {
      if (r.region != null && r.region!.trim().isNotEmpty) {
        regions.add(r.region!);
      }
    }
    return regions.toList();
  }

  GisState copyWith({
    ViewStatus? status,
    List<GisDocumentRecord>? records,
    GisDocumentRecord? selectedRecord,
    bool clearSelectedRecord = false,
    String? selectedRegion,
    String? errorMessage,
    String? actionMessage,
    bool clearError = false,
    bool clearActionMessage = false,
  }) {
    return GisState(
      status: status ?? this.status,
      records: records ?? this.records,
      selectedRecord: clearSelectedRecord
          ? null
          : (selectedRecord ?? this.selectedRecord),
      selectedRegion: selectedRegion ?? this.selectedRegion,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionMessage: clearActionMessage
          ? null
          : (actionMessage ?? this.actionMessage),
    );
  }
}

/// Provider for GisNotifier.
final gisNotifierProvider =
    NotifierProvider<GisNotifier, GisState>(GisNotifier.new);

class GisNotifier extends Notifier<GisState> {
  late final GisRepository _repository;

  @override
  GisState build() {
    _repository = ref.watch(gisRepositoryProvider);
    return const GisState();
  }

  /// Loads GIS spatial coordinates from `GET /integration/gis`.
  Future<void> loadGisRecords() async {
    state = state.copyWith(status: ViewStatus.loading, clearError: true);

    try {
      final records = await _repository.getGisRecords();
      if (!ref.mounted) return;

      final initialSelected = records.isNotEmpty
          ? records.firstWhere((r) => r.hasValidCoordinates, orElse: () => records.first)
          : null;

      state = state.copyWith(
        status: ViewStatus.success,
        records: records,
        selectedRecord: initialSelected,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: ViewStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void selectRecord(GisDocumentRecord? record) {
    state = state.copyWith(selectedRecord: record);
  }

  void setRegionFilter(String region) {
    state = state.copyWith(selectedRegion: region);
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearActionMessage: true);
  }
}
