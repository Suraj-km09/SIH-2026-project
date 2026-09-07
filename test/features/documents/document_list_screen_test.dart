import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/features/documents/document_list_screen.dart';
import 'package:mineintel_ai/features/documents/document_upload_dialog.dart';
import 'package:mineintel_ai/repositories/document_repository.dart';
import 'package:mineintel_ai/state/document_state.dart';

void main() {
  Widget buildTestWidget({DocumentRepository? repository}) {
    return ProviderScope(
      overrides: [
        documentRepositoryProvider.overrideWithValue(
          repository ?? MockDocumentRepository(delay: Duration.zero),
        ),
      ],
      child: const MaterialApp(
        home: DocumentListScreen(),
      ),
    );
  }

  group('DocumentListScreen Responsive & Interactive Widget Tests', () {
    testWidgets('Desktop view renders full data table with columns and seeded docs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Header & Upload Action
      expect(find.text('Document Lifecycle & Ingestion'), findsOneWidget);
      expect(find.text('Upload Document'), findsAtLeastNWidgets(1));

      // Desktop DataTable
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Document'), findsOneWidget);
      expect(find.text('Category'), findsAtLeastNWidgets(1));
      expect(find.text('Classification'), findsAtLeastNWidgets(1));
      expect(find.text('Size / Pages'), findsOneWidget);
      expect(find.text('Status'), findsAtLeastNWidgets(1));

      // Seeded documents should be visible
      expect(find.textContaining('ECL_Rajmahal'), findsOneWidget);
      expect(find.textContaining('BCCL_Dhanbad'), findsOneWidget);
    });

    testWidgets('Mobile view renders cards instead of data table',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // No DataTable on mobile
      expect(find.byType(DataTable), findsNothing);

      // Cards are rendered for documents
      expect(find.byType(Card), findsAtLeastNWidgets(1));
      expect(find.textContaining('ECL_Rajmahal'), findsOneWidget);
    });

    testWidgets('Search input filters documents in real-time',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Korba');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('SECL_Korba'), findsOneWidget);
      expect(find.textContaining('ECL_Rajmahal'), findsNothing);
    });

    testWidgets('Clicking Upload Document opens DocumentUploadDialog',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final uploadBtn = find.widgetWithText(ElevatedButton, 'Upload Document');
      expect(uploadBtn, findsOneWidget);

      await tester.tap(uploadBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(DocumentUploadDialog), findsOneWidget);
      expect(find.text('Upload Mining Document'), findsOneWidget);
      expect(find.text('Max size: 50 MB | Ingestion & OCR pipeline'), findsOneWidget);
    });
  });
}
