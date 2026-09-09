import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/features/command_centre/command_centre_screen.dart';
import 'package:mineintel_ai/repositories/command_centre_repository.dart';

void main() {
  group('CommandCentreScreen Widget Tests', () {
    testWidgets('Renders Command Centre header, KPIs, pipeline, and services on desktop',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockCommandCentreRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            commandCentreRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: CommandCentreScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header
      expect(find.text('Operations Command Centre'), findsOneWidget);
      expect(find.text('OPERATIONAL'), findsOneWidget);

      // KPIs
      expect(find.text('Docs Processed'), findsOneWidget);
      expect(find.text('Validation Score'), findsOneWidget);
      expect(find.text('Open Issues'), findsOneWidget);
      expect(find.text('Reports Generated'), findsOneWidget);

      // Pipeline
      expect(
          find.text('Document Ingestion & Telemetry Pipeline'), findsOneWidget);
      expect(find.text('1. Upload'), findsOneWidget);
      expect(find.text('2. Extraction'), findsOneWidget);
      expect(find.text('3. Validation'), findsOneWidget);
      expect(find.text('4. Vector Index'), findsOneWidget);
      expect(find.text('5. Completed'), findsOneWidget);

      // Microservices
      expect(find.text('Microservices & Intelligence Status Matrix'),
          findsOneWidget);
      expect(find.text('MongoDB Atlas'), findsOneWidget);
      expect(find.text('Vector Search & Knowledge Base'), findsOneWidget);
      expect(find.text('Gemini AI Engine'), findsOneWidget);
      expect(find.text('Multi-Agent Command Framework'), findsOneWidget);

      // Attention Queue
      expect(find.text('Action & Attention Queue'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'HIGH'), findsOneWidget);

      // Activity Feed
      expect(find.text('Real-Time Ingestion & Audit Activity Stream'),
          findsOneWidget);
    });

    testWidgets('Renders Command Centre on mobile viewport without pixel overflows',
        (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockCommandCentreRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            commandCentreRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: CommandCentreScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Operations Command Centre'), findsOneWidget);
      expect(find.text('OPERATIONAL'), findsOneWidget);
      expect(find.text('Docs Processed'), findsOneWidget);

      // Tap filter chip
      final highChip = find.widgetWithText(ChoiceChip, 'HIGH');
      await tester.ensureVisible(highChip);
      await tester.tap(highChip);
      await tester.pumpAndSettle();

      // Only high priority items remain
      expect(find.text('Critical Validation Issue: Negative Output'),
          findsOneWidget);
    });
  });
}
