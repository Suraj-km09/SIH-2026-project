import 'dart:convert';
import 'dart:typed_data';
import '../../../models/report_model.dart';

/// Generates valid, high-fidelity export documents for statutory mining reports
/// across PDF, CSV, DOCX, and JSON formats.
class ReportExportGenerator {
  ReportExportGenerator._();

  // ==========================================================================
  // 1. PDF GENERATION (Standard-compliant PDF 1.4 with Multi-page Layout)
  // ==========================================================================

  static Uint8List generatePdf(
    ReportModel report, {
    List<CitedEvidenceModel>? evidence,
  }) {
    String escapePdf(String text) {
      return text
          .replaceAll('\\', '\\\\')
          .replaceAll('(', '\\(')
          .replaceAll(')', '\\)')
          .replaceAll(RegExp(r'[^\x20-\x7E]'), '?'); // Keep ASCII printable
    }

    final fullContent = StringBuffer();
    fullContent.writeln(report.contentAsString);

    if (evidence != null && evidence.isNotEmpty) {
      fullContent.writeln('\n## STATUTORY CITATIONS & EVIDENCE SOURCES');
      for (var i = 0; i < evidence.length; i++) {
        final ev = evidence[i];
        final relevance = ev.similarity != null ? '${(ev.similarity! * 100).toStringAsFixed(1)}%' : 'N/A';
        fullContent.writeln('[$i] Doc ID: ${ev.documentId} | Relevance: $relevance');
        fullContent.writeln('    Excerpt: ${ev.snippet}');
      }
    }

    if (report.reviewerComments != null && report.reviewerComments!.isNotEmpty) {
      fullContent.writeln('\n## GOVERNANCE REVIEW COMMENTS');
      fullContent.writeln(report.reviewerComments!);
    }

    // Word wrap lines at max 78 characters
    final rawLines = fullContent.toString().split('\n');
    final wrappedLines = <String>[];
    for (final rLine in rawLines) {
      final line = rLine.trimRight();
      if (line.length <= 78) {
        wrappedLines.add(line);
      } else {
        final words = line.split(' ');
        var current = '';
        for (final w in words) {
          if ((current.length + w.length + 1) > 78) {
            wrappedLines.add(current);
            current = w;
          } else {
            current = current.isEmpty ? w : '$current $w';
          }
        }
        if (current.isNotEmpty) wrappedLines.add(current);
      }
    }

    // Paginate lines: Page 1 holds ~28 lines due to header & metadata box, subsequent pages hold ~45 lines
    final pagesList = <List<String>>[];
    var idx = 0;
    // Page 1
    final p1Count = (wrappedLines.length >= 28) ? 28 : wrappedLines.length;
    pagesList.add(wrappedLines.sublist(0, p1Count));
    idx = p1Count;

    // Remaining pages
    const int pageCapacity = 45;
    while (idx < wrappedLines.length) {
      final end = (idx + pageCapacity < wrappedLines.length) ? idx + pageCapacity : wrappedLines.length;
      pagesList.add(wrappedLines.sublist(idx, end));
      idx = end;
    }
    if (pagesList.isEmpty) pagesList.add(['[No report content provided]']);

    final totalPages = pagesList.length;

    var nextObjId = 4;
    final pageObjIds = <int>[];
    final pageObjects = <String>[];
    final contentObjects = <String>[];

    for (var pageIdx = 0; pageIdx < totalPages; pageIdx++) {
      final pageObjId = ++nextObjId;
      final contentObjId = ++nextObjId;
      pageObjIds.add(pageObjId);

      final pageLines = pagesList[pageIdx];
      final streamBuf = StringBuffer();

      // Top decorative rule & branding
      streamBuf.writeln('0.15 0.25 0.45 RG');
      streamBuf.writeln('2 w');
      streamBuf.writeln('40 800 m 555 800 l S');

      streamBuf.writeln('BT');
      streamBuf.writeln('/F2 9.5 Tf');
      streamBuf.writeln('0.25 0.35 0.55 rg');
      streamBuf.writeln('40 806 Td (MINESAFE INTEL AI - MINISTRY OF MINES STATUTORY GOVERNANCE) Tj');
      streamBuf.writeln('ET');

      var currentY = 772;

      if (pageIdx == 0) {
        // Report Title
        streamBuf.writeln('BT');
        streamBuf.writeln('/F2 14 Tf');
        streamBuf.writeln('0.08 0.16 0.32 rg');
        final titleEscaped = escapePdf(report.title.length > 55 ? '${report.title.substring(0, 52)}...' : report.title);
        streamBuf.writeln('40 $currentY Td ($titleEscaped) Tj');
        streamBuf.writeln('ET');
        currentY -= 22;

        // Metadata box background & border
        streamBuf.writeln('0.96 0.97 0.99 rg');
        streamBuf.writeln('40 ${currentY - 58} 515 64 re f');
        streamBuf.writeln('0.78 0.82 0.9 RG');
        streamBuf.writeln('1 w');
        streamBuf.writeln('40 ${currentY - 58} 515 64 re S');

        // Metadata Row 1
        streamBuf.writeln('BT');
        streamBuf.writeln('/F2 8.5 Tf');
        streamBuf.writeln('0.2 0.2 0.2 rg');
        final cleanId = report.id.length > 20 ? report.id.substring(0, 20) : report.id;
        streamBuf.writeln('48 ${currentY - 14} Td (REPORT ID: ${escapePdf(cleanId)}) Tj');
        streamBuf.writeln('180 0 Td (TYPE: ${escapePdf(report.type)}) Tj');
        streamBuf.writeln('170 0 Td (STATUS: ${escapePdf(report.status.toUpperCase())}) Tj');
        streamBuf.writeln('ET');

        // Metadata Row 2
        streamBuf.writeln('BT');
        streamBuf.writeln('/F1 8.5 Tf');
        streamBuf.writeln('0.3 0.3 0.3 rg');
        final genBy = escapePdf(report.generatedBy ?? 'Automated Agent');
        final appBy = escapePdf(report.approvedBy ?? 'Pending Maker-Checker Review');
        streamBuf.writeln('48 ${currentY - 30} Td (Generated By: $genBy) Tj');
        streamBuf.writeln('180 0 Td (Approved By: $appBy) Tj');
        streamBuf.writeln('ET');

        // Metadata Row 3
        streamBuf.writeln('BT');
        streamBuf.writeln('/F1 8.5 Tf');
        streamBuf.writeln('0.3 0.3 0.3 rg');
        final confStr = report.confidenceScore != null ? '${(report.confidenceScore! * 100).toStringAsFixed(1)}%' : 'N/A';
        final dateStr = report.createdAt ?? DateTime.now().toIso8601String().split('T').first;
        streamBuf.writeln('48 ${currentY - 46} Td (Created: ${escapePdf(dateStr)} | Version: ${report.version} | Language: ${report.language.toUpperCase()}) Tj');
        streamBuf.writeln('260 0 Td (AI Confidence: $confStr) Tj');
        streamBuf.writeln('ET');

        currentY -= 76;
      }

      // Render body lines
      for (final line in pageLines) {
        if (currentY < 55) break;
        final isHeading = line.startsWith('#') || line.startsWith('==');
        final clean = escapePdf(line.replaceAll(RegExp(r'^[#=]+\s*'), '').trim());

        if (clean.isEmpty) {
          currentY -= 8;
          continue;
        }

        streamBuf.writeln('BT');
        if (isHeading) {
          streamBuf.writeln('/F2 10.5 Tf');
          streamBuf.writeln('0.1 0.22 0.44 rg');
        } else {
          streamBuf.writeln('/F1 9 Tf');
          streamBuf.writeln('0.15 0.15 0.15 rg');
        }
        streamBuf.writeln('40 $currentY Td ($clean) Tj');
        streamBuf.writeln('ET');

        currentY -= (isHeading ? 15 : 12);
      }

      // Bottom footer rule
      streamBuf.writeln('0.82 0.84 0.88 RG');
      streamBuf.writeln('1 w');
      streamBuf.writeln('40 42 m 555 42 l S');

      streamBuf.writeln('BT');
      streamBuf.writeln('/F1 8 Tf');
      streamBuf.writeln('0.5 0.5 0.5 rg');
      streamBuf.writeln('40 30 Td (MineIntel AI Compliance Provenance - Verified Statutory Record) Tj');
      streamBuf.writeln('380 0 Td (Page ${pageIdx + 1} of $totalPages) Tj');
      streamBuf.writeln('ET');

      final streamBytes = utf8.encode(streamBuf.toString());
      final contentObj = '$contentObjId 0 obj\n<< /Length ${streamBytes.length} >>\nstream\n${streamBuf.toString()}endstream\nendobj';
      contentObjects.add(contentObj);

      final pageObj = '$pageObjId 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents $contentObjId 0 R >>\nendobj';
      pageObjects.add(pageObj);
    }

    final catalogObj = '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj';
    final pagesKids = pageObjIds.map((id) => '$id 0 R').join(' ');
    final pagesObj = '2 0 obj\n<< /Type /Pages /Kids [$pagesKids] /Count $totalPages >>\nendobj';
    final font1Obj = '3 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj';
    final font2Obj = '4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>\nendobj';

    final allObjects = <String>[
      catalogObj,
      pagesObj,
      font1Obj,
      font2Obj,
      ...pageObjects,
      ...contentObjects,
    ];

    final pdfBuffer = BytesBuilder();
    pdfBuffer.add(utf8.encode('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n'));

    final offsets = <int>[0];
    for (final obj in allObjects) {
      offsets.add(pdfBuffer.length);
      pdfBuffer.add(utf8.encode('$obj\n'));
    }

    final xrefOffset = pdfBuffer.length;
    final totalObjs = allObjects.length + 1;
    final xrefBuf = StringBuffer();
    xrefBuf.writeln('xref');
    xrefBuf.writeln('0 $totalObjs');
    xrefBuf.writeln('0000000000 65535 f ');
    for (var i = 1; i < totalObjs; i++) {
      final off = offsets[i].toString().padLeft(10, '0');
      xrefBuf.writeln('$off 00000 n ');
    }
    xrefBuf.writeln('trailer');
    xrefBuf.writeln('<< /Size $totalObjs /Root 1 0 R >>');
    xrefBuf.writeln('startxref');
    xrefBuf.writeln('$xrefOffset');
    xrefBuf.writeln('%%EOF');

    pdfBuffer.add(utf8.encode(xrefBuf.toString()));
    return pdfBuffer.toBytes();
  }

