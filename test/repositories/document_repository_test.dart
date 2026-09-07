import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/core/errors/failures.dart';
import 'package:mineintel_ai/models/document_model.dart';
import 'package:mineintel_ai/repositories/document_repository.dart';

void main() {
  late MockDocumentRepository repository;

  setUp(() {
    repository = MockDocumentRepository(delay: Duration.zero);
  });

  group('MockDocumentRepository Operations Tests', () {
    test('getDocuments returns seeded documents with pagination meta', () async {
      final response = await repository.getDocuments(const DocumentFilter(limit: 10));

      expect(response.documents.isNotEmpty, isTrue);
      expect(response.meta.total, greaterThanOrEqualTo(5));
      expect(response.meta.page, 1);
      expect(response.meta.limit, 10);
    });

    test('getDocuments filters by search term', () async {
      final response = await repository.getDocuments(
        const DocumentFilter(search: 'Rajmahal'),
      );

      expect(response.documents.length, 1);
      expect(response.documents.first.originalName, contains('Rajmahal'));
    });

    test('getDocuments filters by file type', () async {
      final response = await repository.getDocuments(
        const DocumentFilter(type: 'docx'),
      );

      expect(response.documents.every((d) => d.fileType == 'docx'), isTrue);
    });

    test('getDocuments filters by status', () async {
      final response = await repository.getDocuments(
        const DocumentFilter(status: 'processing'),
      );

      expect(response.documents.every((d) => d.status == 'processing'), isTrue);
    });

    test('getDocuments filters by category and classification', () async {
      final response = await repository.getDocuments(
        const DocumentFilter(
          category: 'Safety & DGMS Directive',
          classification: 'confidential',
        ),
      );

      expect(response.documents.length, 1);
      expect(response.documents.first.category, 'Safety & DGMS Directive');
      expect(response.documents.first.classification, 'confidential');
    });

    test('uploadDocument rejects files exceeding 50 MB limit', () async {
      // Mock File that reports length > 50MB
      final largeFile = _MockLargeFile(sizeBytes: 52428801); // 50MB + 1 byte

      expect(
        () => repository.uploadDocument(largeFile),
        throwsA(isA<ValidationFailure>().having(
          (e) => e.message,
          'message',
          contains('50 MB'),
        )),
      );
    });

    test('uploadDocument handles 409 Duplicate Document collision', () async {
      final duplicateFile = _MockNormalFile(
        path: 'C:/docs/duplicate_report.pdf',
        sizeBytes: 1024,
      );

      expect(
        () => repository.uploadDocument(duplicateFile),
        throwsA(isA<ConflictFailure>().having(
          (e) => e.isDuplicateDocument,
          'isDuplicateDocument',
          isTrue,
        )),
      );
    });

    test('uploadDocument tracks send progress and creates document', () async {
      int callbackCount = 0;
      final file = _MockNormalFile(
        path: 'C:/docs/New_Blast_Plan_2026.pdf',
        sizeBytes: 2048,
      );

      final doc = await repository.uploadDocument(
        file,
        onSendProgress: (sent, total) {
          callbackCount++;
          expect(sent, lessThanOrEqualTo(total));
        },
      );

      expect(callbackCount, greaterThanOrEqualTo(1));
      expect(doc.originalName, 'New_Blast_Plan_2026.pdf');
      expect(doc.status, 'queued');

      // Verify added to list
      final list = await repository.getDocuments(const DocumentFilter());
      expect(list.documents.any((d) => d.id == doc.id), isTrue);
    });

    test('getDocumentDetail returns document and OCR text pages', () async {
      final detail = await repository.getDocumentDetail('doc-001');

      expect(detail.document.id, 'doc-001');
      expect(detail.pages.isNotEmpty, isTrue);
      expect(detail.pages.first.text, contains('MINISTRY OF COAL'));
    });

    test('getDocumentMetadata returns full metadata', () async {
      final meta = await repository.getDocumentMetadata('doc-001');

      expect(meta.id, 'doc-001');
      expect(meta.gisMetadata?.mineCode, 'ECL-04');
      expect(meta.entities.any((e) => e.name == 'Rajmahal OCP'), isTrue);
    });

    test('updateDocumentMetadata modifies editable fields', () async {
      const updateReq = DocumentMetadataUpdateRequest(
        category: 'Geological Log',
        classification: 'restricted',
        gisMetadata: GisMetadata(
          latitude: 24.1234,
          longitude: 86.5678,
          elevation: 180.0,
          mineCode: 'ECL-MODIFIED',
        ),
      );

      final updated = await repository.updateDocumentMetadata('doc-001', updateReq);

      expect(updated.category, 'Geological Log');
      expect(updated.classification, 'restricted');
      expect(updated.gisMetadata?.mineCode, 'ECL-MODIFIED');
      expect(updated.gisMetadata?.elevation, 180.0);
    });

    test('reprocessDocument and retryDocument reset status to processing', () async {
      final reprocessed = await repository.reprocessDocument('doc-001');
      expect(reprocessed.status, 'processing');

      final retried = await repository.retryDocument('doc-001');
      expect(retried.status, 'processing');

      final status = await repository.getDocumentStatus('doc-001');
      expect(status.status, 'processing');
      expect(status.progress, 30);
    });

    test('deleteDocument removes document from repository', () async {
      final deletedId = await repository.deleteDocument('doc-001');
      expect(deletedId, 'doc-001');

      expect(
        () => repository.getDocumentDetail('doc-001'),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('downloadDocument creates local file stream', () async {
      final tempDir = await Directory.systemTemp.createTemp('download_test');
      final targetPath = '${tempDir.path}/downloaded_ecl.pdf';

      final result = await repository.downloadDocument('doc-001', targetPath);

      expect(result, targetPath);
      final downloadedFile = File(targetPath);
      expect(await downloadedFile.exists(), isTrue);

      await tempDir.delete(recursive: true);
    });
  });
}

class _MockLargeFile extends Fake implements File {
  final int sizeBytes;

  _MockLargeFile({required this.sizeBytes});

  @override
  String get path => 'C:/docs/massive_mining_archive.zip';

  @override
  Future<int> length() async => sizeBytes;
}

class _MockNormalFile extends Fake implements File {
  @override
  final String path;
  final int sizeBytes;

  _MockNormalFile({required this.path, required this.sizeBytes});

  @override
  Future<int> length() async => sizeBytes;
}
