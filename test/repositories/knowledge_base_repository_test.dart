import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/models/knowledge_base_model.dart';
import 'package:mineintel_ai/repositories/knowledge_base_repository.dart';

void main() {
  group('Phase 9 KnowledgeBaseRepository & MockKnowledgeBaseRepository Tests', () {
    late KnowledgeBaseRepository repository;

    setUp(() {
      EnvConfig.useMockData = true;
      repository = KnowledgeBaseRepositoryImpl(
        mockRepository: MockKnowledgeBaseRepository(),
      );
    });

    tearDown(() {
      EnvConfig.useMockData = false;
    });

    test('getKnowledgeBase returns documents list and vector meta statistics', () async {
      final response = await repository.getKnowledgeBase(const KnowledgeBaseFilter());

      expect(response.documents.isNotEmpty, isTrue);
      expect(response.meta.total, greaterThan(0));
      expect(response.meta.totalIndexedDocuments, greaterThan(0));
      expect(response.meta.totalVectorChunks, greaterThan(0));
    });

    test('indexDocument and ragIndexDocument generate chunks and mark indexed', () async {
      final res = await repository.indexDocument('doc_004');

      expect(res.documentId, 'doc_004');
      expect(res.chunksIndexed, greaterThan(0));

      final updated = await repository.getKnowledgeBase(const KnowledgeBaseFilter());
      final target = updated.documents.firstWhere((d) => d.id == 'doc_004');
      expect(target.isIndexed, isTrue);
      expect(target.chunksCount, greaterThan(0));
    });

    test('getDocumentChunks returns vector chunk details', () async {
      final detail = await repository.getDocumentChunks('doc_001');

      expect(detail.documentId, 'doc_001');
      expect(detail.chunks.isNotEmpty, isTrue);
      expect(detail.chunks.first.content, contains('Eastern Coalfields'));
    });

    test('search and ragSearch perform semantic similarity ranking', () async {
      final searchResp = await repository.search('raw coal extraction', topK: 3);

      expect(searchResp.results.isNotEmpty, isTrue);
      expect(searchResp.results.first.similarity, greaterThan(0.70));
      expect(searchResp.results.length, lessThanOrEqualTo(3));

      final ragResults = await repository.ragSearch('methane monitoring', topK: 2);
      expect(ragResults.isNotEmpty, isTrue);
      expect(ragResults.first.text, contains('methane'));
    });

    test('deleteDocumentIndex removes vector index from document', () async {
      final success = await repository.deleteDocumentIndex('doc_002');
      expect(success, isTrue);

      final updated = await repository.getKnowledgeBase(const KnowledgeBaseFilter());
      final target = updated.documents.firstWhere((d) => d.id == 'doc_002');
      expect(target.isIndexed, isFalse);
      expect(target.chunksCount, 0);
    });
  });
}
