import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/models/extracted_record_model.dart';
import 'package:mineintel_ai/repositories/extraction_repository.dart';

void main() {
  group('Phase 7 ExtractionRepository & MockExtractionRepository Tests', () {
    late ExtractionRepository repository;

    setUp(() {
      EnvConfig.useMockData = true;
      repository = ExtractionRepositoryImpl(
        mockRepository: MockExtractionRepository(),
      );
    });

    tearDown(() {
      EnvConfig.useMockData = false;
    });

    test('getExtractionSummary returns valid summary with statistical metrics', () async {
      final summary = await repository.getExtractionSummary('doc_001');

      expect(summary.documentId, 'doc_001');
      expect(summary.summary.totalRecords, greaterThan(0));
      expect(summary.summary.averageConfidence, inInclusiveRange(0.0, 100.0));
      expect(summary.records.isNotEmpty, isTrue);
    });

    test('getExtractionRecords returns paginated list and filters by status', () async {
      final allResponse = await repository.getExtractionRecords(
        'doc_001',
        const ExtractionFilter(),
      );
      expect(allResponse.records.isNotEmpty, isTrue);

      final pendingResponse = await repository.getExtractionRecords(
        'doc_001',
        const ExtractionFilter(status: 'pending'),
      );
      for (final r in pendingResponse.records) {
        expect(r.status, 'pending');
      }
    });

    test('getExtractionRecords filters by parameter query', () async {
      final response = await repository.getExtractionRecords(
        'doc_001',
        const ExtractionFilter(parameter: 'Coal'),
      );
      for (final r in response.records) {
        expect(r.parameter.toLowerCase(), contains('coal'));
      }
    });

    test('updateExtractionRecord updates fields and records audit history', () async {
      final recordsResp = await repository.getExtractionRecords(
        'doc_001',
        const ExtractionFilter(),
      );
      final target = recordsResp.records.first;

      final updated = await repository.updateExtractionRecord(
        'doc_001',
        target.id,
        const ExtractedRecordUpdateRequest(
          value: '999999',
          unit: 'Custom Tonnes',
        ),
      );

      expect(updated.value, '999999');
      expect(updated.unit, 'Custom Tonnes');
      expect(updated.editHistory.isNotEmpty, isTrue);
    });

    test('approveRecord transitions status to approved', () async {
      final recordsResp = await repository.getExtractionRecords(
        'doc_001',
        const ExtractionFilter(),
      );
      final target = recordsResp.records.first;

      final approved = await repository.approveRecord(target.id);
      expect(approved.status, 'approved');
    });

    test('rejectRecord transitions status to rejected', () async {
      final recordsResp = await repository.getExtractionRecords(
        'doc_001',
        const ExtractionFilter(),
      );
      final target = recordsResp.records.first;

      final rejected = await repository.rejectRecord(target.id);
      expect(rejected.status, 'rejected');
    });

    test('bulkApproveRecords approves multiple records', () async {
      final recordsResp = await repository.getExtractionRecords(
        'doc_001',
        const ExtractionFilter(),
      );
      final ids = recordsResp.records.take(3).map((r) => r.id).toList();

      final res = await repository.bulkApproveRecords(ids);
      expect(res.modifiedCount, equals(ids.length));
    });

    test('runExtraction triggers pipeline and returns summary', () async {
      final res = await repository.runExtraction('doc_001');
      expect(res.documentId, 'doc_001');
      expect(res.summary.totalRecords, greaterThan(0));
    });
  });
}
