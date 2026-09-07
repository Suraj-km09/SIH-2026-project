import '../core/errors/failures.dart';
import '../models/extracted_record_model.dart';
import '../network/extraction_remote_data_source.dart';
import 'base_repository.dart';

/// Abstract contract for Data Extraction operations.
abstract class ExtractionRepository {
  Future<ExtractionSummaryModel> runExtraction(String documentId);
  Future<ExtractionSummaryModel> getExtractionSummary(String documentId);
  Future<ExtractionRecordsResponse> getExtractionRecords(
    String documentId,
    ExtractionFilter filter,
  );
  Future<ExtractedRecordModel> updateExtractionRecord(
    String documentId,
    String recordId,
    ExtractedRecordUpdateRequest request,
  );
  Future<ExtractedRecordModel> approveRecord(String recordId);
  Future<ExtractedRecordModel> rejectRecord(String recordId);
  Future<BulkApproveResponse> bulkApproveRecords(List<String> recordIds);
}

/// Concrete implementation delegating to ExtractionRemoteDataSource or Mock.
class ExtractionRepositoryImpl extends BaseRepository implements ExtractionRepository {
  final ExtractionRemoteDataSource _remoteDataSource;
  final ExtractionRepository? mockRepository;

  ExtractionRepositoryImpl({
    ExtractionRemoteDataSource? remoteDataSource,
    this.mockRepository,
  }) : _remoteDataSource = remoteDataSource ?? ExtractionRemoteDataSourceImpl();

  @override
  Future<ExtractionSummaryModel> runExtraction(String documentId) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.runExtraction(documentId);
    }
    return execute(() => _remoteDataSource.runExtraction(documentId));
  }

  @override
  Future<ExtractionSummaryModel> getExtractionSummary(String documentId) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getExtractionSummary(documentId);
    }
    return execute(() => _remoteDataSource.getExtractionSummary(documentId));
  }

  @override
  Future<ExtractionRecordsResponse> getExtractionRecords(
    String documentId,
    ExtractionFilter filter,
  ) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getExtractionRecords(documentId, filter);
    }
    return execute(() => _remoteDataSource.getExtractionRecords(documentId, filter));
  }

  @override
  Future<ExtractedRecordModel> updateExtractionRecord(
    String documentId,
    String recordId,
    ExtractedRecordUpdateRequest request,
  ) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.updateExtractionRecord(documentId, recordId, request);
    }
    return execute(() => _remoteDataSource.updateExtractionRecord(documentId, recordId, request));
  }

  @override
  Future<ExtractedRecordModel> approveRecord(String recordId) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.approveRecord(recordId);
    }
    return execute(() => _remoteDataSource.approveRecord(recordId));
  }

  @override
  Future<ExtractedRecordModel> rejectRecord(String recordId) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.rejectRecord(recordId);
    }
    return execute(() => _remoteDataSource.rejectRecord(recordId));
  }

  @override
  Future<BulkApproveResponse> bulkApproveRecords(List<String> recordIds) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.bulkApproveRecords(recordIds);
    }
    return execute(() => _remoteDataSource.bulkApproveRecords(recordIds));
  }
}

/// High-fidelity offline mock repository matching exact extraction API schemas.
class MockExtractionRepository implements ExtractionRepository {
  final Duration delay;
  final Map<String, List<ExtractedRecordModel>> _recordsByDoc = {};

  MockExtractionRepository({
    this.delay = Duration.zero,
    Map<String, List<ExtractedRecordModel>>? initialRecords,
  }) {
    if (initialRecords != null) {
      _recordsByDoc.addAll(initialRecords);
    } else {
      _seedDefaultRecords();
    }
  }

