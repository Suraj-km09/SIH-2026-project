import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/features/reports/report_detail_screen.dart';
import 'package:mineintel_ai/features/reports/reports_list_screen.dart';
import 'package:mineintel_ai/features/reports/widgets/report_generate_dialog.dart';
import 'package:mineintel_ai/models/report_model.dart';
import 'package:mineintel_ai/models/user_model.dart';
import 'package:mineintel_ai/repositories/document_repository.dart';
import 'package:mineintel_ai/repositories/report_repository.dart';
import 'package:mineintel_ai/state/auth_state.dart';
import 'package:mineintel_ai/state/document_state.dart';
import 'package:mineintel_ai/state/report_state.dart';

void main() {
  group('Phase 8 ReportsListScreen Widget Tests', () {
    testWidgets('Renders report list, KPI stats cards, and filter toolbar', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockReportRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(
                  const UserModel(id: 'u_1', username: 'admin', role: 'admin'),
                )),
          ],
          child: const MaterialApp(
            home: ReportsListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Statutory Reports & Regulatory Filings'), findsOneWidget);
      expect(find.text('Total Reports'), findsOneWidget);
      expect(find.text('Draft Reports'), findsOneWidget);
      expect(find.text('Generate Report'), findsOneWidget);

      // Verify report titles
      expect(find.textContaining('Gevra OCP'), findsWidgets);
    });

    testWidgets('ReportDetailScreen renders content narrative and tabs', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockReportRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(
                  const UserModel(id: 'u_1', username: 'admin', role: 'admin'),
                )),
          ],
          child: const MaterialApp(
            home: ReportDetailScreen(reportId: 'rep_001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Report Content'), findsOneWidget);
      expect(find.text('Evidence & Citations'), findsOneWidget);
      expect(find.text('Version History'), findsOneWidget);
      expect(find.text('Changes Diff'), findsOneWidget);

      // Verify content
      expect(find.textContaining('Gevra Open Cast Project'), findsWidgets);

      // Switch to Evidence tab
      await tester.tap(find.text('Evidence & Citations'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Gevra_Monthly_Production_May2024.pdf'), findsWidgets);
    });

    testWidgets('ReportDetailScreen renders structured tables and headers for rep_002', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockReportRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(
                  const UserModel(id: 'u_1', username: 'admin', role: 'admin'),
                )),
          ],
          child: const MaterialApp(
            home: ReportDetailScreen(reportId: 'rep_002'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Table headers and cells
      expect(find.text('Plan Target'), findsOneWidget);
      expect(find.text('Actual Achieved'), findsOneWidget);
      expect(find.text('Variance (%)'), findsOneWidget);
      expect(find.text('ROM Coal Extraction (MT)'), findsOneWidget);
      expect(find.text('420,000'), findsOneWidget);
      expect(find.text('415,200'), findsOneWidget);

      // Verify section titles
      expect(find.text('1. Operational Overview'), findsOneWidget);
      expect(find.text('2. Variance Justification'), findsOneWidget);
    });

    testWidgets('ReportGenerateDialog renders cleanly on mobile screen without overflow and shows originalName', (tester) async {
      // Set to mobile viewport size (360x640) matching the user's mobile device screenshot
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockReportRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(mockRepo),
            documentRepositoryProvider.overrideWithValue(MockDocumentRepository()),
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(
                  const UserModel(id: 'u_1', username: 'admin', role: 'admin'),
                )),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    ReportGenerateDialog.show(
                      context,
                      onGenerate: (req) async => null,
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Dialog title
      expect(find.text('Report Generator'), findsOneWidget);

      // Web reference fields
      expect(find.text('Report Template *'), findsOneWidget);
      expect(find.text('Report Title *'), findsOneWidget);
      expect(find.text('Reporting Period'), findsOneWidget);
      expect(find.text('Mine / Subsidiary'), findsOneWidget);
      expect(find.text('Custom Instructions (Optional)'), findsOneWidget);

      // Language Chips (Previously overflowed on mobile!)
      expect(find.text('English (en)'), findsOneWidget);
      expect(find.text('Hindi (hi)'), findsOneWidget);

      // Document list title: verifies originalName is displayed, NOT the raw hash
      expect(find.text('ECL_Rajmahal_Monthly_Production_August.pdf'), findsOneWidget);
      expect(find.textContaining('1725619200000'), findsNothing);

      // Action buttons
      expect(find.text('Generate Statutory Report'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('ReportGenerateDialog displays multi-stage synthesis tracker and rate limit error banner', (tester) async {
      final mockRepo = MockReportRepository();
      final completer = Completer<ReportModel?>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(mockRepo),
            documentRepositoryProvider.overrideWithValue(MockDocumentRepository()),
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(
                  const UserModel(id: 'u_1', username: 'admin', role: 'admin'),
                )),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    ReportGenerateDialog.show(
                      context,
                      onGenerate: (req) => completer.future,
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Trigger generation
      await tester.tap(find.text('Generate Statutory Report'));
      await tester.pump();

      // Verify multi-stage progress tracker is visible during generation
      expect(find.text('Synthesizing Statutory Report...'), findsOneWidget);
      expect(find.text('Document Context Loaded & Grounded'), findsOneWidget);
      expect(find.text('RAG Retrieval & Mining Telemetry Query'), findsOneWidget);
      expect(find.text('LLM Synthesis & Statutory Variance Analysis'), findsOneWidget);
      expect(find.text('Formatting Structured Tables & Citations'), findsOneWidget);

      // Advance stage timer by 1.6s
      await tester.pump(const Duration(milliseconds: 1600));

      // Simulate Gemini Rate Limit failure from backend matching Image 2
      completer.completeError(
        Exception('Gemini Rate Limit Exceeded. Please retry in 45.83s.'),
      );
      await tester.pumpAndSettle();

      // Verify the executive error banner matching Image 2
      expect(find.text('Report Generation Failed'), findsOneWidget);
      expect(find.textContaining('Gemini Rate Limit Exceeded. Please retry in 45.83s.'), findsOneWidget);
      expect(find.textContaining('Narrow the source document or reporting period, or retry after a moment.'), findsOneWidget);
    });

    test('MockReportRepository and ReportExportGenerator export PDF, CSV, JSON, and Word DOCX', () async {
      final mockRepo = MockReportRepository();
      final reports = await mockRepo.getReports(const ReportFilter());
      expect(reports.reports.isNotEmpty, isTrue);

      final firstReport = reports.reports.first;
      final reportId = firstReport.id;

      // 1. Export PDF
      final pdfData = await mockRepo.exportReport(reportId, 'pdf');
      expect(pdfData, isA<Uint8List>());
      final pdfBytes = pdfData as Uint8List;
      expect(pdfBytes.length, greaterThan(100));
      final pdfHeader = String.fromCharCodes(pdfBytes.sublist(0, 8));
      expect(pdfHeader.startsWith('%PDF-1.4'), isTrue);

      // 2. Export CSV
      final csvData = await mockRepo.exportReport(reportId, 'csv');
      expect(csvData, isA<String>());
      final csvString = csvData as String;
      expect(csvString.contains('\uFEFF'), isTrue);
      expect(csvString.contains('Metadata,Report ID'), isTrue);
      expect(csvString.contains('SECTION,LINE_NUMBER,TEXT_CONTENT'), isTrue);

      // 3. Export JSON
      final jsonData = await mockRepo.exportReport(reportId, 'json');
      expect(jsonData, isA<String>());
      final jsonMap = jsonDecode(jsonData as String) as Map<String, dynamic>;
      expect(jsonMap.containsKey('report'), isTrue);
      expect(jsonMap.containsKey('exportMetadata'), isTrue);

      // 4. Export DOCX
      final docxData = await mockRepo.exportReport(reportId, 'docx');
      expect(docxData, isA<Uint8List>());
      final docxStr = utf8.decode(docxData as Uint8List);
      expect(docxStr.contains('xmlns:w="urn:schemas-microsoft-com:office:word"'), isTrue);
    });
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  final UserModel _user;
  _FakeAuthNotifier(this._user);

  @override
  AuthState build() {
    return AuthState(status: AuthStatus.authenticated, user: _user);
  }
}
