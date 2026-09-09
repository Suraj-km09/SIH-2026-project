import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/command_centre_model.dart';
import '../network/command_centre_remote_data_source.dart';
import 'base_repository.dart';

/// Abstract contract for Command Centre Telemetry & Monitoring.
abstract class CommandCentreRepository {
  Future<CommandCentreOverviewModel> getOverview();
  Future<CommandCentrePipelineModel> getPipeline();
  Future<CommandCentreStatusModel> getStatus();
  Future<CommandCentreAttentionModel> getAttentionItems();
  Future<List<CommandCentreActivityModel>> getActivity();
}

/// Concrete repository delegating to live API or high-fidelity mock fallback.
class CommandCentreRepositoryImpl extends BaseRepository
    implements CommandCentreRepository {
  final CommandCentreRemoteDataSource _remoteDataSource;
  final CommandCentreRepository? mockRepository;

  CommandCentreRepositoryImpl({
    CommandCentreRemoteDataSource? remoteDataSource,
    this.mockRepository,
  }) : _remoteDataSource = remoteDataSource ?? CommandCentreRemoteDataSource();

  @override
  Future<CommandCentreOverviewModel> getOverview() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getOverview();
    }
    try {
      return await execute(() => _remoteDataSource.getOverview());
    } catch (_) {
      if (mockRepository != null) return mockRepository!.getOverview();
      rethrow;
    }
  }

  @override
  Future<CommandCentrePipelineModel> getPipeline() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getPipeline();
    }
    try {
      return await execute(() => _remoteDataSource.getPipeline());
    } catch (_) {
      if (mockRepository != null) return mockRepository!.getPipeline();
      rethrow;
    }
  }

  @override
  Future<CommandCentreStatusModel> getStatus() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getStatus();
    }
    try {
      return await execute(() => _remoteDataSource.getStatus());
    } catch (_) {
      if (mockRepository != null) return mockRepository!.getStatus();
      rethrow;
    }
  }

  @override
  Future<CommandCentreAttentionModel> getAttentionItems() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getAttentionItems();
    }
    try {
      return await execute(() => _remoteDataSource.getAttentionItems());
    } catch (_) {
      if (mockRepository != null) return mockRepository!.getAttentionItems();
      rethrow;
    }
  }

  @override
  Future<List<CommandCentreActivityModel>> getActivity() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getActivity();
    }
    try {
      return await execute(() => _remoteDataSource.getActivity());
    } catch (_) {
      if (mockRepository != null) return mockRepository!.getActivity();
      rethrow;
    }
  }
}

/// Offline mock repository matching exact cloud payload schemas.
class MockCommandCentreRepository implements CommandCentreRepository {
  final Duration delay;

  const MockCommandCentreRepository({this.delay = Duration.zero});

  @override
  Future<CommandCentreOverviewModel> getOverview() async {
    if (delay > Duration.zero) await Future.delayed(delay);
    return const CommandCentreOverviewModel(
      docsProcessed: CommandCentreStatItem(
        value: 10,
        display: '10',
        label: 'Docs Processed',
      ),
      validationScore: CommandCentreStatItem(
        value: 90.9,
        display: '90.9%',
        label: 'Validation Score',
      ),
      openIssues: CommandCentreStatItem(
        value: 5,
        display: '5',
        label: 'Open Issues',
      ),
      reportsGenerated: CommandCentreStatItem(
        value: 35,
        display: '35',
        label: 'Reports Generated',
      ),
      systemMetrics: CommandCentreSystemMetrics(
        totalDocuments: 11,
        totalExtractedRecords: 78,
        activeUsers: 45,
        failedDocuments: 1,
        uptimeSeconds: 320,
        memoryUsageMb: 156,
      ),
      timestamp: '2026-09-09T06:55:00.000Z',
    );
  }

  @override
  Future<CommandCentrePipelineModel> getPipeline() async {
    if (delay > Duration.zero) await Future.delayed(delay);
    return const CommandCentrePipelineModel(
      upload: PipelineStageItem(
        count: 0,
        status: 'normal',
        description: 'Files queued for initial ingestion and text extraction',
      ),
      extraction: PipelineStageItem(
        count: 0,
        status: 'normal',
        description: 'Gemini OCR and entity extraction in progress',
      ),
      validation: PipelineStageItem(
        count: 5,
        status: 'normal',
        description: 'Records extracted, pending validation checks or user sign-off',
      ),
      indexing: PipelineStageItem(
        count: 7,
        status: 'normal',
        description: 'Vector embeddings indexed in Knowledge Base',
      ),
      completed: PipelineStageItem(
        count: 5,
        status: 'healthy',
        description: 'Fully processed and searchable in RAG',
      ),
      healthSummary: CommandCentreHealthSummary(
        totalInPipeline: 11,
        failedExtractions: 1,
        pipelineSuccessRate: 91,
        activeWorkers: 1,
      ),
      timestamp: '2026-09-09T06:55:00.000Z',
    );
  }

