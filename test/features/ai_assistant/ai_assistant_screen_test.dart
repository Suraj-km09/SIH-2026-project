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

    testWidgets('Mobile screen (360x700): renders without overflow and filters raw ** asterisks from markdown', (tester) async {
      tester.view.physicalSize = const Size(360, 700);
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

      // Ensure the mobile hamburger button is visible
      expect(find.byKey(const Key('ai_assistant_history_button')), findsOneWidget);

      // Ask question that triggers bold markdown and calculation card
      await tester.enterText(
        find.byType(TextField).last,
        'What was the raw coal production for Rajmahal OCP in August 2026?',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('ai_assistant_send_button')));
      await tester.pumpAndSettle();

      // Verify no overflow errors occurred
      expect(tester.takeException(), isNull);

      // Verify header and calculation card rendered
      expect(find.text('MineIntel AI Response'), findsOneWidget);
      expect(find.text('Mathematical Verification & Operational Variance'), findsOneWidget);
      expect(find.textContaining('Confidence'), findsOneWidget);

      // Verify raw ** asterisks are stripped and not displayed literally
      expect(find.textContaining('**Rajmahal'), findsNothing);
      expect(find.textContaining('**1,420.5'), findsNothing);
      expect(find.textContaining('**+2.4%**'), findsNothing);
    });

    testWidgets('Mobile hamburger button opens Conversation History sheet and allows switching threads', (tester) async {
      tester.view.physicalSize = const Size(360, 700);
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

      // Tap the chatbot hamburger button
      await tester.tap(find.byKey(const Key('ai_assistant_history_button')));
      await tester.pumpAndSettle();

      // Verify the conversation history bottom sheet is displayed
      expect(find.text('Conversation History'), findsOneWidget);
      expect(find.text('Start New Session'), findsOneWidget);
      expect(find.text('ECL Raw Coal Production Audit'), findsOneWidget);
      expect(find.text('Ventilation & Environmental Compliance'), findsOneWidget);

      // Tap on the ventilation thread
      await tester.tap(find.text('Ventilation & Environmental Compliance'));
      await tester.pumpAndSettle();

      // Bottom sheet should dismiss and load that thread's messages
      expect(find.text('Conversation History'), findsNothing);
      expect(find.text('Are underground shaft ventilation levels within statutory DGMS limits?'), findsOneWidget);
      expect(find.text('MineIntel AI Response'), findsOneWidget);
    });

    testWidgets('Mobile history sheet allows starting a new session and deleting threads', (tester) async {
      tester.view.physicalSize = const Size(360, 700);
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

      // Open history sheet
      await tester.tap(find.byKey(const Key('ai_assistant_history_button')));
      await tester.pumpAndSettle();

      // Tap 'Start New Session'
      await tester.tap(find.text('Start New Session'));
      await tester.pumpAndSettle();

      expect(find.text('Conversation History'), findsNothing);
      expect(find.text('MineIntel AI Assistant'), findsOneWidget);
      expect(find.text('Suggested Inquiries'), findsOneWidget);

      // Re-open history sheet to test deletion
      await tester.tap(find.byKey(const Key('ai_assistant_history_button')));
      await tester.pumpAndSettle();

      // Tap delete on the first thread
      final deleteIcons = find.byIcon(Icons.delete_outline);
      expect(deleteIcons, findsWidgets);
      await tester.tap(deleteIcons.first);
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Delete Session'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Dialog dismisses and thread is removed
      expect(find.text('Delete Session'), findsNothing);
    });
  });
}
