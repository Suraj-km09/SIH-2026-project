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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report?.title ?? 'Statutory Report Details',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
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
                ref.read(reportListNotifierProvider.notifier).exportReport(report.id, format);
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
            color: AppColors.surface,
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

        // Report Body Container (Chunked Markdown Viewer)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
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
    final lines = rawContent.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.startsWith('# ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Text(
              line.substring(2),
              style: AppTypography.headlineLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          );
        } else if (line.startsWith('## ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              line.substring(3),
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          );
        } else if (line.startsWith('### ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              line.substring(4),
              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          );
        } else if (line.startsWith('- ') || line.startsWith('* ')) {
          return Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(line.substring(2), style: AppTypography.bodyMedium),
                ),
              ],
            ),
          );
        } else if (line.trim().isEmpty) {
          return const SizedBox(height: 8);
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(line, style: AppTypography.bodyMedium.copyWith(height: 1.5)),
        );
      }).toList(),
    );
  }

  Widget _buildEvidenceTab(BuildContext context, List<CitedEvidenceModel> evidence) {
    if (evidence.isEmpty) {
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

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
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
                        ev.documentName ?? ev.documentId,
                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (ev.pageNumber != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
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
                  color: AppColors.surfaceMuted,
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
            color: AppColors.surface,
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
            color: AppColors.surface,
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
