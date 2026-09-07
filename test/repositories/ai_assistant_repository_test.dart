import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/models/ai_assistant_model.dart';
import 'package:mineintel_ai/repositories/ai_assistant_repository.dart';

void main() {
  group('Phase 9 AiAssistantRepository & MockAiAssistantRepository Tests', () {
    late AiAssistantRepository repository;

    setUp(() {
      EnvConfig.useMockData = true;
      repository = AiAssistantRepositoryImpl(
        mockRepository: MockAiAssistantRepository(),
      );
    });

    tearDown(() {
      EnvConfig.useMockData = false;
    });

    test('query returns synthesized RAG answer with citations and evidence', () async {
      final response = await repository.query(
        const AiAssistantQueryRequest(
          query: 'What was the raw coal production for Rajmahal OCP?',
        ),
      );

      expect(response.answer.isNotEmpty, isTrue);
      expect(response.confidence, greaterThanOrEqualTo(0.85));
      expect(response.citations.isNotEmpty, isTrue);
      expect(response.evidence.isNotEmpty, isTrue);
      expect(response.insufficientEvidence, isFalse);
    });

    test('query returns calculation metadata when variance is computed', () async {
      final response = await repository.query(
        const AiAssistantQueryRequest(
          query: 'Show overburden removal volume at Rajmahal',
        ),
      );

      expect(response.calculation, isNotNull);
      expect(response.calculation?.variance, isNotNull);
      expect(response.calculation?.target, isNotNull);
    });

    test('query explicitly marks insufficientEvidence for unindexed domains', () async {
      final response = await repository.query(
        const AiAssistantQueryRequest(
          query: 'What is the gold and copper assay grade?',
        ),
      );

      expect(response.insufficientEvidence, isTrue);
      expect(response.confidence, lessThan(0.50));
      expect(response.answer, contains('Insufficient Evidence in Knowledge Base'));
    });

    test('getHistory, getConversationById, and deleteConversation manage chat sessions', () async {
      final history = await repository.getHistory();
      expect(history.isNotEmpty, isTrue);

      final targetId = history.first.id;
      final thread = await repository.getConversationById(targetId);
      expect(thread.id, targetId);
      expect(thread.messages.isNotEmpty, isTrue);

      final deleteSuccess = await repository.deleteConversation(targetId);
      expect(deleteSuccess, isTrue);

      final updatedHistory = await repository.getHistory();
      expect(updatedHistory.any((t) => t.id == targetId), isFalse);
    });
  });
}
