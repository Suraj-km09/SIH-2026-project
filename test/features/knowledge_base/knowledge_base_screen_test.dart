import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/features/knowledge_base/knowledge_base_screen.dart';
import 'package:mineintel_ai/repositories/knowledge_base_repository.dart';

void main() {
  group('Phase 9 KnowledgeBaseScreen Widget Tests', () {
    setUp(() {
      EnvConfig.useMockData = true;
    });

    tearDown(() {
      EnvConfig.useMockData = false;
    });

    testWidgets('Renders KPI stats cards, TabBar, and document indexing directory', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockKnowledgeBaseRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            knowledgeBaseRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: KnowledgeBaseScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Knowledge Base & Vector Engine'), findsOneWidget);
      expect(find.text('Total Documents'), findsOneWidget);
      expect(find.text('Indexed for RAG'), findsOneWidget);
      expect(find.text('Total Vector Chunks'), findsOneWidget);
      expect(find.text('Vector Indexing Directory'), findsOneWidget);
      expect(find.text('Semantic RAG Search Sandbox'), findsOneWidget);

      // Check seeded documents in table
      expect(find.text('ECL_Production_August2026.pdf'), findsOneWidget);
    });

    testWidgets('Switches to Semantic RAG Search Sandbox tab and runs query', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockKnowledgeBaseRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            knowledgeBaseRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: KnowledgeBaseScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to RAG tab
      await tester.tap(find.text('Semantic RAG Search Sandbox'));
      await tester.pumpAndSettle();

      expect(find.text('Search Vectors'), findsOneWidget);
      expect(find.textContaining('Top Results (K):'), findsOneWidget);

      // Enter search query
      await tester.enterText(
        find.byType(TextField).last,
        'overburden excavation',
      );
      await tester.pump();

      await tester.tap(find.text('Search Vectors'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Similarity'), findsWidgets);
      expect(find.text('ECL_Production_August2026.pdf'), findsWidgets);
    });
  });
}
