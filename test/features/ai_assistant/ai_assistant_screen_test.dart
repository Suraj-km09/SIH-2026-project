import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/features/ai_assistant/ai_assistant_screen.dart';
import 'package:mineintel_ai/repositories/ai_assistant_repository.dart';

void main() {
  group('Phase 9 AiAssistantScreen Widget Tests', () {
    setUp(() {
      EnvConfig.useMockData = true;
    });

    tearDown(() {
      EnvConfig.useMockData = false;
    });

    testWidgets('Renders empty state with suggested inquiries and input field', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockAiAssistantRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiAssistantRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: AiAssistantScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('MineIntel AI Assistant'), findsOneWidget);
      expect(find.text('Suggested Inquiries'), findsOneWidget);
      expect(find.byKey(const Key('ai_assistant_send_button')), findsOneWidget);
      expect(find.text('Conversations'), findsNothing); // Desktop sidebar is open
      expect(find.text('New Session'), findsOneWidget);
    });

    testWidgets('Sends question and renders assistant answer with citations and confidence', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockAiAssistantRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiAssistantRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: AiAssistantScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter query
      await tester.enterText(
        find.byType(TextField).last,
        'What was the raw coal production for Rajmahal OCP?',
      );
      await tester.pump();

      // Tap send
      await tester.tap(find.byKey(const Key('ai_assistant_send_button')));
      await tester.pumpAndSettle();

      expect(find.text('What was the raw coal production for Rajmahal OCP?'), findsOneWidget);
      expect(find.text('MineIntel AI Response'), findsOneWidget);
      expect(find.textContaining('Confidence'), findsOneWidget);
      expect(find.textContaining('Citations'), findsOneWidget);
    });

    testWidgets('Displays Insufficient Evidence banner for unindexed domain questions', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockAiAssistantRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiAssistantRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: AiAssistantScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter out-of-domain query
      await tester.enterText(
        find.byType(TextField).last,
        'What is the copper grade?',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('ai_assistant_send_button')));
      await tester.pumpAndSettle();

      expect(find.text('Insufficient Evidence in Knowledge Base'), findsOneWidget);
    });
  });
}
