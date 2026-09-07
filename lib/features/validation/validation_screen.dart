import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/validation_issue_model.dart';
import '../../state/app_state.dart';
import '../../state/auth_state.dart';
import '../../state/document_state.dart';
import '../../state/validation_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/status_chip.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/error_state.dart';
import '../../widgets/feedback/loading_indicator.dart';
import 'widgets/issue_resolution_dialog.dart';
import 'widgets/review_decision_dialog.dart';

/// Screen for Phase 7 Validation and Data Quality Engine.
class ValidationScreen extends ConsumerStatefulWidget {
  final String? initialDocumentId;

  const ValidationScreen({
    super.key,
    this.initialDocumentId,
  });

  @override
  ConsumerState<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends ConsumerState<ValidationScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all';
  String? _severityFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWorkspace();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeWorkspace() {
    final docListState = ref.read(documentListNotifierProvider);
    if (docListState.status == ViewStatus.initial) {
      ref.read(documentListNotifierProvider.notifier).loadDocuments();
    }

    final targetDocId = widget.initialDocumentId ??
        (docListState.documents.isNotEmpty ? docListState.documents.first.id : 'doc_001');

    final valState = ref.read(validationNotifierProvider);
    if (valState.activeDocumentId != targetDocId || valState.status == ViewStatus.initial) {
      ref.read(validationNotifierProvider.notifier).loadDocument(targetDocId);
    }
  }

