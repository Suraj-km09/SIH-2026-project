import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/report_model.dart';
import '../../state/auth_state.dart';
import '../../state/report_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/status_chip.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/error_state.dart';
import '../../widgets/feedback/loading_indicator.dart';
import 'widgets/report_editor_dialog.dart';
import 'widgets/report_reject_dialog.dart';

/// Screen displaying complete details of a Statutory Mining Report,
/// content narrative, evidence citations, version history, changes diff,
/// multi-format export actions, and maker-checker approval/rejection workflows.
class ReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;

  const ReportDetailScreen({
    super.key,
    required this.reportId,
  });

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportDetailNotifierProvider.notifier).loadReport(widget.reportId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportDetailNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isAdmin = user?.isAdmin ?? false;
    final isReviewer = user?.isReviewer ?? false;

    ref.listen<ReportDetailState>(reportDetailNotifierProvider, (previous, next) {
      if (next.actionMessage != null && next.actionMessage != previous?.actionMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.actionMessage!),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final report = state.report;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report?.title ?? 'Statutory Report Details',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (report != null) ...[
              const SizedBox(height: 2),
              Text(
                'ID: ${report.id} • v${report.version} • Lang: ${report.language.toUpperCase()}',
                style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
        actions: [
          if (report != null) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: StatusChip(status: report.status),
              ),
            ),
            // Multi-format export popup menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.file_download_outlined, color: AppColors.textPrimary),
              tooltip: 'Export Report',
              onSelected: (format) {
                ref.read(reportDetailNotifierProvider.notifier).exportReport(report.id, format, reportTitle: report.title);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: AppColors.error, size: 18),
                      SizedBox(width: 8),
                      Text('Export as PDF Document (.pdf)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'docx',
                  child: Row(
                    children: [
                      Icon(Icons.description, color: AppColors.accentBlue, size: 18),
                      SizedBox(width: 8),
                      Text('Export as Microsoft Word (.docx)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'csv',
                  child: Row(
                    children: [
                      Icon(Icons.table_view, color: AppColors.success, size: 18),
                      SizedBox(width: 8),
                      Text('Export as CSV Tabular (.csv)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'json',
                  child: Row(
                    children: [
                      Icon(Icons.data_object, color: AppColors.warning, size: 18),
                      SizedBox(width: 8),
                      Text('Export as JSON Payload (.json)'),
                    ],
                  ),
                ),
              ],
            ),
            _buildWorkflowActions(context, report, isAdmin, isReviewer, state.isActionLoading),
            const SizedBox(width: 8),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.article_outlined, size: 18), text: 'Report Content'),
            Tab(icon: Icon(Icons.fact_check_outlined, size: 18), text: 'Evidence & Citations'),
            Tab(icon: Icon(Icons.history, size: 18), text: 'Version History'),
            Tab(icon: Icon(Icons.compare_arrows, size: 18), text: 'Changes Diff'),
          ],
        ),
      ),
      body: _buildBody(context, state, report),
    );
  }

  Widget _buildWorkflowActions(
    BuildContext context,
    ReportModel report,
    bool isAdmin,
    bool isReviewer,
    bool isActionLoading,
  ) {
    final notifier = ref.read(reportDetailNotifierProvider.notifier);

    if (report.isDraft) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Edit Report',
            onPressed: isActionLoading
                ? null
                : () => ReportEditorDialog.show(
                      context,
                      report: report,
                      onSave: (req) => notifier.updateReport(report.id, req),
                    ),
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: isActionLoading ? null : () => notifier.submitForReview(report.id),
            icon: const Icon(Icons.send, size: 14),
            label: const Text('Submit Review'),
          ),
        ],
      );
    }

    if (report.isReview) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reject button (Reviewer or Admin)
          Tooltip(
            message: isReviewer ? 'Reject Report' : 'Requires Reviewer or Admin role',
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: (!isReviewer || isActionLoading)
                  ? null
                  : () => ReportRejectDialog.show(
                        context,
                        reportTitle: report.title,
                        onReject: (reason) => notifier.rejectReport(report.id, reason),
                      ),
              icon: const Icon(Icons.close, size: 14),
              label: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 8),
          // Approve button (Strictly ADMIN ONLY)
          Tooltip(
            message: isAdmin ? 'Approve Report (Admin only)' : 'Approval restricted to Administrator role',
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: (!isAdmin || isActionLoading) ? null : () => notifier.approveReport(report.id),
              icon: const Icon(Icons.check, size: 14),
              label: const Text('Approve (Admin)'),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBody(BuildContext context, ReportDetailState state, ReportModel? report) {
    if (state.isLoading) {
      return const Center(child: AppLoadingIndicator(message: 'Loading statutory report details...'));
    }

    if (state.isError || report == null) {
      return Center(
        child: ErrorStateWidget(
          message: state.errorMessage ?? 'Report not found.',
          onRetry: () => ref.read(reportDetailNotifierProvider.notifier).loadReport(widget.reportId),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildContentTab(context, report),
        _buildEvidenceTab(context, state.evidence),
        _buildVersionsTab(context, state.versions),
        _buildChangesTab(context, state.changes),
      ],
    );
  }

  Widget _buildContentTab(BuildContext context, ReportModel report) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Governance Telemetry Header
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _buildMetaField('Category / Type', report.type.replaceAll('_', ' ').toUpperCase()),
              _buildMetaField('Generated By', report.generatedBy ?? 'Unknown'),
              _buildMetaField('Created', report.createdAt ?? 'Recent'),
              if (report.approvedBy != null) ...[
                _buildMetaField('Approved By (Admin)', report.approvedBy!, color: AppColors.success),
                _buildMetaField('Approved At', report.approvedAt ?? '—'),
              ],
              if (report.reviewerComments != null) ...[
                _buildMetaField('Reviewer Feedback', report.reviewerComments!, color: AppColors.error),
              ],
            ],
          ),
        ),

        // Source Grounding Context Banner
        if (report.sources.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.source_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Source Context: ',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: report.sources.map((src) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.picture_as_pdf, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              src.originalName,
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Report Body Container (Chunked Markdown Viewer)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: SelectionArea(
            child: _buildMarkdownContent(report.contentAsString),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaField(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMarkdownContent(String rawContent) {
    if (rawContent.trim().isEmpty) {
      return const Text('No report content available.');
    }

    final rawLines = rawContent.split('\n');
    final widgets = <Widget>[];

    int i = 0;
    while (i < rawLines.length) {
      final line = rawLines[i];
      final trimmed = line.trim();

      // 1. Check for Markdown Table: starts and ends with '|'
      if (trimmed.startsWith('|') && trimmed.endsWith('|') && trimmed.length > 2) {
        final tableLines = <String>[];
        while (i < rawLines.length &&
            rawLines[i].trim().startsWith('|') &&
            rawLines[i].trim().endsWith('|') &&
            rawLines[i].trim().length > 2) {
          tableLines.add(rawLines[i].trim());
          i++;
        }
        widgets.add(_buildTableBlock(tableLines));
        continue;
      }

      // 2. Check for Math / LaTeX block: $$...$$ or multiline $$
      if (trimmed.startsWith(r'$$')) {
        if (trimmed.endsWith(r'$$') && trimmed.length > 4) {
          widgets.add(_buildFormulaCard(trimmed));
          i++;
          continue;
        } else {
          final mathLines = <String>[trimmed];
          i++;
          while (i < rawLines.length && !rawLines[i].trim().endsWith(r'$$')) {
            mathLines.add(rawLines[i].trim());
            i++;
          }
          if (i < rawLines.length) {
            mathLines.add(rawLines[i].trim());
            i++;
          }
          widgets.add(_buildFormulaCard(mathLines.join('\n')));
          continue;
        }
      }

      // 3. Horizontal Rule
      if (trimmed == '---' || trimmed == '***' || trimmed == '___') {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(color: AppColors.border, height: 1),
        ));
        i++;
        continue;
      }

      // 4. Empty line
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        i++;
        continue;
      }

      // 5. Heading 1 (# )
      if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 12),
          child: Text(
            line.substring(2).trim(),
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ));
        i++;
        continue;
      }

      // 6. Heading 2 (## )
      if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  line.substring(3).trim(),
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ));
        i++;
        continue;
      }

      // 7. Heading 3 (### )
      if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            line.substring(4).trim(),
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ));
        i++;
        continue;
      }

      // 8. Blockquote (> )
      if (line.startsWith('> ')) {
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
          ),
          child: Text.rich(
            TextSpan(
              children: _parseInlineSpans(
                line.substring(2).trim(),
                AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
              ),
            ),
          ),
        ));
        i++;
        continue;
      }

      // 9. Numbered items: 1. , 2. 
      final numMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(trimmed);
      if (numMatch != null) {
        final numStr = numMatch.group(1)!;
        final textContent = numMatch.group(2)!;
        final isRiskOrAnomaly = textContent.toLowerCase().contains('anomaly') ||
            textContent.toLowerCase().contains('negative') ||
            textContent.toLowerCase().contains('discrepancy') ||
            textContent.toLowerCase().contains('risk');

        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 8, top: 2),
                decoration: BoxDecoration(
                  color: isRiskOrAnomaly
                      ? AppColors.errorBg
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: isRiskOrAnomaly ? Border.all(color: AppColors.errorBorder) : null,
                ),
                child: Text(
                  numStr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isRiskOrAnomaly ? AppColors.error : AppColors.primary,
                  ),
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: _parseInlineSpans(
                      textContent,
                      AppTypography.bodyMedium.copyWith(height: 1.5, color: AppColors.textPrimary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
        i++;
        continue;
      }

      // 10. Bullet items: - or *
      if (line.startsWith('- ') || (line.startsWith('* ') && !line.startsWith('* **'))) {
        final content = line.substring(2);
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(top: 8, right: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: _parseInlineSpans(
                      content,
                      AppTypography.bodyMedium.copyWith(height: 1.5, color: AppColors.textPrimary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
        i++;
        continue;
      }

      // 11. Regular paragraph with inline formatting
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text.rich(
          TextSpan(
            children: _parseInlineSpans(
              line,
              AppTypography.bodyMedium.copyWith(height: 1.5, color: AppColors.textPrimary),
            ),
          ),
        ),
      ));
      i++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Builds a responsive, styled Flutter Table from markdown table lines.
  Widget _buildTableBlock(List<String> tableLines) {
    if (tableLines.isEmpty) return const SizedBox.shrink();

    final headerCells = _parseCells(tableLines.first);
    final rowLines = <List<String>>[];

    for (int i = 1; i < tableLines.length; i++) {
      if (_isTableDelimiter(tableLines[i])) {
        continue;
      }
      final cells = _parseCells(tableLines[i]);
      if (cells.isNotEmpty) {
        rowLines.add(cells);
      }
    }

    if (headerCells.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 520),
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder(
              horizontalInside: BorderSide(color: AppColors.border.withValues(alpha: 0.5), width: 1),
              verticalInside: BorderSide(color: AppColors.border.withValues(alpha: 0.3), width: 1),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                children: headerCells.map((h) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Text(
                      h,
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              ...rowLines.asMap().entries.map((entry) {
                final idx = entry.key;
                final row = entry.value;
                final isEven = idx % 2 == 0;
                return TableRow(
                  decoration: BoxDecoration(
                    color: isEven ? Colors.transparent : AppColors.surfaceMuted.withValues(alpha: 0.35),
                  ),
                  children: row.map((cell) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      child: Text.rich(
                        TextSpan(
                          children: _parseInlineSpans(
                            cell,
                            AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  bool _isTableDelimiter(String line) {
    final inner = line.replaceAll('|', '').replaceAll('-', '').replaceAll(':', '').trim();
    return inner.isEmpty;
  }

  List<String> _parseCells(String line) {
    var trimmed = line.trim();
    if (trimmed.startsWith('|')) trimmed = trimmed.substring(1);
    if (trimmed.endsWith('|')) trimmed = trimmed.substring(0, trimmed.length - 1);
    return trimmed.split('|').map((c) => c.trim()).toList();
  }

  /// Builds a formula callout card for LaTeX/math equations.
  Widget _buildFormulaCard(String rawEquation) {
    String clean = rawEquation
        .replaceAll(r'$$', '')
        .replaceAll(r'\text{', '')
        .replaceAll('}', '')
        .replaceAll(r'\times', '×')
        .replaceAll(r'\%', '%')
        .replaceAll(r'\left(', '(')
        .replaceAll(r'\right)', ')')
        .trim();

    clean = clean.replaceAllMapped(
      RegExp(r'\\frac\{([^}]+)\}\{([^}]+)\}'),
      (m) => '(${m[1]} / ${m[2]})',
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calculate_outlined, color: AppColors.accentTeal, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              clean,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.accentTeal,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Parses inline markdown styling: **bold**, *italic*, and `code`.
  List<InlineSpan> _parseInlineSpans(String text, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`)');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      final matchText = match.group(0)!;
      if (matchText.startsWith('**') && matchText.endsWith('**')) {
        spans.add(TextSpan(
          text: matchText.substring(2, matchText.length - 2),
          style: baseStyle.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ));
      } else if (matchText.startsWith('*') && matchText.endsWith('*')) {
        spans.add(TextSpan(
          text: matchText.substring(1, matchText.length - 1),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
        ));
      } else if (matchText.startsWith('`') && matchText.endsWith('`')) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              matchText.substring(1, matchText.length - 1),
              style: baseStyle.copyWith(
                fontFamily: 'monospace',
                fontSize: (baseStyle.fontSize ?? 13) - 1,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }

  Widget _buildEvidenceTab(BuildContext context, List<CitedEvidenceModel> evidence) {
    final report = ref.watch(reportDetailNotifierProvider).report;

    if (evidence.isEmpty) {
      if (report != null && report.sources.isNotEmpty) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Grounded Source Documents (${report.sources.length})',
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...report.sources.map((src) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            src.originalName,
                            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Verified Statutory Source Grounding',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.successBorder),
                      ),
                      child: Text(
                        'Verified',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      }
      return const Padding(
        padding: EdgeInsets.all(32),
        child: EmptyStateWidget(
          title: 'No Evidence Citations',
          description: 'This report does not contain cited source document links.',
          icon: Icons.fact_check_outlined,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: evidence.length,
      itemBuilder: (context, index) {
        final ev = evidence[index];
        final similarityPct = ((ev.similarity ?? 0.95) * 100).round();
        final docDisplayName = (ev.documentName != null && ev.documentName!.isNotEmpty)
            ? ev.documentName!
            : (report?.sources.where((s) => s.id == ev.documentId).firstOrNull?.originalName ?? ev.documentId);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        docDisplayName,
                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (ev.pageNumber != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Page ${ev.pageNumber}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.successBorder),
                    ),
                    child: Text(
                      'Similarity: $similarityPct%',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${ev.snippet}"',
                  style: AppTypography.bodySmall.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVersionsTab(BuildContext context, List<ReportVersionModel> versions) {
    if (versions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: EmptyStateWidget(
          title: 'No Historical Versions',
          description: 'Only the initial version exists for this report.',
          icon: Icons.history,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: versions.length,
      itemBuilder: (context, index) {
        final ver = versions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'v${ver.version}',
                    style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ver.title, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      'Edited by ${ver.updatedBy ?? 'Author'} on ${ver.updatedAt ?? 'recent'}',
                      style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    if (ver.changeSummary != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        ver.changeSummary!,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChangesTab(BuildContext context, List<ReportChangeModel> changes) {
    if (changes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: EmptyStateWidget(
          title: 'No Recorded Mutations',
          description: 'No field modifications have been recorded on this statutory report.',
          icon: Icons.compare_arrows,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: changes.length,
      itemBuilder: (context, index) {
        final chg = changes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Field: ${chg.field.toUpperCase()}',
                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  Text(
                    chg.timestamp ?? 'Recent',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Previous Value', style: TextStyle(fontSize: 10, color: AppColors.error)),
                          Text(chg.oldValue ?? 'None', style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Updated Value', style: TextStyle(fontSize: 10, color: AppColors.success)),
                          Text(chg.newValue ?? 'None', style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (chg.author != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Author: ${chg.author}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
