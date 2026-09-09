import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/intelligence_model.dart';
import '../models/topic_model.dart';
import '../network/intelligence_remote_data_source.dart';
import 'base_repository.dart';

/// Abstract contract for Document Intelligence and Cross-Document Analytics.
abstract class IntelligenceRepository {
  Future<IntelligenceOverview> getOverview({
    String? documentId,
    String? timeframe,
  });
  Future<IntelligenceAnalysisResult> analyze({
    String? documentId,
    List<String>? documentIds,
  });
  Future<List<TopicTrend>> getTrends();
  Future<List<IntelligenceEntity>> getEntities({
    String? document,
    String? type,
  });
  Future<List<IntelligenceCluster>> getClusters();
  Future<IntelligenceSimilarityResult> getSimilarity({String? documentId});
  Future<IntelligenceChangesResponse> getChanges({
    String? docA,
    String? docB,
  });
  Future<DocumentEntitiesResponse> getDocumentEntities(String documentId);
  Future<DocumentSimilarityResponse> getDocumentSimilarity(String documentId);
  Future<LinkEvidenceResult> linkEvidence(String documentId);
  Future<List<Map<String, String>>> getAvailableDocuments();
}

/// Concrete implementation delegating to live API or fallback Mock.
class IntelligenceRepositoryImpl extends BaseRepository
    implements IntelligenceRepository {
  final IntelligenceRemoteDataSource _remoteDataSource;
  final IntelligenceRepository? mockRepository;

  IntelligenceRepositoryImpl({
    IntelligenceRemoteDataSource? remoteDataSource,
    this.mockRepository,
  }) : _remoteDataSource =
            remoteDataSource ?? IntelligenceRemoteDataSource();

  @override
  Future<IntelligenceOverview> getOverview({
    String? documentId,
    String? timeframe,
  }) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getOverview(
        documentId: documentId,
        timeframe: timeframe,
      );
    }
    return execute(() => _remoteDataSource.getOverview(
          documentId: documentId,
          timeframe: timeframe,
        ));
  }

  @override
  Future<IntelligenceAnalysisResult> analyze({
    String? documentId,
    List<String>? documentIds,
  }) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.analyze(
        documentId: documentId,
        documentIds: documentIds,
      );
    }
    return execute(() => _remoteDataSource.analyze(
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
  Future<List<IntelligenceEntity>> getEntities({
    String? document,
    String? type,
  }) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getEntities(document: document, type: type);
    }
    return execute(() => _remoteDataSource.getEntities(
          document: document,
          type: type,
        ));
  }

  @override
  Future<List<IntelligenceCluster>> getClusters() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getClusters();
    }
    return execute(() => _remoteDataSource.getClusters());
  }

  @override
  Future<IntelligenceSimilarityResult> getSimilarity({String? documentId}) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getSimilarity(documentId: documentId);
    }
    return execute(() => _remoteDataSource.getSimilarity(documentId: documentId));
  }

  @override
  Future<IntelligenceChangesResponse> getChanges({
    String? docA,
    String? docB,
  }) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getChanges(docA: docA, docB: docB);
    }
    return execute(() => _remoteDataSource.getChanges(docA: docA, docB: docB));
  }

  @override
  Future<DocumentEntitiesResponse> getDocumentEntities(
      String documentId) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getDocumentEntities(documentId);
    }
    return execute(() => _remoteDataSource.getDocumentEntities(documentId));
  }

  @override
  Future<DocumentSimilarityResponse> getDocumentSimilarity(
      String documentId) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getDocumentSimilarity(documentId);
    }
    return execute(() => _remoteDataSource.getDocumentSimilarity(documentId));
  }

  @override
  Future<LinkEvidenceResult> linkEvidence(String documentId) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.linkEvidence(documentId);
    }
    return execute(() => _remoteDataSource.linkEvidence(documentId));
  }

  @override
  Future<List<Map<String, String>>> getAvailableDocuments() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getAvailableDocuments();
    }
    return execute(() => _remoteDataSource.getAvailableDocuments());
  }
}

/// High-fidelity offline Mock Intelligence Repository matching exact schemas.
class MockIntelligenceRepository implements IntelligenceRepository {
  final Duration delay;

  MockIntelligenceRepository({this.delay = const Duration(milliseconds: 150)});

  @override
  Future<IntelligenceOverview> getOverview({
    String? documentId,
    String? timeframe,
  }) async {
    await Future.delayed(delay);
    return const IntelligenceOverview(
      totalEntities: 84,
      totalTopics: 12,
      similarityClusters: 4,
      recentChanges: 6,
    );
  }

