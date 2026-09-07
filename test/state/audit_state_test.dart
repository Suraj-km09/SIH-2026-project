import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/repositories/audit_repository.dart';
import 'package:mineintel_ai/state/audit_state.dart';

void main() {
  group('Phase 11 Audit Riverpod State Tests', () {
    late ProviderContainer container;
    late MockAuditRepository mockRepo;

    setUp(() {
      EnvConfig.useMockData = true;
      mockRepo = MockAuditRepository();
      container = ProviderContainer(
        overrides: [
          auditRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('AuditNotifier loads logs and stats successfully', () async {
      final notifier = container.read(auditNotifierProvider.notifier);
      await notifier.loadStats();
      await notifier.loadLogs();

      final state = container.read(auditNotifierProvider);
      expect(state.logs, isNotEmpty);
      expect(state.stats, isNotNull);
      expect(state.stats!.totalEvents, greaterThan(0));
    });

    test('AuditNotifier filters by status, action, and search', () async {
      final notifier = container.read(auditNotifierProvider.notifier);
      await notifier.loadLogs();

      notifier.setStatus('FAILED');
      await Future.delayed(const Duration(milliseconds: 200));
      final failedState = container.read(auditNotifierProvider);
      expect(failedState.logs.every((l) => l.isFailed), isTrue);

      notifier.setStatus('ALL');
      notifier.setAction('APPROVE_REPORT');
      await Future.delayed(const Duration(milliseconds: 200));
      final actionState = container.read(auditNotifierProvider);
      expect(
        actionState.logs.every((l) => l.action == 'APPROVE_REPORT'),
        isTrue,
      );

      notifier.setAction('ALL');
      notifier.setSearch('vishal');
      await Future.delayed(const Duration(milliseconds: 200));
      final searchState = container.read(auditNotifierProvider);
      expect(
        searchState.logs.every((l) => l.user.username.contains('vishal')),
        isTrue,
      );
    });

    test('AuditNotifier filters by entity: user, document, report', () async {
      final notifier = container.read(auditNotifierProvider.notifier);

      notifier.filterByUser('64e0a1b2c3d4e5f6a7b8c9d0');
      await Future.delayed(const Duration(milliseconds: 200));
      final userState = container.read(auditNotifierProvider);
      expect(userState.hasEntityFilter, isTrue);
      expect(userState.entityFilterType, 'user');
      expect(
        userState.logs.every((l) => l.user.id == '64e0a1b2c3d4e5f6a7b8c9d0'),
        isTrue,
      );

      notifier.clearEntityFilter();
      await Future.delayed(const Duration(milliseconds: 200));
      final clearedState = container.read(auditNotifierProvider);
      expect(clearedState.hasEntityFilter, isFalse);

      notifier.filterByDocument('doc-bokaro-survey-01');
      await Future.delayed(const Duration(milliseconds: 200));
      final docState = container.read(auditNotifierProvider);
      expect(docState.entityFilterType, 'document');
      expect(
        docState.logs.every((l) =>
            l.resource == 'Document' && l.resourceId == 'doc-bokaro-survey-01'),
        isTrue,
      );

      notifier.filterByReport('rep-q2-coal-2026');
      await Future.delayed(const Duration(milliseconds: 200));
      final repState = container.read(auditNotifierProvider);
      expect(repState.entityFilterType, 'report');
      expect(
        repState.logs.every(
            (l) => l.resource == 'Report' && l.resourceId == 'rep-q2-coal-2026'),
        isTrue,
      );
    });

    test('AuditNotifier getLogDetail loads single log detail', () async {
      final notifier = container.read(auditNotifierProvider.notifier);
      final log = await notifier.getLogDetail('aud-001');

      expect(log, isNotNull);
      expect(log!.id, 'aud-001');
      expect(container.read(auditNotifierProvider).selectedLog?.id, 'aud-001');
    });

    test('AuditNotifier exportAudit triggers statutory export', () async {
      final notifier = container.read(auditNotifierProvider.notifier);
      final res = await notifier.exportAudit('csv');

      expect(res, isNotNull);
      expect(res!.format, 'csv');
      expect(container.read(auditNotifierProvider).exportMessage, isNotNull);
    });
  });
}
