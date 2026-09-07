import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/models/topic_model.dart';

void main() {
  group('Phase 10 Topic Models', () {
    test('TopicModel parses properly', () {
      final json = {
        'id': 'top-1',
        'name': 'Coal Extraction Efficiency',
        'description': 'Production throughput, shovel performance, and ROM coal metrics.',
        'keywords': ['extraction', 'shovel', 'ROM', 'tonnage'],
        'relevanceScore': 0.94,
        'documentCount': 14,
        'mentionCount': 128,
        'weight': 0.85,
      };

      final topic = TopicModel.fromJson(json);
      expect(topic.id, 'top-1');
      expect(topic.name, 'Coal Extraction Efficiency');
      expect(topic.keywords.length, 4);
      expect(topic.relevanceScore, 0.94);
      expect(topic.documentCount, 14);
      expect(topic.mentionCount, 128);
      expect(topic.weight, 0.85);
    });

    test('TopicTrend parses temporal frequencies properly', () {
      final json = {
        'id': 'top-1',
        'name': 'Environmental Dust Control',
        'weight': 0.82,
        'periods': [
          {'period': '2026-05', 'count': 12},
          {'period': '2026-06', 'count': 18},
        ],
      };

      final trend = TopicTrend.fromJson(json);
      expect(trend.id, 'top-1');
      expect(trend.name, 'Environmental Dust Control');
      expect(trend.periods.length, 2);
      expect(trend.periods[0].period, '2026-05');
      expect(trend.periods[1].count, 18);
    });

    test('EmergingTopic parses acceleration metrics', () {
      final json = {
        'topicId': 'em-1',
        'name': 'Overburden Spoil Stability',
        'growthRate': 48.6,
        'latestPeriod': '2026-08',
        'weight': 0.91,
        'status': 'ACCELERATING',
      };

      final emerging = EmergingTopic.fromJson(json);
      expect(emerging.topicId, 'em-1');
      expect(emerging.growthRate, 48.6);
      expect(emerging.latestPeriod, '2026-08');
      expect(emerging.status, 'ACCELERATING');
    });

    test('TopicChange parses period-to-period shifts', () {
      final json = {
        'topicId': 'top-env',
        'name': 'PM10 Ambient Air Standards',
        'fromPeriod': 'July 2026',
        'toPeriod': 'August 2026',
        'countChange': 24,
        'weightChange': 0.18,
        'direction': 'EXPANDING',
      };

      final change = TopicChange.fromJson(json);
      expect(change.topicId, 'top-env');
      expect(change.name, 'PM10 Ambient Air Standards');
      expect(change.fromPeriod, 'July 2026');
      expect(change.toPeriod, 'August 2026');
      expect(change.countChange, 24);
      expect(change.direction, 'EXPANDING');
    });

    test('TopicEntityAssociation parses topic to entity links', () {
      final json = {
        'topicId': 'top-prod',
        'topicName': 'Overburden Removal',
        'entitiesCount': 1,
        'entities': [
          {'name': 'Gevra Mine', 'type': 'MINE', 'mentions': 34},
        ],
      };

      final assoc = TopicEntityAssociation.fromJson(json);
      expect(assoc.topicId, 'top-prod');
      expect(assoc.entities.length, 1);
      expect(assoc.entities.first.name, 'Gevra Mine');
      expect(assoc.entities.first.mentions, 34);
    });
  });
}