  void _seedDefaultRecords() {
    _recordsByDoc['doc-001'] = [
      ExtractedRecordModel(
        id: 'rec-001-1',
        documentId: 'doc-001',
        pageNumber: 1,
        parameter: 'Raw Coal Production',
        value: '1420.5',
        originalValue: '1420.5',
        unit: 'Tonnes',
        period: 'August 2026',
        mineName: 'Rajmahal OCP',
        subsidiary: 'ECL',
        confidenceScore: 0.96,
        sourceText: 'Total raw coal production for August recorded at 1,420.5 Tonnes.',
        status: 'approved',
        editHistory: const [],
      ),
      ExtractedRecordModel(
        id: 'rec-001-2',
        documentId: 'doc-001',
        pageNumber: 1,
        parameter: 'Overburden Removal',
        value: '3820.0',
        originalValue: '3900.0',
        unit: 'Cu.m',
        period: 'August 2026',
        mineName: 'Rajmahal OCP',
        subsidiary: 'ECL',
        confidenceScore: 0.91,
        sourceText: 'Overburden excavation reached 3,820 Cu.m in Block 4.',
        status: 'pending',
        editHistory: [
          EditHistoryEntry(
            field: 'value',
            oldValue: '3900.0',
            newValue: '3820.0',
            editedAt: '2026-09-06T14:30:00.000Z',
            editedBy: 'admin',
          ),
        ],
      ),
      ExtractedRecordModel(
        id: 'rec-001-3',
        documentId: 'doc-001',
        pageNumber: 2,
        parameter: 'Coal Dispatch Rail',
        value: '1150.0',
        originalValue: '1150.0',
        unit: 'Tonnes',
        period: 'August 2026',
        mineName: 'Rajmahal OCP',
        subsidiary: 'ECL',
        confidenceScore: 0.94,
        sourceText: 'Total rail rake dispatch amounted to 1,150.0 Tonnes.',
        status: 'pending',
        editHistory: const [],
      ),
      ExtractedRecordModel(
        id: 'rec-001-4',
        documentId: 'doc-001',
        pageNumber: 2,
        parameter: 'Ash Content',
        value: '14.2',
        originalValue: '14.2',
        unit: '%',
        period: 'August 2026',
        mineName: 'Rajmahal OCP',
        subsidiary: 'ECL',
        confidenceScore: 0.88,
        sourceText: 'Proximate analysis: dry basis Ash content 14.2%.',
        status: 'pending',
        editHistory: const [],
      ),
      ExtractedRecordModel(
        id: 'rec-001-5',
        documentId: 'doc-001',
        pageNumber: 2,
        parameter: 'Methane Gas Concentration',
        value: '0.08',
        originalValue: '0.08',
        unit: '% CH4',
        period: 'August 2026',
        mineName: 'Rajmahal OCP',
        subsidiary: 'ECL',
        confidenceScore: 0.98,
        sourceText: 'Return airway methane monitoring sensor averaged 0.08% CH4.',
        status: 'approved',
        editHistory: const [],
      ),
    ];

    // Seed doc-002
    _recordsByDoc['doc-002'] = [
      const ExtractedRecordModel(
        id: 'rec-002-1',
        documentId: 'doc-002',
        pageNumber: 1,
        parameter: 'Ventilation Air Quantity',
        value: '4800.0',
        unit: 'm3/min',
        period: 'Q2 2026',
        mineName: 'Dhanbad Underground Pit 4',
        subsidiary: 'BCCL',
        confidenceScore: 0.95,
        sourceText: 'Shaft ventilation volume: 4,800 m3/min.',
        status: 'approved',
      ),
      const ExtractedRecordModel(
        id: 'rec-002-2',
        documentId: 'doc-002',
        pageNumber: 1,
        parameter: 'Respirable Dust PM10',
        value: '2.4',
        unit: 'mg/m3',
        period: 'Q2 2026',
        mineName: 'Dhanbad Underground Pit 4',
        subsidiary: 'BCCL',
        confidenceScore: 0.85,
        sourceText: 'Airborne dust concentration measured at 2.4 mg/m3.',
        status: 'pending',
      ),
    ];
  }

  String _resolveDocKey(String documentId) {
    if (_recordsByDoc.containsKey(documentId)) return documentId;
    final hyphen = documentId.replaceAll('_', '-');
    if (_recordsByDoc.containsKey(hyphen)) return hyphen;
    final under = documentId.replaceAll('-', '_');
    if (_recordsByDoc.containsKey(under)) return under;
    return documentId;
  }

  @override
  Future<ExtractionSummaryModel> runExtraction(String documentId) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    final key = _resolveDocKey(documentId);
    if (!_recordsByDoc.containsKey(key)) {
      _recordsByDoc[key] = [
        ExtractedRecordModel(
          id: 'rec-$documentId-1',
          documentId: documentId,
          pageNumber: 1,
          parameter: 'Raw Coal Production',
          value: '2540.0',
          originalValue: '2540.0',
          unit: 'Tonnes',
          period: 'August 2026',
          mineName: 'Jharia Coalfield Pit 3',
          subsidiary: 'BCCL',
          confidenceScore: 0.93,
          sourceText: 'Monthly raw coal extraction: 2,540.0 Tonnes.',
          status: 'pending',
        ),
      ];
    }

