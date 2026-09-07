import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/repositories/topic_repository.dart';

void main() {
  group('Phase 10 TopicRepository Tests', () {
    late MockTopicRepository repo;

    setUp(() {
      repo = MockTopicRepository();
    });

    test('getTopics returns catalog of statutory topics', () async {
      final topics = await repo.getTopics();
      expect(topics, isNotEmpty);
      expect(topics.first.name, isNotEmpty);
      expect(topics.first.keywords, isNotEmpty);
    });

    test('analyzeTopics runs topic modeling and discovers topics', () async {
      final result = await repo.analyzeTopics(documentId: 'doc-001');
      expect(result.documentId, 'doc-001');
      expect(result.topicsFound, greaterThan(0));
      expect(result.topics, isNotEmpty);
    });

    test('getTrends returns temporal frequency trends', () async {
      final trends = await repo.getTrends();
      expect(trends, isNotEmpty);
      expect(trends.first.periods, isNotEmpty);
    });

    test('getClusters returns topic clusters with document counts', () async {
      final clusters = await repo.getClusters();
      expect(clusters, isNotEmpty);
      expect(clusters.first.documentsCount, greaterThan(0));
    });

    test('getEntities returns topic-entity associations', () async {
      final entities = await repo.getEntities();
      expect(entities, isNotEmpty);
      expect(entities.first.entities, isNotEmpty);
    });

    test('getEmerging returns accelerating statutory topics', () async {
      final emerging = await repo.getEmerging();
      expect(emerging, isNotEmpty);
      expect(emerging.first.growthRate, greaterThan(0));
      expect(emerging.first.status, 'ACCELERATING');
    });

    test('getChanges returns period shifts with direction', () async {
      final changes = await repo.getChanges();
      expect(changes, isNotEmpty);
      expect(changes.first.direction, anyOf(['EXPANDING', 'CONTRACTING']));
    });
  });
}
