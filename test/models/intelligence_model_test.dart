import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/models/intelligence_model.dart';

void main() {
  group('Phase 10 Intelligence Models', () {
    test('IntelligenceOverview parses from JSON properly', () {
      final json = {
        'totalEntities': 120,
        'totalTopics': 18,
        'similarityClusters': 5,
        'recentChanges': 4,
      };

      final overview = IntelligenceOverview.fromJson(json);
      expect(overview.totalEntities, 120);
      expect(overview.totalTopics, 18);
      expect(overview.similarityClusters, 5);
      expect(overview.recentChanges, 4);
    });

    test('IntelligenceAnalysisResult parses extracted entities and topics', () {
      final json = {
        'documentId': 'doc-101',
        'documentName': 'Annual Environmental Audit',
        'entitiesExtracted': 15,
        'topicsExtracted': 4,
        'similarDocumentsFound': 2,
      };

      final result = IntelligenceAnalysisResult.fromJson(json);
      expect(result.documentId, 'doc-101');
      expect(result.documentName, 'Annual Environmental Audit');
      expect(result.entitiesExtracted, 15);
      expect(result.topicsExtracted, 4);
      expect(result.similarDocumentsFound, 2);
    });

    test('IntelligenceEntity parses properly with source occurrences', () {
      final json = {
        'name': 'Gevra Open Cast Mine',
        'type': 'MINE',
        'count': 42,
        'documents': ['doc-001', 'doc-002'],
      };

      final entity = IntelligenceEntity.fromJson(json);
      expect(entity.name, 'Gevra Open Cast Mine');
      expect(entity.type, 'MINE');
      expect(entity.count, 42);
      expect(entity.documents, contains('doc-001'));
    });

    test('IntelligenceCluster parses properly', () {
      final json = {
        'clusterId': 'clust-env',
        'name': 'DGMS Safety Compliance',
        'weight': 0.85,
        'keywords': ['safety', 'ventilation', 'dust control'],
        'documentsCount': 12,
        'relatedTopics': [
          {'name': 'Ventilation Standards', 'strength': 0.92},
        ],
      };

      final cluster = IntelligenceCluster.fromJson(json);
      expect(cluster.clusterId, 'clust-env');
      expect(cluster.name, 'DGMS Safety Compliance');
      expect(cluster.keywords.length, 3);
      expect(cluster.documentsCount, 12);
      expect(cluster.relatedTopics.first.strength, 0.92);
    });

    test('IntelligenceSimilarityResult parses similarity matches', () {
      final json = {
        'targetDocument': 'doc-001',
        'similar': [
          {
            'documentId': 'doc-002',
            'documentName': 'Dipka Mine Monthly Report',
            'similarity': 0.88,
            'commonEntities': ['Gevra Mine', 'SECL'],
          },
        ],
      };

      final result = IntelligenceSimilarityResult.fromJson(json);
      expect(result.targetDocument, 'doc-001');
      expect(result.similar.length, 1);
      expect(result.similar.first.documentId, 'doc-002');
      expect(result.similar.first.similarity, 0.88);
      expect(result.similar.first.commonEntities, contains('SECL'));
    });

    test('IntelligenceChangesResponse parses parameter diffs', () {
      final json = {
        'totalChanges': 1,
        'added': 0,
        'removed': 0,
        'modified': 1,
        'changes': [
          {
            'parameter': 'Stripping Ratio',
            'docAValue': 2.14,
            'docBValue': 2.45,
            'variancePct': 14.48,
            'unit': 'm3/tonne',
          },
        ],
      };

      final resp = IntelligenceChangesResponse.fromJson(json);
      expect(resp.totalChanges, 1);
      expect(resp.modified, 1);
      expect(resp.changes.length, 1);
      expect(resp.changes.first.parameter, 'Stripping Ratio');
      expect(resp.changes.first.variancePct, 14.48);
    });

    test('LinkEvidenceResult parses properly', () {
      final json = {
        'documentId': 'doc-001',
        'linked': true,
        'linksCount': 8,
      };

      final linkResult = LinkEvidenceResult.fromJson(json);
      expect(linkResult.documentId, 'doc-001');
      expect(linkResult.linked, isTrue);
      expect(linkResult.linksCount, 8);
    });
  });
}
