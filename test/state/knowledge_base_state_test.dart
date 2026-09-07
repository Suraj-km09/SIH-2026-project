import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/repositories/knowledge_base_repository.dart';
import 'package:mineintel_ai/state/knowledge_base_state.dart';

void main() {
  group('Phase 9 KnowledgeBaseNotifier Riverpod State Tests', () {
    late ProviderContainer container;
    late MockKnowledgeBaseRepository mockRepo;

    setUp(() {
      EnvConfig.useMockData = true;
      mockRepo = MockKnowledgeBaseRepository();
      container = ProviderContainer(
        overrides: [
          knowledgeBaseRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      EnvConfig.useMockData = false;
      container.dispose();
    });

    test('loadDocuments populates documents directory and meta metrics', () async {
      final notifier = container.read(knowledgeBaseNotifierProvider.notifier);
      await notifier.loadDocuments();

      final state = container.read(knowledgeBaseNotifierProvider);
      expect(state.documents.isNotEmpty, isTrue);
      expect(state.meta.totalIndexedDocuments, greaterThan(0));
      expect(state.meta.totalVectorChunks, greaterThan(0));
    });

    test('indexDocument prevents duplicate in-flight indexing and updates document', () async {
      final notifier = container.read(knowledgeBaseNotifierProvider.notifier);
      await notifier.loadDocuments();

      final success = await notifier.indexDocument('doc_004');
      expect(success, isTrue);

      final state = container.read(knowledgeBaseNotifierProvider);
      final doc = state.documents.firstWhere((d) => d.id == 'doc_004');
      expect(doc.isIndexed, isTrue);
      expect(doc.chunksCount, greaterThan(0));
      expect(state.indexingDocIds.contains('doc_004'), isFalse);
    });

    test('loadDocumentChunks and deleteDocumentIndex manage vector chunks', () async {
      final notifier = container.read(knowledgeBaseNotifierProvider.notifier);
      await notifier.loadDocuments();

      await notifier.loadDocumentChunks('doc_001');
      var state = container.read(knowledgeBaseNotifierProvider);
      expect(state.activeDetail, isNotNull);
      expect(state.activeDetail?.chunks.isNotEmpty, isTrue);

      final deleteSuccess = await notifier.deleteDocumentIndex('doc_001');
      expect(deleteSuccess, isTrue);

      state = container.read(knowledgeBaseNotifierProvider);
      final doc = state.documents.firstWhere((d) => d.id == 'doc_001');
      expect(doc.isIndexed, isFalse);
      expect(doc.chunksCount, 0);
    });

    test('performSemanticSearch ranks results and clearSearch clears them', () async {
      final notifier = container.read(knowledgeBaseNotifierProvider.notifier);

      await notifier.performSemanticSearch('overburden excavation Block 4', topK: 3);
      var state = container.read(knowledgeBaseNotifierProvider);
      expect(state.searchResults.isNotEmpty, isTrue);
      expect(state.searchResults.first.similarity, greaterThan(0.70));

      notifier.clearSearch();
      state = container.read(knowledgeBaseNotifierProvider);
      expect(state.searchResults.isEmpty, isTrue);
    });
  });
}