  @override
  Future<IntelligenceAnalysisResult> analyze({
    String? documentId,
    List<String>? documentIds,
  }) async {
    await Future.delayed(delay);
    return IntelligenceAnalysisResult(
      documentId: documentId ?? 'doc-001',
      documentName: 'ECL_Rajmahal_Production_Report_Aug_2026.pdf',
      entitiesExtracted: 14,
      topicsExtracted: 3,
      similarDocumentsFound: 2,
    );
  }

  @override
  Future<List<TopicTrend>> getTrends() async {
    await Future.delayed(delay);
    return const [
      TopicTrend(
        id: 'top_trend_1',
        name: 'Coal Dispatch & Evacuation',
        weight: 0.88,
        periods: [
          TopicTrendPeriod(period: '2026-05', count: 12),
          TopicTrendPeriod(period: '2026-06', count: 19),
          TopicTrendPeriod(period: '2026-07', count: 24),
          TopicTrendPeriod(period: '2026-08', count: 31),
        ],
      ),
      TopicTrend(
        id: 'top_trend_2',
        name: 'Overburden Removal & Stripping',
        weight: 0.82,
        periods: [
          TopicTrendPeriod(period: '2026-05', count: 15),
          TopicTrendPeriod(period: '2026-06', count: 18),
          TopicTrendPeriod(period: '2026-07', count: 22),
          TopicTrendPeriod(period: '2026-08', count: 28),
        ],
      ),
      TopicTrend(
        id: 'top_trend_3',
        name: 'DGMS Statutory Safety Compliance',
        weight: 0.74,
        periods: [
          TopicTrendPeriod(period: '2026-05', count: 8),
          TopicTrendPeriod(period: '2026-06', count: 11),
          TopicTrendPeriod(period: '2026-07', count: 14),
          TopicTrendPeriod(period: '2026-08', count: 17),
        ],
      ),
    ];
  }

  @override
  Future<List<IntelligenceEntity>> getEntities({
    String? document,
    String? type,
  }) async {
    await Future.delayed(delay);
    final all = const [
      IntelligenceEntity(
        name: 'Rajmahal OCP',
        type: 'MINE',
        count: 18,
        documents: ['doc-001', 'doc-004'],
      ),
      IntelligenceEntity(
        name: 'Eastern Coalfields Limited',
        type: 'ORGANIZATION',
        count: 24,
        documents: ['doc-001'],
      ),
      IntelligenceEntity(
        name: 'Dhanbad Underground Pit 4',
        type: 'LOCATION',
        count: 15,
        documents: ['doc-002'],
      ),
      IntelligenceEntity(
        name: 'Bharat Coking Coal Limited',
        type: 'ORGANIZATION',
        count: 22,
        documents: ['doc-002'],
      ),
      IntelligenceEntity(
        name: 'Dragline 24/96 Marion',
        type: 'EQUIPMENT',
        count: 9,
        documents: ['doc-001', 'doc-003'],
      ),
      IntelligenceEntity(
        name: 'Surface Miner 2200 SM',
        type: 'EQUIPMENT',
        count: 7,
        documents: ['doc-003'],
      ),
      IntelligenceEntity(
        name: 'DGMS Central Zone',
        type: 'ORGANIZATION',
        count: 13,
        documents: ['doc-002'],
      ),
      IntelligenceEntity(
        name: '1380.0 Tonnes',
        type: 'FIGURE',
        count: 11,
        documents: ['doc-001'],
      ),
    ];

    if (type != null && type.isNotEmpty && type != 'ALL') {
      return all
          .where((e) => e.type.toUpperCase() == type.toUpperCase())
          .toList();
    }
    return all;
  }

  @override
  Future<List<IntelligenceCluster>> getClusters() async {
    await Future.delayed(delay);
    return const [
      IntelligenceCluster(
        clusterId: 'cluster_1',
        name: 'Heavy Extraction & Dragline Operations',
        weight: 0.94,
        keywords: ['dragline', 'overburden', 'shovels', 'stripping ratio'],
        documentsCount: 6,
        relatedTopics: [
          RelatedTopicItem(name: 'Coal Dispatch', strength: 0.85),
          RelatedTopicItem(name: 'Fleet Utilization', strength: 0.78),
        ],
      ),
      IntelligenceCluster(
        clusterId: 'cluster_2',
        name: 'Statutory Safety & Gas Monitoring',
        weight: 0.89,
        keywords: ['methane', 'DGMS', 'ventilation', 'dust suppression'],
        documentsCount: 4,
        relatedTopics: [
          RelatedTopicItem(name: 'Environmental Compliance', strength: 0.81),
        ],
      ),
      IntelligenceCluster(
        clusterId: 'cluster_3',
        name: 'Rail Freight & Weighbridge Logistics',
        weight: 0.86,
        keywords: ['rake loading', 'weighbridge', 'in-transit loss', 'FSI'],
        documentsCount: 5,
        relatedTopics: [
          RelatedTopicItem(name: 'Dispatch Reconciliation', strength: 0.88),
        ],
      ),
      IntelligenceCluster(
        clusterId: 'cluster_4',
        name: 'Environmental Clearance & Water Quality',
        weight: 0.79,
        keywords: ['pH levels', 'turbidity', 'mine runoff', 'air quality'],
        documentsCount: 3,
        relatedTopics: [
          RelatedTopicItem(name: 'Statutory Safety', strength: 0.72),
        ],
      ),
    ];
  }