    return getExtractionSummary(documentId);
  }

  @override
  Future<ExtractionSummaryModel> getExtractionSummary(String documentId) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    final key = _resolveDocKey(documentId);
    final records = _recordsByDoc[key] ?? [];
    final total = records.length;
    final approved = records.where((r) => r.isApproved).length;
    final pending = records.where((r) => r.isPending).length;
    final rejected = records.where((r) => r.isRejected).length;

    final avgConf = total > 0
        ? records.fold(0.0, (acc, r) => acc + r.confidenceScore) / total
        : 0.0;

    final params = records.map((r) => r.parameter).toSet().toList();

    return ExtractionSummaryModel(
      documentId: documentId,
      summary: ExtractionSummaryStats(
        total: total,
        approved: approved,
        pending: pending,
        rejected: rejected,
        avgConfidence: avgConf,
        parameters: params,
      ),
      records: records,
    );
  }

  @override
  Future<ExtractionRecordsResponse> getExtractionRecords(
    String documentId,
    ExtractionFilter filter,
  ) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    final key = _resolveDocKey(documentId);
    var list = List<ExtractedRecordModel>.from(_recordsByDoc[key] ?? []);

    if (filter.status != null && filter.status!.isNotEmpty) {
      list = list.where((r) => r.status.toLowerCase() == filter.status!.toLowerCase()).toList();
    }
    if (filter.parameter != null && filter.parameter!.isNotEmpty) {
      final q = filter.parameter!.toLowerCase();
      list = list.where((r) => r.parameter.toLowerCase().contains(q)).toList();
    }
    if (filter.mineName != null && filter.mineName!.isNotEmpty) {
      final q = filter.mineName!.toLowerCase();
      list = list.where((r) => r.mineName?.toLowerCase().contains(q) ?? false).toList();
    }

    final total = list.length;
    final totalPages = (total / filter.limit).ceil().clamp(1, 99999);
    final startIndex = ((filter.page - 1) * filter.limit).clamp(0, total);
    final endIndex = (startIndex + filter.limit).clamp(0, total);
    final paginated = list.sublist(startIndex, endIndex);

    return ExtractionRecordsResponse(
      records: paginated,
      meta: ExtractionRecordsPaginationMeta(
        total: total,
        page: filter.page,
        limit: filter.limit,
        pages: totalPages,
      ),
    );
  }

  @override
  Future<ExtractedRecordModel> updateExtractionRecord(
    String documentId,
    String recordId,
    ExtractedRecordUpdateRequest request,
  ) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    final key = _resolveDocKey(documentId);
    final records = _recordsByDoc[key];
    if (records == null) {
      throw NotFoundFailure('No records found for document $documentId');
    }

    final index = records.indexWhere((r) => r.id == recordId);
    if (index == -1) {
      throw NotFoundFailure('Extracted record with id $recordId not found');
    }

    final old = records[index];
    final history = List<EditHistoryEntry>.from(old.editHistory);

    if (request.value != null && request.value != old.value) {
      history.insert(
        0,
        EditHistoryEntry(
          field: 'value',
          oldValue: old.value,
          newValue: request.value,
          editedAt: DateTime.now().toUtc().toIso8601String(),
          editedBy: 'reviewer',
        ),
      );
    }

    final updated = old.copyWith(
      value: request.value ?? old.value,
      unit: request.unit ?? old.unit,
      parameter: request.parameter ?? old.parameter,
      status: request.status ?? old.status,
      period: request.period ?? old.period,
      mineName: request.mineName ?? old.mineName,
      subsidiary: request.subsidiary ?? old.subsidiary,
      editHistory: history,
    );

    records[index] = updated;
    return updated;
  }

  @override
  Future<ExtractedRecordModel> approveRecord(String recordId) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    for (final docRecords in _recordsByDoc.values) {
      final index = docRecords.indexWhere((r) => r.id == recordId);
      if (index != -1) {
        final updated = docRecords[index].copyWith(status: 'approved');
        docRecords[index] = updated;
        return updated;
      }
    }
    throw NotFoundFailure('Record with id $recordId not found.');
  }

  @override
  Future<ExtractedRecordModel> rejectRecord(String recordId) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    for (final docRecords in _recordsByDoc.values) {
      final index = docRecords.indexWhere((r) => r.id == recordId);
      if (index != -1) {
        final updated = docRecords[index].copyWith(status: 'rejected');
        docRecords[index] = updated;
        return updated;
      }
    }
    throw NotFoundFailure('Record with id $recordId not found.');
  }

  @override
  Future<BulkApproveResponse> bulkApproveRecords(List<String> recordIds) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    int modified = 0;
    for (final docRecords in _recordsByDoc.values) {
      for (int i = 0; i < docRecords.length; i++) {
        if (recordIds.contains(docRecords[i].id)) {
          docRecords[i] = docRecords[i].copyWith(status: 'approved');
          modified++;
        }
      }
    }

    return BulkApproveResponse(
      matchedCount: recordIds.length,
      modifiedCount: modified,
    );
  }
}
