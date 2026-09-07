import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';
import 'package:mineintel_ai/features/topics/topics_screen.dart';
import 'package:mineintel_ai/repositories/topic_repository.dart';

void main() {
  group('Phase 10 TopicsScreen Widget Tests', () {
    setUp(() {
      EnvConfig.useMockData = true;
    });

    tearDown(() {
      EnvConfig.useMockData = false;
    });

    testWidgets('Renders header, tabs, search bar, and topics list', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockTopicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            topicRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: TopicsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('Topic Modeling & Taxonomy Discovery'), findsOneWidget);
      expect(find.text('Discover Topics'), findsOneWidget);

      // Tabs
      expect(find.text('Taxonomy Catalog'), findsOneWidget);
      expect(find.text('Emerging Topics'), findsOneWidget);
      expect(find.text('Period Shifts'), findsOneWidget);
      expect(find.text('Clusters & Entities'), findsOneWidget);

      // Search Bar
      expect(find.byType(TextField), findsOneWidget);

      // Topic items
      expect(find.text('Coal Production & Extraction'), findsOneWidget);
      expect(find.text('Overburden Evacuation & Stripping'), findsOneWidget);
    });

    testWidgets('Switches to Emerging Topics tab and renders accelerating themes', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockTopicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            topicRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: TopicsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Emerging Topics tab
      final emergingTab = find.text('Emerging Topics');
      await tester.tap(emergingTab);
      await tester.pumpAndSettle();

      expect(find.text('Overburden Evacuation'), findsOneWidget);
      expect(find.text('+45.2% Growth'), findsOneWidget);
      expect(find.text('ACCELERATING'), findsWidgets);
    });

    testWidgets('Switches to Period Shifts tab and displays changes', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockTopicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            topicRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: TopicsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Period Shifts tab
      final shiftsTab = find.text('Period Shifts');
      await tester.tap(shiftsTab);
      await tester.pumpAndSettle();

      expect(find.text('Safety Compliance'), findsOneWidget);
      expect(find.text('+8 mentions'), findsOneWidget);
      expect(find.text('EXPANDING'), findsWidgets);
    });
  });
}
