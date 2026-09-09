import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/models/command_centre_model.dart';
import 'package:mineintel_ai/repositories/command_centre_repository.dart';

void main() {
  group('CommandCentreRepository & Mock Tests', () {
    late MockCommandCentreRepository repository;

    setUp(() {
      repository = MockCommandCentreRepository();
    });

    test('getOverview returns valid statistics and system metrics', () async {
      final overview = await repository.getOverview();

      expect(overview.docsProcessed.value, 10);
      expect(overview.validationScore.display, '90.9%');
      expect(overview.openIssues.value, 5);
      expect(overview.reportsGenerated.value, 35);
      expect(overview.systemMetrics.totalDocuments, 11);
      expect(overview.systemMetrics.activeUsers, 45);
    });

    test('getPipeline returns 5-step telemetry and health summary', () async {
      final pipeline = await repository.getPipeline();

      expect(pipeline.upload.status, 'normal');
      expect(pipeline.validation.count, 5);
      expect(pipeline.indexing.count, 7);
      expect(pipeline.completed.count, 5);
      expect(pipeline.healthSummary.pipelineSuccessRate, 91);
      expect(pipeline.healthSummary.activeWorkers, 1);
    });

    test('getStatus returns operational status and microservice matrix', () async {
      final status = await repository.getStatus();

      expect(status.overallStatus, 'OPERATIONAL');
      expect(status.database.name, 'MongoDB Atlas');
      expect(status.database.status, 'connected');
      expect(status.database.latencyMs, 12);
      expect(status.llmEngine.model, 'gemini-1.5-flash');
      expect(status.agentOrchestrator.supportedAgents.length, 5);
    });

    test('getAttentionItems returns pending queues with priorities', () async {
      final attention = await repository.getAttentionItems();

      expect(attention.totalItems, 4);
      expect(attention.highPriorityCount, 2);
      expect(attention.items.length, 4);
      expect(attention.items.first.priority, 'high');
      expect(attention.items.first.category, 'DOCUMENT_PROCESSING');
    });

    test('getActivity returns audit trail stream events', () async {
      final activities = await repository.getActivity();

      expect(activities.isNotEmpty, true);
      expect(activities.first.source, 'AUDIT_TRAIL');
      expect(activities.first.action, 'DOCUMENT_INGEST');
    });

    test('CommandCentreOverviewModel round-trip serialization', () {
      const model = CommandCentreOverviewModel(
        docsProcessed: CommandCentreStatItem(value: 5, display: '5', label: 'Docs'),
        validationScore: CommandCentreStatItem(value: 95.0, display: '95%', label: 'Score'),
        openIssues: CommandCentreStatItem(value: 1, display: '1', label: 'Issues'),
        reportsGenerated: CommandCentreStatItem(value: 8, display: '8', label: 'Reports'),
        systemMetrics: CommandCentreSystemMetrics(
          totalDocuments: 10,
          totalExtractedRecords: 50,
          activeUsers: 3,
          failedDocuments: 0,
          uptimeSeconds: 100,
          memoryUsageMb: 120,
        ),
        timestamp: '2026-09-09T00:00:00Z',
      );

      final json = model.toJson();
      final fromJson = CommandCentreOverviewModel.fromJson(json);

      expect(fromJson.docsProcessed.value, 5);
      expect(fromJson.validationScore.display, '95%');
      expect(fromJson.systemMetrics.activeUsers, 3);
    });
  });
}
