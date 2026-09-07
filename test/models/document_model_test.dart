import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/models/document_model.dart';

void main() {
  group('DocumentModel & DocumentDetailModel Unit Tests', () {
    test('DocumentModel fromJson / toJson round-trip', () {
      final json = {
        '_id': 'doc-123',
        'originalName': 'ECL_Coal_Production.pdf',
        'filename': '1725619200000-ECL_Coal_Production.pdf',
        'mimeType': 'application/pdf',
        'fileSize': 2097152, // 2.0 MB
        'fileType': 'pdf',
        'hash': 'abc123sha256',
        'category': 'Production Report',
        'classification': 'internal',
        'status': 'completed',
        'totalPages': 12,
        'gisMetadata': {
          'latitude': 25.045,
          'longitude': 87.251,
          'elevation': 115.0,
          'mineCode': 'ECL-04',
          'region': 'Jharkhand',
        },
        'uploadedAt': '2026-09-06T10:00:00.000Z',
        'userId': 'usr-admin',
        'entities': [
          {'name': 'Rajmahal', 'type': 'LOCATION'},
        ],
        'topicIds': ['top-01'],
      };

      final doc = DocumentModel.fromJson(json);

      expect(doc.id, 'doc-123');
      expect(doc.originalName, 'ECL_Coal_Production.pdf');
      expect(doc.fileSize, 2097152);
      expect(doc.formattedFileSize, '2.0 MB');
      expect(doc.isCompleted, isTrue);
      expect(doc.isProcessing, isFalse);
      expect(doc.isTerminal, isTrue);
      expect(doc.gisMetadata?.latitude, 25.045);
      expect(doc.gisMetadata?.mineCode, 'ECL-04');
      expect(doc.entities?.first.name, 'Rajmahal');
      expect(doc.topicIds, ['top-01']);

      final serialized = doc.toJson();
      expect(serialized['_id'], 'doc-123');
      expect(serialized['originalName'], 'ECL_Coal_Production.pdf');
    });

    test('formattedFileSize handles Bytes, KB, and MB', () {
      const docBytes = DocumentModel(
        id: '1',
        originalName: 'test.txt',
        fileSize: 512,
        fileType: 'txt',
        category: 'Test',
        classification: 'public',
        status: 'pending',
      );
      expect(docBytes.formattedFileSize, '512 B');

      const docKb = DocumentModel(
        id: '2',
        originalName: 'test.txt',
        fileSize: 2048,
        fileType: 'txt',
        category: 'Test',
        classification: 'public',
        status: 'pending',
      );
      expect(docKb.formattedFileSize, '2.0 KB');

      const docMb = DocumentModel(
        id: '3',
        originalName: 'test.txt',
        fileSize: 10485760,
        fileType: 'txt',
        category: 'Test',
        classification: 'public',
        status: 'pending',
      );
      expect(docMb.formattedFileSize, '10.0 MB');
    });

    test('DocumentDetailModel parses document and pages', () {
      final json = {
        'document': {
          '_id': 'doc-detail-01',
          'originalName': 'BCCL_Safety.docx',
          'fileSize': 1024,
          'fileType': 'docx',
          'category': 'Safety',
          'classification': 'confidential',
          'status': 'completed',
          'totalPages': 2,
        },
        'pages': [
          {
            '_id': 'page-01',
            'documentId': 'doc-detail-01',
            'pageNumber': 1,
            'text': 'SAFETY REPORT SUMMARY',
          },
          {
            '_id': 'page-02',
            'documentId': 'doc-detail-01',
            'pageNumber': 2,
            'text': 'DGMS DIRECTIVE CHECKLIST',
          },
        ],
      };

      final detail = DocumentDetailModel.fromJson(json);
      expect(detail.document.id, 'doc-detail-01');
      expect(detail.pages.length, 2);
      expect(detail.pages[0].pageNumber, 1);
      expect(detail.pages[0].text, 'SAFETY REPORT SUMMARY');
      expect(detail.pages[1].pageNumber, 2);
    });

    test('DocumentMetadataModel parses full technical & GIS metadata', () {
      final json = {
        '_id': 'meta-doc-01',
        'originalName': 'Mine_Audit.pdf',
        'fileType': 'pdf',
        'fileSize': 3145728,
        'hash': 'sha256hash123',
        'status': 'completed',
        'category': 'Environmental Audit',
        'classification': 'restricted',
        'totalPages': 10,
        'entities': [
          {'name': 'CMPDI', 'type': 'ORGANIZATION'}
        ],
        'topicIds': ['env-audit'],
        'gisMetadata': {
          'latitude': 23.5,
          'longitude': 85.2,
          'elevation': 500.0,
          'mineCode': 'CMPDI-01',
        },
        'retentionDate': '2031-09-07T00:00:00.000Z',
        'uploadedAt': '2026-09-06T10:00:00.000Z',
        'processedAt': '2026-09-06T10:01:15.000Z',
      };

      final meta = DocumentMetadataModel.fromJson(json);
      expect(meta.id, 'meta-doc-01');
      expect(meta.hash, 'sha256hash123');
      expect(meta.gisMetadata?.mineCode, 'CMPDI-01');
      expect(meta.entities.first.name, 'CMPDI');
      expect(meta.retentionDate, '2031-09-07T00:00:00.000Z');
      expect(meta.processedAt, '2026-09-06T10:01:15.000Z');
    });

    test('DocumentStatusModel terminal checks', () {
      final statusQueued = DocumentStatusModel.fromJson({
        '_id': 'job-01',
        'documentId': 'doc-01',
        'status': 'queued',
        'progress': 0,
      });
      expect(statusQueued.isQueued, isTrue);
      expect(statusQueued.isProcessing, isTrue);
      expect(statusQueued.isTerminal, isFalse);

      final statusProcessing = DocumentStatusModel.fromJson({
        '_id': 'job-02',
        'documentId': 'doc-02',
        'status': 'processing',
        'progress': 45,
      });
      expect(statusProcessing.isProcessing, isTrue);
      expect(statusProcessing.isTerminal, isFalse);

      final statusCompleted = DocumentStatusModel.fromJson({
        '_id': 'job-03',
        'documentId': 'doc-03',
        'status': 'completed',
        'progress': 100,
      });
      expect(statusCompleted.isCompleted, isTrue);
      expect(statusCompleted.isTerminal, isTrue);

      final statusFailed = DocumentStatusModel.fromJson({
        '_id': 'job-04',
        'documentId': 'doc-04',
        'status': 'failed',
        'progress': 20,
        'error': 'OCR parse failure',
      });
      expect(statusFailed.isFailed, isTrue);
      expect(statusFailed.isTerminal, isTrue);
      expect(statusFailed.error, 'OCR parse failure');
    });

    test('DocumentFilter toQueryParams matches OpenAPI spec', () {
      const filter = DocumentFilter(
        search: 'Rajmahal',
        type: 'pdf',
        status: 'completed',
        category: 'Production Report',
        classification: 'internal',
        dateFrom: '2026-09-01',
        dateTo: '2026-09-07',
        page: 2,
        limit: 25,
      );

      final params = filter.toQueryParams();
      expect(params['search'], 'Rajmahal');
      expect(params['type'], 'pdf');
      expect(params['status'], 'completed');
      expect(params['category'], 'Production Report');
      expect(params['classification'], 'internal');
      expect(params['dateFrom'], '2026-09-01');
      expect(params['dateTo'], '2026-09-07');
      expect(params['page'], 2);
      expect(params['limit'], 25);
    });
  });
}