  void _applyFilter() {
    final notifier = ref.read(validationNotifierProvider.notifier);
    notifier.setFilter(
      ValidationFilter(
        status: _statusFilter == 'all' ? null : _statusFilter,
        severity: _severityFilter,
        type: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(validationNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final canApprove = user?.isReviewer ?? false;
    final canResolve = (user?.role ?? 'viewer') != 'viewer';

    ref.listen<ValidationState>(validationNotifierProvider, (previous, next) {
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

    final docs = ref.watch(documentListNotifierProvider).documents;
    final activeDocId = state.activeDocumentId ?? widget.initialDocumentId ?? 'doc_001';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, state, activeDocId, docs, canApprove),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.accentTeal,
                onRefresh: () async {
                  if (state.activeDocumentId != null) {
                    await ref
                        .read(validationNotifierProvider.notifier)
                        .loadDocument(state.activeDocumentId!);
                  }
                },
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (state.summary != null) ...[
                      _buildQualityScoreHeader(state.summary!),
                      const SizedBox(height: 16),
                    ],
                    _buildFilterToolbar(context, state),
                    const SizedBox(height: 16),
                    _buildBody(context, state, activeDocId, canResolve),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ValidationState state,
    String activeDocId,
    List<dynamic> docs,
    bool canApprove,
  ) {
    final notifier = ref.read(validationNotifierProvider.notifier);
    final isCompact = MediaQuery.of(context).size.width < 900;

    final titleSection = Row(
      children: [
        if (Navigator.of(context).canPop()) ...[
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Validation & Quality Engine',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Phase 7',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.accentBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Rule-based integrity checks, math discrepancies, and governance review',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    final dropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: docs.any((d) => d.id == activeDocId) ? activeDocId : null,
          hint: Text(
            activeDocId,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          items: docs.isEmpty
              ? [
                  DropdownMenuItem(
                    value: activeDocId,
                    child: Text(activeDocId, style: AppTypography.bodySmall),
                  )
                ]
              : docs.map<DropdownMenuItem<String>>((d) {
                  final title = d.filename.isNotEmpty ? d.filename : d.id;
                  return DropdownMenuItem<String>(
                    value: d.id,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  );
                }).toList(),
          onChanged: (newId) {
            if (newId != null && newId != activeDocId) {
              notifier.loadDocument(newId);
            }
          },
        ),
      ),
    );

    final runValidationBtn = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: state.isActionLoading ? null : () => notifier.runValidation(activeDocId),
      icon: state.isActionLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.rule, size: 16),
      label: const Text('Run Validation'),
    );

    final reviewBtn = Tooltip(
      message: canApprove ? 'Submit Formal Review' : 'Requires Reviewer role',
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: (!canApprove || state.isActionLoading)
            ? null
            : () => ReviewDecisionDialog.show(
                  context,
                  documentId: activeDocId,
                  onSubmit: (req) => notifier.submitReview(activeDocId, req),
                ),
        icon: const Icon(Icons.rate_review_outlined, size: 16),
        label: const Text('Review'),
      ),
    );

    final approveBtn = Tooltip(
      message: canApprove ? 'Approve Entire Document Validation' : 'Requires Reviewer role',
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: (!canApprove || state.isActionLoading)
            ? null
            : () => notifier.approveValidation(activeDocId),
        icon: const Icon(Icons.verified_outlined, size: 16),
        label: const Text('Approve'),
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleSection,
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    dropdown,
                    runValidationBtn,
                    reviewBtn,
                    approveBtn,
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: titleSection),
                const SizedBox(width: 12),
                dropdown,
                const SizedBox(width: 8),
                runValidationBtn,
                const SizedBox(width: 8),
                reviewBtn,
                const SizedBox(width: 8),
                approveBtn,
              ],
            ),
    );
  }

  Widget _buildQualityScoreHeader(ValidationSummaryModel summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        final scoreCard = _buildScoreDialCard(summary);
        final breakdownCard = _buildBreakdownCard(summary);

        if (isMobile) {
          return Column(
            children: [
              scoreCard,
              const SizedBox(height: 12),
              breakdownCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 280, child: scoreCard),
            const SizedBox(width: 14),
            Expanded(child: breakdownCard),
          ],
        );
      },
    );
  }

  Widget _buildScoreDialCard(ValidationSummaryModel summary) {
    final score = summary.qualityScore;
    final Color scoreColor;
    final String scoreRating;

    if (score >= 90) {
      scoreColor = AppColors.success;
      scoreRating = 'EXCELLENT INTEGRITY';
    } else if (score >= 75) {
      scoreColor = AppColors.warning;
      scoreRating = 'GOOD (ATTENTION)';
    } else {
      scoreColor = AppColors.error;
      scoreRating = 'CRITICAL REVIEW';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            'DOCUMENT QUALITY SCORE',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 9,
                  backgroundColor: AppColors.surfaceMuted,
                  color: scoreColor,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: AppTypography.headlineLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              scoreRating,
              style: AppTypography.labelSmall.copyWith(
                color: scoreColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Avg Confidence: ${(summary.avgConfidence * 100).toStringAsFixed(1)}%',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(ValidationSummaryModel summary) {
    final sev = summary.bySeverity;
    final critical = sev['critical'] ?? 0;
    final error = sev['error'] ?? 0;
    final warning = sev['warning'] ?? 0;
    final info = sev['info'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
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
                'Validation Engine Telemetry',
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              StatusChip(
                status: summary.openIssues == 0 ? 'resolved' : 'pending',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Total Issues',
                  summary.totalIssues.toString(),
                  AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  'Open Issues',
                  summary.openIssues.toString(),
                  summary.openIssues > 0 ? AppColors.warning : AppColors.success,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  'Resolved Issues',
                  summary.resolvedIssues.toString(),
                  AppColors.success,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  'Records Checked',
                  summary.recordsCount.toString(),
                  AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            'Severity Distribution',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildSeverityPill('Critical', critical, AppColors.error, AppColors.errorBg),
              const SizedBox(width: 8),
              _buildSeverityPill('Error', error, const Color(0xFFEA580C), const Color(0xFFFFEDD5)),
              const SizedBox(width: 8),
              _buildSeverityPill('Warning', warning, AppColors.warning, AppColors.warningBg),
              const SizedBox(width: 8),
              _buildSeverityPill('Info', info, AppColors.accentBlue, const Color(0xFFEFF6FF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityPill(String label, int count, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar(BuildContext context, ValidationState state) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _applyFilter(),
                    style: AppTypography.bodySmall,
                    decoration: InputDecoration(
                      hintText: 'Search by issue type, parameter, or message...',
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilter();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: AppColors.surfaceMuted,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _applyFilter,
                icon: const Icon(Icons.filter_list, size: 16),
                label: const Text('Filter'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Status:',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              _FilterChip(
                label: 'All',
                isSelected: _statusFilter == 'all',
                onSelected: () {
                  setState(() => _statusFilter = 'all');
                  _applyFilter();
                },
              ),
              _FilterChip(
                label: 'Open',
                isSelected: _statusFilter == 'open',
                onSelected: () {
                  setState(() => _statusFilter = 'open');
                  _applyFilter();
                },
              ),
              _FilterChip(
                label: 'Resolved',
                isSelected: _statusFilter == 'resolved',
                onSelected: () {
                  setState(() => _statusFilter = 'resolved');
                  _applyFilter();
                },
              ),
              _FilterChip(
                label: 'Ignored',
                isSelected: _statusFilter == 'ignored',
                onSelected: () {
                  setState(() => _statusFilter = 'ignored');
                  _applyFilter();
                },
              ),
              const SizedBox(width: 16),
              Text(
                'Severity:',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              _FilterChip(
                label: 'All',
                isSelected: _severityFilter == null,
                onSelected: () {
                  setState(() => _severityFilter = null);
                  _applyFilter();
                },
              ),
              _FilterChip(
                label: 'Critical',
                isSelected: _severityFilter == 'critical',
                onSelected: () {
                  setState(() => _severityFilter = 'critical');
                  _applyFilter();
                },
              ),
              _FilterChip(
                label: 'Error',
                isSelected: _severityFilter == 'error',
                onSelected: () {
                  setState(() => _severityFilter = 'error');
                  _applyFilter();
                },
              ),
              _FilterChip(
                label: 'Warning',
                isSelected: _severityFilter == 'warning',
                onSelected: () {
                  setState(() => _severityFilter = 'warning');
                  _applyFilter();
                },
              ),
              _FilterChip(
                label: 'Info',
                isSelected: _severityFilter == 'info',
                onSelected: () {
                  setState(() => _severityFilter = 'info');
                  _applyFilter();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ValidationState state,
    String activeDocId,
    bool canResolve,
  ) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: AppLoadingIndicator(message: 'Executing validation engine...'),
      );
    }

    if (state.isError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: ErrorStateWidget(
          message: state.errorMessage ?? 'Failed to load validation issues.',
          onRetry: () {
            ref.read(validationNotifierProvider.notifier).loadDocument(activeDocId);
          },
        ),
      );
    }

    if (state.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: EmptyStateWidget(
          title: 'No Validation Issues Found',
          description:
              'All extracted parameters adhere to documented ranges, mathematical checks, and schemas.',
          icon: Icons.verified_user_outlined,
          actionText: 'Re-run Validation',
          onAction: () {
            ref.read(validationNotifierProvider.notifier).runValidation(activeDocId);
          },
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 850) {
          return _buildDesktopTable(context, state, canResolve);
        }
        return _buildMobileCardList(context, state, canResolve);
      },
    );
  }

  Widget _buildDesktopTable(
    BuildContext context,
    ValidationState state,
    bool canResolve,
  ) {
    final notifier = ref.read(validationNotifierProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surfaceMuted),
          horizontalMargin: 16,
          columnSpacing: 20,
          columns: [
            DataColumn(
              label: Text('Severity',
                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label:
                  Text('Type', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Field / Parameter',
                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Extracted Value',
                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Suggested / Expected',
                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Rule Violation Message',
                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Status',
                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Actions',
                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
            ),
          ],
          rows: state.issues.map((issue) {
            return DataRow(
              cells: [
                DataCell(StatusChip(status: issue.severity)),
                DataCell(
                  Text(
                    _formatType(issue.type),
                    style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                DataCell(
                  Text(
                    issue.field ?? '—',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                  ),
                ),
                DataCell(
                  Text(
                    issue.currentValue ?? '—',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    issue.suggestedValue ?? '—',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Tooltip(
                      message: issue.message,
                      child: Text(
                        issue.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
                DataCell(StatusChip(status: issue.status)),
                DataCell(
                  Tooltip(
                    message: canResolve ? 'Resolve issue' : 'Requires Operator or Reviewer role',
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentBlue,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: !canResolve
                          ? null
                          : () => IssueResolutionDialog.show(
                                context,
                                issue: issue,
                                onSave: (req) => notifier.resolveIssue(issue.id, req),
                              ),
                      icon: const Icon(Icons.build_outlined, size: 14),
                      label: Text(issue.status == 'open' ? 'Resolve' : 'Update'),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileCardList(
    BuildContext context,
    ValidationState state,
    bool canResolve,
  ) {
    final notifier = ref.read(validationNotifierProvider.notifier);

    return Column(
      children: state.issues.map((issue) {
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
                  StatusChip(status: issue.severity),
                  StatusChip(status: issue.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                issue.field ?? 'Unspecified Parameter',
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'Type: ${_formatType(issue.type)}',
                style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
              ),
              const Divider(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Extracted Value',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          issue.currentValue ?? 'N/A',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Suggested Value',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          issue.suggestedValue ?? 'None',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  issue.message,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                ),
              ),
              if (issue.resolutionNotes != null && issue.resolutionNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Resolution note: ${issue.resolutionNotes}',
                  style: AppTypography.bodySmall.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentBlue,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onPressed: !canResolve
                      ? null
                      : () => IssueResolutionDialog.show(
                            context,
                            issue: issue,
                            onSave: (req) => notifier.resolveIssue(issue.id, req),
                          ),
                  icon: const Icon(Icons.build_outlined, size: 16),
                  label: Text(issue.status == 'open' ? 'Resolve Issue' : 'Edit Resolution'),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatType(String raw) {
    return raw
        .split('_')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '')
        .join(' ');
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
