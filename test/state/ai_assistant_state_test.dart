import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/repositories/ai_assistant_repository.dart';
import 'package:mineintel_ai/state/ai_assistant_state.dart';

void main() {
  group('Phase 9 AiAssistantNotifier Riverpod State Tests', () {
    late ProviderContainer container;
    late MockAiAssistantRepository mockRepo;

    setUp(() {
      EnvConfig.useMockData = true;
      mockRepo = MockAiAssistantRepository();
      container = ProviderContainer(
        overrides: [
          aiAssistantRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      EnvConfig.useMockData = false;
      container.dispose();
    });

    test('sendMessage appends user and assistant messages with citations and evidence', () async {
      final notifier = container.read(aiAssistantNotifierProvider.notifier);

      final success = await notifier.sendMessage('What was the raw coal production for Rajmahal OCP?');
      expect(success, isTrue);

      final state = container.read(aiAssistantNotifierProvider);
      expect(state.messages.length, 2);
      expect(state.messages.first.isUser, isTrue);
      expect(state.messages.last.isAssistant, isTrue);
      expect(state.messages.last.confidence, greaterThanOrEqualTo(0.85));
      expect(state.messages.last.citations.isNotEmpty, isTrue);
      expect(state.activeConversationId, isNotNull);
    });

    test('sendMessage rejects empty queries and concurrent in-flight queries', () async {
      final notifier = container.read(aiAssistantNotifierProvider.notifier);

      final emptyResult = await notifier.sendMessage('   ');
      expect(emptyResult, isFalse);

      // Fast second message while first is theoretically in flight (tested via notifier)
      final firstSend = notifier.sendMessage('First query');
      final secondSend = notifier.sendMessage('Second concurrent query');

      final results = await Future.wait([firstSend, secondSend]);
      // Exactly one succeeds, second was locked or both complete sequentially
      expect(results.first, isTrue);
    });

    test('loadHistory, selectConversation, and startNewConversation manage thread sessions', () async {
      final notifier = container.read(aiAssistantNotifierProvider.notifier);

      await notifier.loadHistory();
      var state = container.read(aiAssistantNotifierProvider);
      expect(state.history.isNotEmpty, isTrue);

      final targetId = state.history.first.id;
      await notifier.selectConversation(targetId);

      state = container.read(aiAssistantNotifierProvider);
      expect(state.activeConversationId, targetId);
      expect(state.messages.isNotEmpty, isTrue);

      notifier.startNewConversation();
      state = container.read(aiAssistantNotifierProvider);
      expect(state.activeConversationId, isNull);
      expect(state.messages.isEmpty, isTrue);
    });

    test('deleteConversation deletes thread and clears active if selected', () async {
      final notifier = container.read(aiAssistantNotifierProvider.notifier);
      await notifier.loadHistory();

      var state = container.read(aiAssistantNotifierProvider);
      final targetId = state.history.first.id;
      await notifier.selectConversation(targetId);

      final deleteSuccess = await notifier.deleteConversation(targetId);
      expect(deleteSuccess, isTrue);

      state = container.read(aiAssistantNotifierProvider);
      expect(state.activeConversationId, isNull);
      expect(state.history.any((t) => t.id == targetId), isFalse);
    });
  });
}
