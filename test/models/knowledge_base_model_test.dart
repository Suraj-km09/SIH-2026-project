import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/models/knowledge_base_model.dart';

void main() {
  group('Phase 9 Knowledge Base Models Tests', () {
    test('KnowledgeBaseFilter converts to query parameters correctly', () {
      const filter = KnowledgeBaseFilter(
        search: 'overburden',
        category: 'production',
        classification: 'confidential',
        page: 2,
        limit: 50,
      );

      final params = filter.toQueryParams();
      expect(params['search'], 'overburden');
      expect(params['category'], 'production');
      expect(params['classification'], 'confidential');
      expect(params['page'], 2);
      expect(params['limit'], 50);
    });

    test('KnowledgeBaseDocumentModel parses json and supports copyWith', () {
      final json = {
        'id': 'doc_001',
        'originalName': 'ECL_Production.pdf',
        'isIndexed': true,
        'chunksCount': 24,
        'lastIndexedAt': '2026-09-07T04:30:00.000Z',
        'category': 'production',
      };

      final doc = KnowledgeBaseDocumentModel.fromJson(json);
      expect(doc.id, 'doc_001');
      expect(doc.originalName, 'ECL_Production.pdf');
      expect(doc.isIndexed, isTrue);
      expect(doc.chunksCount, 24);

      final updated = doc.copyWith(chunksCount: 28);
      expect(updated.chunksCount, 28);
      expect(updated.id, 'doc_001');
    });

    test('VectorChunkModel and KnowledgeBaseDetailModel parse correctly', () {
      final json = {
        'data': {
          'documentId': 'doc_002',
          'documentName': 'DGMS_Ventilation.pdf',
          'chunksCount': 2,
          'chunks': [
            {
              'id': 'c1',
              'chunkIndex': 0,
              'pageNumber': 1,
              'content': 'Ventilation shaft delivery 4800 m3/min.',
              'createdAt': '2026-09-06T10:00:00.000Z',
            },
            {
              'id': 'c2',
              'chunkIndex': 1,
              'pageNumber': 2,
              'content': 'Methane detector average 0.08% CH4.',
            },
          ],
        },
      };

      final detail = KnowledgeBaseDetailModel.fromJson(json);
      expect(detail.documentId, 'doc_002');
      expect(detail.documentName, 'DGMS_Ventilation.pdf');
      expect(detail.chunks.length, 2);
      expect(detail.chunks.first.chunkIndex, 0);
      expect(detail.chunks.last.pageNumber, 2);
    });

    test('KnowledgeBaseSearchResponse parses vector search rankings and similarity', () {
      final json = {
        'data': {
          'query': 'methane gas levels',
          'topK': 5,
          'totalResults': 1,
          'results': [
            {
              'chunkId': 'c2',
              'documentId': 'doc_002',
              'documentName': 'DGMS_Ventilation.pdf',
              'pageNumber': 2,
              'text': 'Methane detector average 0.08% CH4.',
              'similarity': 0.942,
            },
          ],
        },
      };

      final resp = KnowledgeBaseSearchResponse.fromJson(json);
      expect(resp.query, 'methane gas levels');
      expect(resp.results.length, 1);
      expect(resp.results.first.similarity, 0.942);
      expect(resp.results.first.documentName, 'DGMS_Ventilation.pdf');
    });
  });
}
