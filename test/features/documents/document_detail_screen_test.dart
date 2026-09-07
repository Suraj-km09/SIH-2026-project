import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/features/documents/document_detail_screen.dart';
import 'package:mineintel_ai/features/documents/document_metadata_dialog.dart';
import 'package:mineintel_ai/repositories/document_repository.dart';
import 'package:mineintel_ai/state/document_state.dart';

void main() {
  Widget buildTestWidget({String documentId = 'doc-001', DocumentRepository? repository}) {
    return ProviderScope(
      overrides: [
        documentRepositoryProvider.overrideWithValue(
          repository ?? MockDocumentRepository(delay: Duration.zero),
        ),
      ],
      child: MaterialApp(
        home: DocumentDetailScreen(documentId: documentId),
      ),
    );
  }

  group('DocumentDetailScreen & OCR Viewer Widget Tests', () {
    testWidgets('Renders header, telemetry banner, and OCR extracted pages',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Title
      expect(find.textContaining('ECL_Rajmahal'), findsOneWidget);

      // Status banner
      expect(find.text('Status: COMPLETED'), findsOneWidget);
      expect(find.text('Progress: 100%'), findsOneWidget);

      // OCR Extracted Pages Tab
      expect(find.text('OCR Extracted Pages'), findsOneWidget);
      expect(find.text('Metadata & GIS'), findsOneWidget);
      expect(find.text('Page 1 of 2'), findsOneWidget);
      expect(find.textContaining('MINISTRY OF COAL'), findsOneWidget);
      expect(find.textContaining('OPERATIONAL SUMMARY'), findsOneWidget);
    });

    testWidgets('Advances to next OCR page with chevron button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Page 1 of 2'), findsOneWidget);

      final nextBtn = find.byTooltip('Next Page');
      expect(nextBtn, findsOneWidget);

      await tester.tap(nextBtn);
      await tester.pump();

      expect(find.text('Page 2 of 2'), findsOneWidget);
      expect(find.textContaining('STATUTORY SAFETY & AIR MONITORING'), findsOneWidget);
    });

    testWidgets('Switches to Metadata & GIS tab and displays technical and GIS properties',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final metaTab = find.text('Metadata & GIS');
      await tester.tap(metaTab);
      await tester.pumpAndSettle();

      // Technical properties
      expect(find.text('Technical Properties'), findsOneWidget);
      expect(find.text('Original Filename'), findsOneWidget);
      expect(find.text('SHA-256 Hash'), findsOneWidget);

      // GIS Properties
      expect(find.text('GIS & Geographic Coordinates'), findsOneWidget);
      expect(find.text('Mine Code'), findsOneWidget);
      expect(find.text('ECL-04'), findsOneWidget);

      // Named entities
      expect(find.text('Extracted Named Entities'), findsOneWidget);
      expect(find.textContaining('Rajmahal OCP'), findsOneWidget);

      // Edit metadata button
      final editBtn = find.widgetWithText(ElevatedButton, 'Edit Metadata');
      expect(editBtn, findsOneWidget);

      await tester.tap(editBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(DocumentMetadataDialog), findsOneWidget);
      expect(find.text('Edit Document Metadata'), findsOneWidget);
    });

    testWidgets('Delete icon displays confirmation dialog',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final deleteBtn = find.byTooltip('Delete Document');
      expect(deleteBtn, findsOneWidget);

      await tester.tap(deleteBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Delete Document?'), findsOneWidget);
      expect(find.text('Delete Permanently'), findsOneWidget);
    });
  });
}
