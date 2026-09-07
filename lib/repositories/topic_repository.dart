import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/intelligence_model.dart';
import '../models/topic_model.dart';
import '../network/topic_remote_data_source.dart';
import 'base_repository.dart';

/// Abstract contract for Topic Modeling & Taxonomy Discovery.
abstract class TopicRepository {
  Future<List<TopicModel>> getTopics();
  Future<TopicAnalysisResult> analyzeTopics({
    String? documentId,
    List<String>? documentIds,
  });
  Future<List<TopicTrend>> getTrends();
  Future<List<TopicCluster>> getClusters();
  Future<List<TopicEntityAssociation>> getEntities();
  Future<List<EmergingTopic>> getEmerging();
  Future<List<TopicChange>> getChanges();
}

/// Concrete implementation delegating to live API or Mock repository.
class TopicRepositoryImpl extends BaseRepository implements TopicRepository {
  final TopicRemoteDataSource _remoteDataSource;
  final TopicRepository? mockRepository;

  TopicRepositoryImpl({
    TopicRemoteDataSource? remoteDataSource,
    this.mockRepository,
  }) : _remoteDataSource = remoteDataSource ?? TopicRemoteDataSource();

  @override
  Future<List<TopicModel>> getTopics() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getTopics();
    }
    return execute(() => _remoteDataSource.getTopics());
  }

  @override
  Future<TopicAnalysisResult> analyzeTopics({
    String? documentId,
    List<String>? documentIds,
  }) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.analyzeTopics(
        documentId: documentId,
        documentIds: documentIds,
      );
    }
    return execute(() => _remoteDataSource.analyzeTopics(
          documentId: documentId,
          documentIds: documentIds,
        ));
  }

  @override
  Future<List<TopicTrend>> getTrends() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getTrends();
    }
    return execute(() => _remoteDataSource.getTrends());
  }

  @override
  Future<List<TopicCluster>> getClusters() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getClusters();
    }
    return execute(() => _remoteDataSource.getClusters());
  }

  @override
  Future<List<TopicEntityAssociation>> getEntities() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getEntities();
    }
    return execute(() => _remoteDataSource.getEntities());
  }

  @override
  Future<List<EmergingTopic>> getEmerging() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getEmerging();
    }
    return execute(() => _remoteDataSource.getEmerging());
  }

  @override
  Future<List<TopicChange>> getChanges() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getChanges();
    }
    return execute(() => _remoteDataSource.getChanges());
  }
}

/// High-fidelity offline Mock Topic Repository.
class MockTopicRepository implements TopicRepository {
  final Duration delay;

  MockTopicRepository({this.delay = const Duration(milliseconds: 150)});

  @override
  Future<List<TopicModel>> getTopics() async {
    await Future.delayed(delay);
    return const [
      TopicModel(
        id: 'top_001',
        name: 'Coal Production & Extraction',
        description:
            'Metrics and trends related to raw coal production volume, seams, and daily extraction rates.',
        keywords: ['coal', 'production', 'raw', 'extraction', 'run-of-mine'],
        weight: 0.95,
        documentCount: 8,
        mentionCount: 64,
        relevanceScore: 0.98,
      ),
      TopicModel(
        id: 'top_002',
        name: 'Overburden Evacuation & Stripping',
        description:
            'Topsoil and rock removal metrics, composite stripping ratios, dragline efficiency and dumper cycles.',
        keywords: ['overburden', 'stripping ratio', 'dragline', 'bench'],
        weight: 0.88,
        documentCount: 6,
        mentionCount: 42,
        relevanceScore: 0.91,
      ),
      TopicModel(
        id: 'top_003',
        name: 'DGMS Statutory Safety Directives',
        description:
            'Safety audits, gas detection protocols, slope stability, and occupational health compliance.',
        keywords: ['DGMS', 'safety', 'methane', 'ventilation', 'audit'],
        weight: 0.82,
        documentCount: 5,
        mentionCount: 38,
        relevanceScore: 0.87,
      ),
      TopicModel(
        id: 'top_004',
        name: 'Rail & Weighbridge Logistics',
        description:
            'Weighbridge calibration reconciliation, rake allotments, coal transportation, and dispatch demurrage.',
        keywords: ['dispatch', 'weighbridge', 'rake', 'loading', 'railways'],
        weight: 0.79,
        documentCount: 7,
        mentionCount: 49,
        relevanceScore: 0.84,
      ),
      TopicModel(
        id: 'top_005',
        name: 'Environmental Quality & Mine Water',
        description:
            'Air quality particulate matter (PM10/PM2.5), effluent discharge pH, afforestation, and topsoil restoration.',
        keywords: ['environmental', 'PM10', 'effluent', 'reclamation', 'water'],
        weight: 0.71,
        documentCount: 4,
        mentionCount: 26,
        relevanceScore: 0.76,
      ),
    ];
  }

  @override
  Future<TopicAnalysisResult> analyzeTopics({
    String? documentId,
    List<String>? documentIds,
  }) async {
    await Future.delayed(delay);
    final all = await getTopics();
    return TopicAnalysisResult(
      documentId: documentId ?? 'doc-001',
      topicsFound: 3,
      topics: all.take(3).toList(),
    );
  }

