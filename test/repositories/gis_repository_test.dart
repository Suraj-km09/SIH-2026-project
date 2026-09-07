import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/repositories/gis_repository.dart';

void main() {
  group('Phase 10 GisRepository Tests', () {
    late MockGisRepository repo;

    setUp(() {
      repo = MockGisRepository();
    });

    test('getGisRecords returns documents with geographic coordinates', () async {
      final records = await repo.getGisRecords();
      expect(records, isNotEmpty);
      expect(records.every((r) => r.hasValidCoordinates), isTrue);
      for (final r in records) {
        expect(r.latitude, inInclusiveRange(8.0, 37.0)); // Indian sub-continent bounds
        expect(r.longitude, inInclusiveRange(68.0, 97.0));
      }
    });

    test('verify Indian coal mining coordinates exist in mock data', () async {
      final records = await repo.getGisRecords();
      final mineCodes = records.map((r) => r.mineCode).toList();
      expect(mineCodes, contains('ECL-04'));
      expect(mineCodes, contains('BCCL-09'));
      expect(mineCodes, contains('SECL-12'));
    });
  });
}