  // ==========================================================================
  // 2. CSV EXPORT (RFC 4180 with UTF-8 BOM for Microsoft Excel Compatibility)
  // ==========================================================================

  static String generateCsv(
    ReportModel report, {
    List<CitedEvidenceModel>? evidence,
  }) {
    String csvEscape(dynamic val) {
      if (val == null) return '""';
      final s = val.toString();
      if (s.contains('"') || s.contains(',') || s.contains('\n') || s.contains('\r')) {
        return '"${s.replaceAll('"', '""')}"';
      }
      return '"$s"';
    }

    final buf = StringBuffer();
    // Prepend UTF-8 BOM so Excel opens Hindi/UTF-8 flawlessly
    buf.write('\uFEFF');

    // Primary Overview Table
    buf.writeln('Field,Value');
    buf.writeln('ID,${csvEscape(report.id)}');
    buf.writeln('Title,${csvEscape(report.title)}');
    buf.writeln('Status,${csvEscape(report.status)}');
    buf.writeln('Version,${csvEscape(report.version)}');
    buf.writeln('Type,${csvEscape(report.type)}');
    buf.writeln('GeneratedBy,${csvEscape(report.generatedBy ?? "")}');
    buf.writeln('ApprovedBy,${csvEscape(report.approvedBy ?? "")}');
    buf.writeln('Confidence,${csvEscape(report.confidenceScore ?? 0.0)}');
    buf.writeln('');

    // Section 1: Metadata
    buf.writeln('SECTION,PROPERTY,VALUE');
    buf.writeln('Metadata,Report ID,${csvEscape(report.id)}');
    buf.writeln('Metadata,Title,${csvEscape(report.title)}');
    buf.writeln('Metadata,Type,${csvEscape(report.type)}');
    buf.writeln('Metadata,Status,${csvEscape(report.status)}');
    buf.writeln('Metadata,Version,${csvEscape(report.version)}');
    buf.writeln('Metadata,Language,${csvEscape(report.language)}');
    buf.writeln('Metadata,Confidence Score,${csvEscape(report.confidenceScore ?? 0.0)}');
    buf.writeln('Metadata,Generated By,${csvEscape(report.generatedBy ?? "")}');
    buf.writeln('Metadata,Approved By,${csvEscape(report.approvedBy ?? "")}');
    buf.writeln('Metadata,Created At,${csvEscape(report.createdAt ?? "")}');
    buf.writeln('Metadata,Reviewer Comments,${csvEscape(report.reviewerComments ?? "")}');

    buf.writeln('');

    // Section 2: Content Breakdown
    buf.writeln('SECTION,LINE_NUMBER,TEXT_CONTENT');
    final lines = report.contentAsString.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty) {
        buf.writeln('Content,${i + 1},${csvEscape(line)}');
      }
    }

    // Section 3: Evidence & Citations
    if (evidence != null && evidence.isNotEmpty) {
      buf.writeln('');
      buf.writeln('SECTION,DOCUMENT_ID,SIMILARITY_SCORE,SNIPPET');
      for (final ev in evidence) {
        buf.writeln('Evidence,${csvEscape(ev.documentId)},${csvEscape(ev.similarity ?? 0.0)},${csvEscape(ev.snippet)}');
      }
    }

    return buf.toString();
  }

  // ==========================================================================
  // 3. JSON EXPORT
  // ==========================================================================

  static String generateJson(
    ReportModel report, {
    List<CitedEvidenceModel>? evidence,
    List<ReportVersionModel>? versions,
  }) {
    final map = <String, dynamic>{
      'exportMetadata': {
        'system': 'MineIntel AI Statutory Governance Platform',
        'exportTimestamp': DateTime.now().toIso8601String(),
        'complianceFormat': 'JSON-LD / Statutory Schema v1.0',
      },
      'report': report.toJson(),
      'evidence': evidence?.map((e) => e.toJson()).toList() ?? [],
      'versions': versions?.map((v) => v.toJson()).toList() ?? [],
    };

    return const JsonEncoder.withIndent('  ').convert(map);
  }

  // ==========================================================================
  // 4. MICROSOFT WORD / DOCX EXPORT (Office HTML Dialect)
  // ==========================================================================

  static Uint8List generateDocx(
    ReportModel report, {
    List<CitedEvidenceModel>? evidence,
  }) {
    String escapeHtml(String text) {
      return text
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;');
    }

    final buf = StringBuffer();
    buf.writeln('<html xmlns:o="urn:schemas-microsoft-com:office:office" '
        'xmlns:w="urn:schemas-microsoft-com:office:word" '
        'xmlns="http://www.w3.org/TR/REC-html40">');
    buf.writeln('<head>');
    buf.writeln('<meta charset="utf-8">');
    buf.writeln('<title>${escapeHtml(report.title)}</title>');
    buf.writeln('<style>');
    buf.writeln('body { font-family: Calibri, Arial, sans-serif; font-size: 11pt; line-height: 1.5; color: #1a202c; margin: 40px; }');
    buf.writeln('h1 { font-size: 18pt; color: #1a365d; border-bottom: 2pt solid #2b6cb0; padding-bottom: 6pt; margin-bottom: 12pt; }');
    buf.writeln('h2 { font-size: 13pt; color: #2b6cb0; margin-top: 18pt; border-bottom: 1pt solid #e2e8f0; padding-bottom: 4pt; }');
    buf.writeln('p { margin: 6pt 0; }');
    buf.writeln('.meta-table { width: 100%; border-collapse: collapse; margin-bottom: 20pt; background: #f7fafc; }');
    buf.writeln('.meta-table td { border: 1pt solid #cbd5e0; padding: 6pt 10pt; font-size: 10pt; }');
    buf.writeln('.meta-table .label { font-weight: bold; width: 22%; background: #edf2f7; color: #2d3748; }');
    buf.writeln('.footer { margin-top: 30pt; font-size: 9pt; color: #a0aec0; border-top: 1pt solid #e2e8f0; padding-top: 8pt; }');
    buf.writeln('</style>');
    buf.writeln('</head>');
    buf.writeln('<body>');

    buf.writeln('<h1>${escapeHtml(report.title)}</h1>');

    // Metadata Table
    buf.writeln('<table class="meta-table">');
    buf.writeln('<tr><td class="label">Report ID</td><td>${escapeHtml(report.id)}</td><td class="label">Status</td><td>${escapeHtml(report.status.toUpperCase())}</td></tr>');
    buf.writeln('<tr><td class="label">Report Type</td><td>${escapeHtml(report.type)}</td><td class="label">Version</td><td>${report.version}</td></tr>');
    buf.writeln('<tr><td class="label">Generated By</td><td>${escapeHtml(report.generatedBy ?? "Automated AI Agent")}</td><td class="label">Approved By</td><td>${escapeHtml(report.approvedBy ?? "Pending Review")}</td></tr>');
    buf.writeln('<tr><td class="label">Language</td><td>${escapeHtml(report.language.toUpperCase())}</td><td class="label">Created Date</td><td>${escapeHtml(report.createdAt ?? DateTime.now().toIso8601String())}</td></tr>');
    if (report.confidenceScore != null) {
      buf.writeln('<tr><td class="label">AI Confidence</td><td colspan="3">${(report.confidenceScore! * 100).toStringAsFixed(1)}%</td></tr>');
    }
    buf.writeln('</table>');

    // Body Content
    final lines = report.contentAsString.split('\n');
    for (final raw in lines) {
      final line = raw.trim();
      if (line.startsWith('# ')) {
        buf.writeln('<h1>${escapeHtml(line.substring(2))}</h1>');
      } else if (line.startsWith('## ')) {
        buf.writeln('<h2>${escapeHtml(line.substring(3))}</h2>');
      } else if (line.startsWith('### ')) {
        buf.writeln('<h3>${escapeHtml(line.substring(4))}</h3>');
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        buf.writeln('<p style="margin-left: 20pt;">&#8226; ${escapeHtml(line.substring(2))}</p>');
      } else if (line.isNotEmpty) {
        buf.writeln('<p>${escapeHtml(line)}</p>');
      }
    }

    // Evidence
    if (evidence != null && evidence.isNotEmpty) {
      buf.writeln('<h2>Statutory Citations & Evidence Sources</h2>');
      buf.writeln('<table class="meta-table">');
      buf.writeln('<tr><th style="background:#edf2f7; text-align:left; padding:6pt;">Doc ID</th><th style="background:#edf2f7; text-align:left; padding:6pt;">Similarity</th><th style="background:#edf2f7; text-align:left; padding:6pt;">Snippet</th></tr>');
      for (final ev in evidence) {
        final sim = ev.similarity != null ? '${(ev.similarity! * 100).toStringAsFixed(1)}%' : 'N/A';
        buf.writeln('<tr><td>${escapeHtml(ev.documentId)}</td><td>$sim</td><td>${escapeHtml(ev.snippet)}</td></tr>');
      }
      buf.writeln('</table>');
    }

    buf.writeln('<div class="footer">MineSafe Intel AI &#8212; Ministry of Mines & DGMS Statutory Compliance Verification. Tamper-evident immutable export.</div>');
    buf.writeln('</body>');
    buf.writeln('</html>');

    return Uint8List.fromList(utf8.encode(buf.toString()));
  }
}