  @override
  Future<List<TopicTrend>> getTrends() async {
    await Future.delayed(delay);
    return const [
      TopicTrend(
        id: 'top_trend_1',
        name: 'Coal Dispatch',
        weight: 0.85,
        periods: [
          TopicTrendPeriod(period: '2026-05', count: 14),
          TopicTrendPeriod(period: '2026-06', count: 20),
          TopicTrendPeriod(period: '2026-07', count: 25),
          TopicTrendPeriod(period: '2026-08', count: 32),
        ],
      ),
      TopicTrend(
        id: 'top_trend_2',
        name: 'Safety Audits',
        weight: 0.72,
        periods: [
          TopicTrendPeriod(period: '2026-05', count: 6),
          TopicTrendPeriod(period: '2026-06', count: 9),
          TopicTrendPeriod(period: '2026-07', count: 12),
          TopicTrendPeriod(period: '2026-08', count: 15),
        ],
      ),
    ];
  }

  @override
  Future<List<TopicCluster>> getClusters() async {
    await Future.delayed(delay);
    return const [
      TopicCluster(
        clusterId: 'topic_cluster_1',
        name: 'Coal Production & Extraction',
        weight: 0.92,
        keywords: ['coal', 'production', 'extraction'],
        documentsCount: 8,
        relatedTopics: [
          RelatedTopicItem(name: 'Coal Dispatch', strength: 0.82),
          RelatedTopicItem(name: 'Overburden Evacuation', strength: 0.75),
        ],
      ),
      TopicCluster(
        clusterId: 'topic_cluster_2',
        name: 'Statutory Safety & Gas Monitoring',
        weight: 0.85,
        keywords: ['methane', 'ventilation', 'DGMS'],
        documentsCount: 5,
        relatedTopics: [
          RelatedTopicItem(name: 'Environmental Quality', strength: 0.78),
        ],
      ),
    ];
  }

  @override
  Future<List<TopicEntityAssociation>> getEntities() async {
    await Future.delayed(delay);
    return const [
      TopicEntityAssociation(
        topicId: 'top_001',
        topicName: 'Coal Production & Extraction',
        entitiesCount: 3,
        entities: [
          TopicEntityItem(name: 'Rajmahal OCP', type: 'MINE', mentions: 18),
          TopicEntityItem(
              name: 'Eastern Coalfields Limited',
              type: 'ORGANIZATION',
              mentions: 24),
          TopicEntityItem(name: 'Seam VII', type: 'LOCATION', mentions: 8),
        ],
      ),
      TopicEntityAssociation(
        topicId: 'top_003',
        topicName: 'DGMS Statutory Safety Directives',
        entitiesCount: 2,
        entities: [
          TopicEntityItem(
              name: 'DGMS Central Zone', type: 'REGULATOR', mentions: 13),
          TopicEntityItem(
              name: 'Dhanbad Underground Pit 4',
              type: 'LOCATION',
              mentions: 15),
        ],
      ),
    ];
  }

  @override
  Future<List<EmergingTopic>> getEmerging() async {
    await Future.delayed(delay);
    return const [
      EmergingTopic(
        topicId: 'top_002',
        name: 'Overburden Evacuation',
        weight: 0.78,
        growthRate: 45.2,
        latestPeriod: 'August 2026',
        status: 'ACCELERATING',
      ),
      EmergingTopic(
        topicId: 'top_006',
        name: 'Methane Drainage & Flare Systems',
        weight: 0.71,
        growthRate: 38.6,
        latestPeriod: 'August 2026',
        status: 'ACCELERATING',
      ),
      EmergingTopic(
        topicId: 'top_007',
        name: 'Continuous Surface Miners',
        weight: 0.64,
        growthRate: 18.3,
        latestPeriod: 'August 2026',
        status: 'STABLE',
      ),
    ];
  }

  @override
  Future<List<TopicChange>> getChanges() async {
    await Future.delayed(delay);
    return const [
      TopicChange(
        topicId: 'top_003',
        name: 'Safety Compliance',
        fromPeriod: 'July 2026',
        toPeriod: 'August 2026',
        countChange: 8,
        weightChange: 0.12,
        direction: 'EXPANDING',
      ),
      TopicChange(
        topicId: 'top_004',
        name: 'Coal Dispatch & Freight Reconciliation',
        fromPeriod: 'July 2026',
        toPeriod: 'August 2026',
        countChange: 14,
        weightChange: 0.18,
        direction: 'EXPANDING',
      ),
      TopicChange(
        topicId: 'top_008',
        name: 'Manual Weighbridge Logging',
        fromPeriod: 'July 2026',
        toPeriod: 'August 2026',
        countChange: -6,
        weightChange: -0.11,
        direction: 'CONTRACTING',
      ),
    ];
  }
}

/// Global provider for TopicRepository.
final topicRepositoryProvider = Provider<TopicRepository>((ref) {
  return TopicRepositoryImpl(
    mockRepository: MockTopicRepository(),
  );
});
