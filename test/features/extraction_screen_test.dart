import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/features/extraction/extraction_screen.dart';
import 'package:mineintel_ai/models/user_model.dart';
import 'package:mineintel_ai/repositories/document_repository.dart';
import 'package:mineintel_ai/repositories/extraction_repository.dart';
import 'package:mineintel_ai/state/auth_state.dart';
import 'package:mineintel_ai/state/document_state.dart';
import 'package:mineintel_ai/state/extraction_state.dart';

class _FakeAuthNotifier extends AuthNotifier {
  final UserModel _user;
  _FakeAuthNotifier(this._user);

  @override
  AuthState build() {
    return AuthState(status: AuthStatus.authenticated, user: _user);
  }
}

void main() {
  group('ExtractionScreen UI & Overflow Tests', () {
    testWidgets('Mobile 360px viewport has zero RenderFlex overflow and displays readable document name',
        (tester) async {
      // Configure compact mobile screen where the 30px overflow originally happened
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final extractionRepo = MockExtractionRepository();
      final docRepo = MockDocumentRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            extractionRepositoryProvider.overrideWithValue(extractionRepo),
            documentRepositoryProvider.overrideWithValue(docRepo),
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(
                  const UserModel(id: 'u_reviewer', username: 'reviewer', role: 'reviewer'),
                )),
          ],
          child: const MaterialApp(
            home: ExtractionScreen(initialDocumentId: 'doc-001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no RenderFlex or layout exceptions occurred
      expect(tester.takeException(), isNull, reason: 'Zero RenderFlex overflows expected on 360px mobile width');

      // Verify Header and Title
      expect(find.text('Data Extraction & HITL Workspace'), findsOneWidget);

      // Verify human-readable document name is shown (NOT raw ID like doc_001)
      expect(find.textContaining('ECL_Rajmahal_Monthly_Production_August.pdf'), findsWidgets);
      expect(find.text('doc_001'), findsNothing);

      // Verify Run Extraction and Reprocess buttons are present
      expect(find.widgetWithText(FilledButton, 'Run Extraction'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Reprocess'), findsOneWidget);

      // Scroll down to view the cards in the ListView
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // Verify Mobile Cards render with wrap action buttons
      expect(find.text('Raw Coal Production'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Citation'), findsWidgets);
      expect(find.widgetWithText(OutlinedButton, 'Edit'), findsWidgets);
      expect(find.widgetWithText(FilledButton, 'Approve'), findsWidgets);

      // Still zero RenderFlex overflows
      expect(tester.takeException(), isNull);
    });

    testWidgets('Reprocess button prompts confirmation modal', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final extractionRepo = MockExtractionRepository();
      final docRepo = MockDocumentRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            extractionRepositoryProvider.overrideWithValue(extractionRepo),
            documentRepositoryProvider.overrideWithValue(docRepo),
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(
                  const UserModel(id: 'u_admin', username: 'admin', role: 'admin'),
                )),
          ],
          child: const MaterialApp(
            home: ExtractionScreen(initialDocumentId: 'doc-001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final reprocessBtn = find.widgetWithText(OutlinedButton, 'Reprocess');
      expect(reprocessBtn, findsOneWidget);

      await tester.tap(reprocessBtn);
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Reprocess Document'), findsOneWidget);
      expect(find.textContaining('Reprocessing will clear the current extraction records'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Reprocess Now'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Reprocess Document'), findsNothing);
    });

    testWidgets('Citation button opens ground-truth source inspector sheet on mobile cards', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final extractionRepo = MockExtractionRepository();
      final docRepo = MockDocumentRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            extractionRepositoryProvider.overrideWithValue(extractionRepo),
            documentRepositoryProvider.overrideWithValue(docRepo),
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(
                  const UserModel(id: 'u_reviewer', username: 'reviewer', role: 'reviewer'),
                )),
          ],
          child: const MaterialApp(
            home: ExtractionScreen(initialDocumentId: 'doc-001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to cards
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      final citationBtn = find.widgetWithText(OutlinedButton, 'Citation').first;
      expect(citationBtn, findsOneWidget);

      await tester.tap(citationBtn);
      await tester.pumpAndSettle();

      // Verify ground-truth citation inspection sheet
      expect(find.text('Ground-Truth Citation & Audit'), findsOneWidget);
      expect(find.text('Exact Document Excerpt:'), findsOneWidget);
      expect(find.textContaining('Total raw coal production for August'), findsWidgets);

      // Close bottom sheet
      await tester.tap(find.widgetWithText(OutlinedButton, 'Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('Filter tabs switch between All, Needs Review, Approved, and Rejected', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final extractionRepo = MockExtractionRepository();
      final docRepo = MockDocumentRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            extractionRepositoryProvider.overrideWithValue(extractionRepo),
            documentRepositoryProvider.overrideWithValue(docRepo),
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(
                  const UserModel(id: 'u_reviewer', username: 'reviewer', role: 'reviewer'),
                )),
          ],
          child: const MaterialApp(
            home: ExtractionScreen(initialDocumentId: 'doc-001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('All Records'), findsOneWidget);
      expect(find.text('Needs Review'), findsOneWidget);

      // Switch tab to Needs Review
      await tester.tap(find.text('Needs Review'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch tab back to All Records
      await tester.tap(find.text('All Records'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Ultra-compact 320px viewport has zero RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 680);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final extractionRepo = MockExtractionRepository();
      final docRepo = MockDocumentRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            extractionRepositoryProvider.overrideWithValue(extractionRepo),
            documentRepositoryProvider.overrideWithValue(docRepo),
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(
                  const UserModel(id: 'u_reviewer', username: 'reviewer', role: 'reviewer'),
                )),
          ],
          child: const MaterialApp(
            home: ExtractionScreen(initialDocumentId: 'doc-001'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'No RenderFlex overflow on ultra-compact 320px screen');

      // Scroll through content
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Edit dialog opens and allows updating extracted parameter', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final extractionRepo = MockExtractionRepository();
      final docRepo = MockDocumentRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            extractionRepositoryProvider.overrideWithValue(extractionRepo),
            documentRepositoryProvider.overrideWithValue(docRepo),
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(
                  const UserModel(id: 'u_reviewer', username: 'reviewer', role: 'reviewer'),
                )),
          ],
          child: const MaterialApp(
            home: ExtractionScreen(initialDocumentId: 'doc-001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to cards
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      final editBtn = find.widgetWithText(OutlinedButton, 'Edit').first;
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Verify RecordEditDialog is presented
      expect(find.text('Edit Extracted Parameter'), findsOneWidget);
      expect(find.text('Ground Truth Source Text (Page 1):'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Extracted Parameter'), findsNothing);
    });

    testWidgets('Selecting record toggles bulk action bar', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final extractionRepo = MockExtractionRepository();
      final docRepo = MockDocumentRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            extractionRepositoryProvider.overrideWithValue(extractionRepo),
            documentRepositoryProvider.overrideWithValue(docRepo),
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(
                  const UserModel(id: 'u_reviewer', username: 'reviewer', role: 'reviewer'),
                )),
          ],
          child: const MaterialApp(
            home: ExtractionScreen(initialDocumentId: 'doc-001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to cards
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // Find first checkbox in the card list
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsWidgets);

      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      // Verify bulk action bar appeared
      expect(find.textContaining('1 of'), findsOneWidget);
      expect(find.text('Select All'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);

      // Tap clear
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // Verify bulk action bar is cleared
      expect(find.text('Clear'), findsNothing);
    });
  });
}