  @override
  Future<CommandCentreStatusModel> getStatus() async {
    if (delay > Duration.zero) await Future.delayed(delay);
    return const CommandCentreStatusModel(
      overallStatus: 'OPERATIONAL',
      database: MicroserviceItem(
        name: 'MongoDB Atlas',
        status: 'connected',
        latencyMs: 12,
      ),
      ragEngine: MicroserviceItem(
        name: 'Vector Search & Knowledge Base',
        status: 'ready',
        totalIndexedChunks: 7,
      ),
      llmEngine: MicroserviceItem(
        name: 'Gemini AI Engine',
        status: 'ready',
        model: 'gemini-1.5-flash',
      ),
      agentOrchestrator: MicroserviceItem(
        name: 'Multi-Agent Command Framework',
        status: 'active',
        supportedAgents: [
          'ExtractionAgent',
          'ValidationAgent',
          'RAGRetrievalAgent',
          'ReportGeneratorAgent',
          'IntelligenceAgent',
        ],
      ),
      nodeVersion: 'v20.20.2',
      platform: 'linux',
      uptimeSeconds: 320,
      timestamp: '2026-09-09T06:55:00.000Z',
    );
  }

  @override
  Future<CommandCentreAttentionModel> getAttentionItems() async {
    if (delay > Duration.zero) await Future.delayed(delay);
    return const CommandCentreAttentionModel(
      totalItems: 4,
      highPriorityCount: 2,
      mediumPriorityCount: 2,
      items: [
        AttentionItemModel(
          id: 'doc-fail-6a9e23669f285431bbd7119d',
          category: 'DOCUMENT_PROCESSING',
          priority: 'high',
          title: 'Processing Failed: raw_coal_aug26.pdf',
          description: 'OCR Error: Version mismatch encountered during text extraction.',
          actionRequired: 'Retry extraction or re-upload document',
          resourceId: '6a9e23669f285431bbd7119d',
          timestamp: '2026-09-07T02:37:26.503Z',
        ),
        AttentionItemModel(
          id: 'val-crit-6a91affd7405965eac5dbe0c',
          category: 'DATA_VALIDATION',
          priority: 'high',
          title: 'Critical Validation Issue: Negative Output',
          description: 'Numeric value for "Coal Production" cannot be negative: -500.',
          actionRequired: 'Resolve validation conflict or adjust value',
          resourceId: '6a91affd7405965eac5dbe0c',
          timestamp: '2026-08-28T15:57:49.943Z',
        ),
        AttentionItemModel(
          id: 'rep-review-6a9bc1f87c752c4daf87eb7a',
          category: 'REPORT_APPROVAL',
          priority: 'medium',
          title: 'Report Awaiting Review: Monthly Statutory Report - August 2026',
          description: 'Submitted for formal verification.',
          actionRequired: 'Approve or reject report',
          resourceId: '6a9bc1f87c752c4daf87eb7a',
          timestamp: '2026-09-05T07:17:12.839Z',
        ),
        AttentionItemModel(
          id: 'rep-reject-6a9e33e30f061aeadc8cdb85',
          category: 'REPORT_REVISION',
          priority: 'medium',
          title: 'Report Rejected: Production Variance Audit',
          description: 'Reviewer feedback: "Requires adjustment in production period comparison"',
          actionRequired: 'Revise content and re-submit for review',
          resourceId: '6a9e33e30f061aeadc8cdb85',
          timestamp: '2026-09-07T03:58:45.455Z',
        ),
      ],
    );
  }

  @override
  Future<List<CommandCentreActivityModel>> getActivity() async {
    if (delay > Duration.zero) await Future.delayed(delay);
    return [
      const CommandCentreActivityModel(
        id: 'act-001',
        source: 'AUDIT_TRAIL',
        action: 'DOCUMENT_INGEST',
        actor: 'specialist_operator',
        description: 'Uploaded ECL_August_Production_Summary.pdf for OCR extraction',
        timestamp: '2026-09-09T06:50:00.000Z',
      ),
      const CommandCentreActivityModel(
        id: 'act-002',
        source: 'AUDIT_TRAIL',
        action: 'REPORT_GENERATE',
        actor: 'gemini_agent',
        description: 'Synthesized statutory monthly production report for Rajmahal OCP',
        timestamp: '2026-09-09T06:45:00.000Z',
      ),
      const CommandCentreActivityModel(
        id: 'act-003',
        source: 'AUDIT_TRAIL',
        action: 'VALIDATION_CHECK',
        actor: 'validation_engine',
        description: 'Quality score calculated at 90.9% across 78 extracted parameters',
        timestamp: '2026-09-09T06:40:00.000Z',
      ),
    ];
  }
}

/// Provider for CommandCentreRepository.
final commandCentreRepositoryProvider =
    Provider<CommandCentreRepository>((ref) {
  return CommandCentreRepositoryImpl(
    mockRepository: MockCommandCentreRepository(),
  );
});
