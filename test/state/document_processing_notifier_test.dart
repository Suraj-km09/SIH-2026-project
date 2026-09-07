import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/repositories/document_repository.dart';
import 'package:mineintel_ai/state/document_state.dart';

void main() {
  late ProviderContainer container;
  late MockDocumentRepository mockRepo;

  setUp(() {
    mockRepo = MockDocumentRepository(delay: Duration.zero);
    container = ProviderContainer(
      overrides: [
        documentRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.read(documentProcessingNotifierProvider.notifier).stopAllPolling();
    container.dispose();
  });

  group('DocumentProcessingNotifier Polling & Ingestion Tests', () {
    test('startPolling stops immediately if document is already in terminal state', () async {
      final notifier = container.read(documentProcessingNotifierProvider.notifier);

      // doc-001 is seeded with status 'completed' (terminal)
      await notifier.startPolling('doc-001', interval: const Duration(milliseconds: 50));

      final state = container.read(documentProcessingNotifierProvider);

      // Terminal state stops polling immediately without leaving active timers
      expect(state.isPolling('doc-001'), isFalse);
      expect(state.statuses['doc-001']?.isTerminal, isTrue);
    });

    test('startPolling prevents duplicate polling for the same document', () async {
      final notifier = container.read(documentProcessingNotifierProvider.notifier);

      // doc-003 is seeded with status 'processing' (non-terminal)
      await notifier.startPolling('doc-003', interval: const Duration(seconds: 2));

      var state = container.read(documentProcessingNotifierProvider);
      expect(state.isPolling('doc-003'), isTrue);

      // Call startPolling second time with same ID - must be ignored to prevent duplicate timers
      await notifier.startPolling('doc-003', interval: const Duration(seconds: 2));

      state = container.read(documentProcessingNotifierProvider);
      expect(state.activePollingIds.where((id) => id == 'doc-003').length, 1);

      // Clean stop
      notifier.stopPolling('doc-003');
      state = container.read(documentProcessingNotifierProvider);
      expect(state.isPolling('doc-003'), isFalse);
    });

    test('uploadDocument rejects file with unsupported extension', () async {
      final notifier = container.read(documentProcessingNotifierProvider.notifier);
      final unsupportedFile = _TestFile(
        path: 'C:/docs/malicious_payload.exe',
        sizeBytes: 1024,
      );

      final result = await notifier.uploadDocument(unsupportedFile);
      final state = container.read(documentProcessingNotifierProvider);

      expect(result, isNull);
      expect(state.errorMessage, contains('Unsupported file format'));
    });

    test('uploadDocument rejects file exceeding 50 MB limit', () async {
      final notifier = container.read(documentProcessingNotifierProvider.notifier);
      final hugeFile = _TestFile(
        path: 'C:/docs/too_big.pdf',
        sizeBytes: 52428801, // 50MB + 1
      );

      final result = await notifier.uploadDocument(hugeFile);
      final state = container.read(documentProcessingNotifierProvider);

      expect(result, isNull);
      expect(state.errorMessage, contains('50 MB limit'));
    });

    test('uploadDocument captures 409 Conflict as duplicate document state', () async {
      final notifier = container.read(documentProcessingNotifierProvider.notifier);
      final duplicateFile = _TestFile(
        path: 'C:/docs/duplicate_geology.pdf',
        sizeBytes: 2048,
      );

      final result = await notifier.uploadDocument(duplicateFile);
      final state = container.read(documentProcessingNotifierProvider);

      expect(result, isNull);
      expect(state.isDuplicateConflict, isTrue);
      expect(state.conflictMessage, contains('Duplicate document checksum'));
    });

    test('stopAllPolling cancels all active polling IDs', () async {
      final notifier = container.read(documentProcessingNotifierProvider.notifier);

      await notifier.startPolling('doc-003', interval: const Duration(seconds: 2));
      expect(container.read(documentProcessingNotifierProvider).isPolling('doc-003'), isTrue);

      notifier.stopAllPolling();
      expect(container.read(documentProcessingNotifierProvider).activePollingIds.isEmpty, isTrue);
    });
  });
}

class _TestFile extends Fake implements File {
  @override
  final String path;
  final int sizeBytes;

  _TestFile({required this.path, required this.sizeBytes});

  @override
  Future<int> length() async => sizeBytes;
}
