import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/models/gis_model.dart';

void main() {
  group('Phase 10 GIS Models', () {
    test('GisDocumentRecord parses properly with complete coordinates', () {
      final json = {
        'id': 'doc-gis-001',
        'originalName': 'Gevra OCP Environmental Clearance',
        'category': 'Environmental',
        'status': 'completed',
        'gisMetadata': {
          'latitude': 22.3361,
          'longitude': 82.5939,
          'elevation': 310.0,
          'mineCode': 'GEVRA_01',
          'region': 'Chhattisgarh',
        },
      };

      final record = GisDocumentRecord.fromJson(json);
      expect(record.id, 'doc-gis-001');
      expect(record.originalName, 'Gevra OCP Environmental Clearance');
      expect(record.category, 'Environmental');
      expect(record.hasValidCoordinates, isTrue);
      expect(record.latitude, 22.3361);
      expect(record.longitude, 82.5939);
      expect(record.elevation, 310.0);
      expect(record.region, 'Chhattisgarh');
      expect(record.mineCode, 'GEVRA_01');
      expect(record.gisMetadata?.mineCode, 'GEVRA_01');
      expect(record.gisMetadata?.region, 'Chhattisgarh');
    });

    test('GisDocumentRecord correctly handles missing coordinates without failing', () {
      final json = {
        'id': 'doc-no-gis',
        'originalName': 'General Office Memo',
        'category': 'Administrative',
        'status': 'completed',
      };

      final record = GisDocumentRecord.fromJson(json);
      expect(record.id, 'doc-no-gis');
      expect(record.hasValidCoordinates, isFalse);
      expect(record.latitude, isNull);
      expect(record.longitude, isNull);
      expect(record.elevation, isNull);
    });
  });
}
