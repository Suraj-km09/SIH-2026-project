import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/repositories/intelligence_repository.dart';

void main() {
  group('Phase 10 IntelligenceRepository Tests', () {
    late MockIntelligenceRepository repo;

    setUp(() {
      repo = MockIntelligenceRepository();
    });

    test('getOverview returns valid data with all counts', () async {
      final overview = await repo.getOverview();
      expect(overview.totalEntities, greaterThan(0));
      expect(overview.totalTopics, greaterThan(0));
      expect(overview.similarityClusters, greaterThan(0));
      expect(overview.recentChanges, greaterThan(0));
    });

    test('analyze triggers document analysis and returns extraction counts', () async {
      final result = await repo.analyze(documentId: 'doc-001');
      expect(result.documentId, 'doc-001');
      expect(result.entitiesExtracted, greaterThan(0));
      expect(result.topicsExtracted, greaterThan(0));
      expect(result.similarDocumentsFound, greaterThanOrEqualTo(0));
    });

    test('getTrends returns temporal topic trends with data points', () async {
      final trends = await repo.getTrends();
      expect(trends, isNotEmpty);
      expect(trends.first.periods, isNotEmpty);
      expect(trends.first.periods.first.count, greaterThan(0));
    });

    test('getEntities returns list of entities and allows filtering', () async {
      final entities = await repo.getEntities();
      expect(entities, isNotEmpty);
      expect(entities.any((e) => e.type == 'MINE'), isTrue);
      expect(entities.any((e) => e.type == 'ORGANIZATION'), isTrue);

      final mineEntities = await repo.getEntities(type: 'MINE');
      expect(mineEntities.every((e) => e.type == 'MINE'), isTrue);
    });

    test('getClusters returns semantic clusters with keywords', () async {
      final clusters = await repo.getClusters();
      expect(clusters, isNotEmpty);
      expect(clusters.first.keywords, isNotEmpty);
      expect(clusters.first.weight, inInclusiveRange(0.0, 1.0));
    });

    test('getSimilarity returns cosine similarity scores >= 0.70', () async {
      final similarity = await repo.getSimilarity(documentId: 'doc-001');
      expect(similarity.targetDocument, 'doc-001');
      expect(similarity.similar, isNotEmpty);
      expect(similarity.similar.first.similarity, greaterThanOrEqualTo(0.70));
    });

    test('getChanges returns cross-document parameter diffs', () async {
      final changesResp = await repo.getChanges(docA: 'doc-001', docB: 'doc-002');
      expect(changesResp.changes, isNotEmpty);
      expect(changesResp.changes.first.parameter, isNotEmpty);
    });

    test('getDocumentEntities returns entities for a specific document', () async {
      final docEntities = await repo.getDocumentEntities('doc-001');
      expect(docEntities.documentName, isNotEmpty);
      expect(docEntities.entities, isNotEmpty);
    });

    test('getDocumentSimilarity returns similarity for a specific document', () async {
      final docSim = await repo.getDocumentSimilarity('doc-001');
      expect(docSim.documentName, isNotEmpty);
      expect(docSim.similar, isNotEmpty);
    });

    test('linkEvidence returns linked count and confirmation', () async {
      final result = await repo.linkEvidence('doc-001');
      expect(result.documentId, 'doc-001');
      expect(result.linksCount, greaterThan(0));
      expect(result.linked, isTrue);
    });
  });
}
