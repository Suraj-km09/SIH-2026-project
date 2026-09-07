import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/features/intelligence/intelligence_screen.dart';
import 'package:mineintel_ai/repositories/intelligence_repository.dart';

void main() {
  group('Phase 10 IntelligenceScreen Widget Tests', () {
    setUp(() {
      EnvConfig.useMockData = true;
    });

    tearDown(() {
      EnvConfig.useMockData = false;
    });

    testWidgets('Renders tabs, KPI cards, and trigger action', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockIntelligenceRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            intelligenceRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: IntelligenceScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('Document Intelligence & Cross-Reasoning'), findsOneWidget);
      expect(find.text('Run Analysis'), findsOneWidget);

      // Tabs
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Trends'), findsOneWidget);
      expect(find.text('Entities'), findsOneWidget);
      expect(find.text('Clusters'), findsOneWidget);
      expect(find.text('Similarity'), findsOneWidget);
      expect(find.text('Changes'), findsOneWidget);

      // KPI cards in Overview tab
      expect(find.text('Discovered Entities'), findsOneWidget);
      expect(find.text('Taxonomy Topics'), findsOneWidget);
      expect(find.text('Similarity Clusters'), findsOneWidget);
    });

    testWidgets('Switches to Entities tab and renders entities', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockIntelligenceRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            intelligenceRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: IntelligenceScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Entities tab
      final entitiesTab = find.text('Entities');
      await tester.tap(entitiesTab);
      await tester.pumpAndSettle();

      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('MINE'), findsOneWidget);
      expect(find.text('Rajmahal OCP'), findsOneWidget);
      expect(find.text('Eastern Coalfields Limited'), findsOneWidget);
    });
  });
}