  @override
  Future<IntelligenceSimilarityResult> getSimilarity({
    String? documentId,
  }) async {
    await Future.delayed(delay);
    return IntelligenceSimilarityResult(
      targetDocument: documentId ?? 'doc-001',
      similar: const [
        SimilarDocumentItem(
          documentId: 'doc-002',
          documentName: 'BCCL_Dhanbad_Safety_Audit_Q2_2026.docx',
          similarity: 0.88,
          commonEntities: [
            'Eastern Coalfields Limited',
            'DGMS Central Zone',
            'Seam VII'
          ],
        ),
        SimilarDocumentItem(
          documentId: 'doc-003',
          documentName: 'SECL_Korba_Dispatch_Weighbridge_Logs.xlsx',
          similarity: 0.79,
          commonEntities: ['Dragline 24/96', 'Raw Coal'],
        ),
      ],
    );
  }

  @override
  Future<IntelligenceChangesResponse> getChanges({
    String? docA,
    String? docB,
  }) async {
    await Future.delayed(delay);
    return const IntelligenceChangesResponse(
      totalChanges: 4,
      added: 1,
      removed: 0,
      modified: 3,
      changes: [
        IntelligenceChangeItem(
          parameter: 'Raw Coal Production',
          docAValue: 1380.0,
          docBValue: 1420.5,
          variancePct: 2.9,
          unit: 'tonnes',
        ),
        IntelligenceChangeItem(
          parameter: 'Overburden Removal',
          docAValue: 4200.0,
          docBValue: 4450.0,
          variancePct: 5.95,
          unit: 'm³',
        ),
        IntelligenceChangeItem(
          parameter: 'Specific Energy Consumption',
          docAValue: 18.2,
          docBValue: 17.6,
          variancePct: -3.3,
          unit: 'kWh/tonne',
        ),
        IntelligenceChangeItem(
          parameter: 'Peak Ground Vibration (PPV)',
          docAValue: 0.0,
          docBValue: 2.4,
          variancePct: 100.0,
          unit: 'mm/s',
        ),
      ],
    );
  }

  @override
  Future<DocumentEntitiesResponse> getDocumentEntities(
      String documentId) async {
    await Future.delayed(delay);
    return const DocumentEntitiesResponse(
      documentName: 'ECL_Rajmahal_Production_Report_Aug_2026.pdf',
      entities: [
        DocumentEntityItem(name: 'Rajmahal OCP', type: 'MINE', count: 18),
        DocumentEntityItem(
            name: 'Eastern Coalfields Limited',
            type: 'ORGANIZATION',
            count: 24),
        DocumentEntityItem(name: 'Seam VII', type: 'LOCATION', count: 8),
      ],
    );
  }

  @override
  Future<DocumentSimilarityResponse> getDocumentSimilarity(
      String documentId) async {
    await Future.delayed(delay);
    return const DocumentSimilarityResponse(
      documentName: 'ECL_Rajmahal_Production_Report_Aug_2026.pdf',
      similar: [
        SimilarDocumentItem(
          documentId: 'doc-002',
          documentName: 'BCCL_Dhanbad_Safety_Audit_Q2_2026.docx',
          similarity: 0.88,
          commonEntities: ['Rajmahal OCP', 'Eastern Coalfields Limited'],
        ),
      ],
    );
  }

  @override
  Future<LinkEvidenceResult> linkEvidence(String documentId) async {
    await Future.delayed(delay);
    return LinkEvidenceResult(
      documentId: documentId,
      linked: true,
      linksCount: 18,
    );
  }

  @override
  Future<List<Map<String, String>>> getAvailableDocuments() async {
    await Future.delayed(delay);
    return const [
      {
        'id': 'doc-001',
        'name': 'MineIntel_MultiPeriod_Test_Report.pdf',
      },
      {
        'id': 'doc-002',
        'name': 'validation_test_bad_data.pdf',
      },
      {
        'id': 'doc-003',
        'name': 'mineintel_test_report.pdf',
      },
    ];
  }
}

/// Global provider for IntelligenceRepository.
final intelligenceRepositoryProvider =
    Provider<IntelligenceRepository>((ref) {
  return IntelligenceRepositoryImpl(
    mockRepository: MockIntelligenceRepository(),
  );
});
