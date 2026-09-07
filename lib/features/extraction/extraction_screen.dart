import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/extracted_record_model.dart';
import '../../state/app_state.dart';
import '../../state/auth_state.dart';
import '../../state/document_state.dart';
import '../../state/extraction_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/status_chip.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/error_state.dart';
import '../../widgets/feedback/loading_indicator.dart';
import 'widgets/record_edit_dialog.dart';

/// Screen for Phase 7 Extraction and Human-in-the-loop (HITL) Verification.
class ExtractionScreen extends ConsumerStatefulWidget {
  final String? initialDocumentId;

  const ExtractionScreen({
    super.key,
    this.initialDocumentId,
  });

  @override
  ConsumerState<ExtractionScreen> createState() => _ExtractionScreenState();
}

class _ExtractionScreenState extends ConsumerState<ExtractionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all';
  double? _minConfidenceFilter;

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

    final extractionState = ref.read(extractionNotifierProvider);
    if (extractionState.activeDocumentId != targetDocId ||
        extractionState.status == ViewStatus.initial) {
      ref.read(extractionNotifierProvider.notifier).loadDocument(targetDocId);
    }
  }

  void _applyFilter() {
    final notifier = ref.read(extractionNotifierProvider.notifier);
    notifier.setFilter(
      ExtractionFilter(
        status: _statusFilter == 'all' ? null : _statusFilter,
        parameter: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        minConfidence: _minConfidenceFilter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(extractionNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final canApprove = user?.isReviewer ?? false;
    final canEdit = (user?.role ?? 'viewer') != 'viewer';

    ref.listen<ExtractionState>(extractionNotifierProvider, (previous, next) {
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
                        .read(extractionNotifierProvider.notifier)
                        .loadDocument(state.activeDocumentId!);
                  }
                },
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (state.summary != null) _buildSummaryCards(state.summary!),
                    const SizedBox(height: 16),
                    _buildFilterToolbar(context, state),
                    const SizedBox(height: 16),
                    if (state.selectedRecordIds.isNotEmpty)
                      _buildBulkActionBar(context, state, canApprove),
                    if (state.selectedRecordIds.isNotEmpty) const SizedBox(height: 16),
                    _buildBody(context, state, canEdit, canApprove),
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
    ExtractionState state,
    String activeDocId,
    List<dynamic> docs,
    bool canApprove,
  ) {
    final isCompact = MediaQuery.of(context).size.width < 768;

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
                    'Data Extraction & HITL Workspace',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Phase 7',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.accentTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Automated parameter extraction with human-in-the-loop audit verification',
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
                      constraints: const BoxConstraints(maxWidth: 180),
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
              ref.read(extractionNotifierProvider.notifier).loadDocument(newId);
            }
          },
        ),
      ),
    );

    final runButton = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: state.isActionLoading
          ? null
          : () => ref.read(extractionNotifierProvider.notifier).runExtraction(activeDocId),
      icon: state.isActionLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.play_arrow_outlined, size: 18),
      label: const Text('Run Extraction'),
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
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    dropdown,
                    runButton,
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: titleSection),
                const SizedBox(width: 12),
                dropdown,
                const SizedBox(width: 12),
                runButton,
              ],
            ),
    );
  }

  Widget _buildSummaryCards(ExtractionSummaryStats summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth < 360
            ? 1
            : (constraints.maxWidth < 700 ? 2 : 5);
        final isMobile = constraints.maxWidth < 700;
        final itemWidth = count == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - (count - 1) * 12) / count;

        final cards = [
          _StatCard(
            label: 'Total Records',
            value: summary.totalRecords.toString(),
            icon: Icons.list_alt,
            color: AppColors.textPrimary,
          ),
          _StatCard(
            label: 'Approved',
            value: summary.approvedRecords.toString(),
            icon: Icons.check_circle_outline,
            color: AppColors.success,
          ),
          _StatCard(
            label: 'Pending',
            value: summary.pendingRecords.toString(),
            icon: Icons.pending_outlined,
            color: AppColors.warning,
          ),
          _StatCard(
            label: 'Rejected',
            value: summary.rejectedRecords.toString(),
            icon: Icons.cancel_outlined,
            color: AppColors.error,
          ),
          _StatCard(
            label: 'Avg Confidence',
            value: '${summary.averageConfidence.toStringAsFixed(1)}%',
            icon: Icons.analytics_outlined,
            color: summary.averageConfidence >= 85
                ? AppColors.success
                : (summary.averageConfidence >= 70 ? AppColors.warning : AppColors.error),
          ),
        ];

        if (isMobile) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards.map((c) => SizedBox(width: itemWidth, child: c)).toList(),
          );
        }

        return Row(
          children: cards
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: c,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildFilterToolbar(BuildContext context, ExtractionState state) {
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
                      hintText: 'Search by parameter, mine, or keyword...',
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
                label: 'Pending',
                isSelected: _statusFilter == 'pending',
                onSelected: () {
                  setState(() => _statusFilter = 'pending');
                  _applyFilter();
                },
              ),
              _FilterChip(
                label: 'Approved',
                isSelected: _statusFilter == 'approved',
                onSelected: () {
                  setState(() => _statusFilter = 'approved');
                  _applyFilter();
                },
              ),
              _FilterChip(
                label: 'Rejected',
                isSelected: _statusFilter == 'rejected',
                onSelected: () {
                  setState(() => _statusFilter = 'rejected');
                  _applyFilter();
                },
              ),
              const SizedBox(width: 16),
              Text(
                'Confidence:',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              _FilterChip(
                label: 'All',
                isSelected: _minConfidenceFilter == null,
                onSelected: () {
                  setState(() => _minConfidenceFilter = null);
                  _applyFilter();
                },
              ),
              _FilterChip(
                label: '≥ 90% High',
                isSelected: _minConfidenceFilter == 90.0,
                onSelected: () {
                  setState(() => _minConfidenceFilter = 90.0);
                  _applyFilter();
                },
              ),
              _FilterChip(
                label: '≥ 75% Med',
                isSelected: _minConfidenceFilter == 75.0,
                onSelected: () {
                  setState(() => _minConfidenceFilter = 75.0);
                  _applyFilter();
                },
              ),
              _FilterChip(
                label: '< 80% Flagged',
                isSelected: _minConfidenceFilter == -80.0,
                onSelected: () {
                  setState(() => _minConfidenceFilter = -80.0);
                  _applyFilter();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionBar(BuildContext context, ExtractionState state, bool canApprove) {
    final count = state.selectedRecordIds.length;
    final total = state.records.length;
    final notifier = ref.read(extractionNotifierProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_box_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Text(
            '$count of $total selected',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: notifier.selectAllRecords,
            child: const Text('Select All'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: notifier.clearSelection,
            child: const Text('Clear'),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: canApprove ? 'Bulk approve selected records' : 'Requires Reviewer or Admin role',
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: (!canApprove || state.isActionLoading)
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirm Bulk Approval'),
                          content: Text('Are you sure you want to approve $count selected records?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Approve All'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        notifier.bulkApprove();
                      }
                    },
              icon: state.isActionLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.done_all, size: 18),
              label: Text('Bulk Approve ($count)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ExtractionState state,
    bool canEdit,
    bool canApprove,
  ) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: AppLoadingIndicator(message: 'Loading extracted records...'),
      );
    }

    if (state.isError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: ErrorStateWidget(
          message: state.errorMessage ?? 'Failed to load records.',
          onRetry: () {
            if (state.activeDocumentId != null) {
              ref.read(extractionNotifierProvider.notifier).loadDocument(state.activeDocumentId!);
            }
          },
        ),
      );
    }

    if (state.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: EmptyStateWidget(
          title: 'No Extracted Records Found',
          description: 'Click below to parse structured parameters and entities from this document.',
          icon: Icons.document_scanner_outlined,
          actionText: 'Run Extraction Now',
          onAction: () {
            if (state.activeDocumentId != null) {
              ref.read(extractionNotifierProvider.notifier).runExtraction(state.activeDocumentId!);
            }
          },
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 850) {
          return _buildDesktopTable(context, state, canEdit, canApprove);
        }
        return _buildMobileCardList(context, state, canEdit, canApprove);
      },
    );
  }

  Widget _buildDesktopTable(
    BuildContext context,
    ExtractionState state,
    bool canEdit,
    bool canApprove,
  ) {
    final notifier = ref.read(extractionNotifierProvider.notifier);
    final allSelected =
        state.records.isNotEmpty && state.selectedRecordIds.length == state.records.length;

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
          showCheckboxColumn: false,
          columns: [
            DataColumn(
              label: Row(
                children: [
                  Checkbox(
                    value: allSelected,
                    onChanged: (val) {
                      if (val == true) {
                        notifier.selectAllRecords();
                      } else {
                        notifier.clearSelection();
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  Text('Parameter', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            DataColumn(
              label: Text('Value & Unit',
                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Period',
                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Mine / Subsidiary',
                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Confidence',
                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Status',
                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Source Text',
                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Actions',
                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
            ),
          ],
          rows: state.records.map((r) {
            final isSelected = state.selectedRecordIds.contains(r.id);
            return DataRow(
              selected: isSelected,
              onSelectChanged: (_) => notifier.toggleRecordSelection(r.id),
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => notifier.toggleRecordSelection(r.id),
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          r.parameter,
                          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    '${r.value} ${r.unit ?? ''}',
                    style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    r.period ?? '—',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                DataCell(
                  Text(
                    '${r.mineName ?? '—'} / ${r.subsidiary ?? '—'}',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                DataCell(_buildConfidenceBadge(r.confidence)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusChip(status: r.status),
                      if (r.editHistory.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Tooltip(
                          message: 'Edited ${r.editHistory.length} time(s)',
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.history, size: 11, color: AppColors.accentBlue),
                                const SizedBox(width: 3),
                                Text(
                                  '${r.editHistory.length}',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 10,
                                    color: AppColors.accentBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Tooltip(
                      message: r.sourceText ?? 'No source text available',
                      child: Text(
                        r.sourceText ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: canEdit ? 'Edit Record' : 'Requires Operator/Reviewer role',
                        child: IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          color: canEdit ? AppColors.accentBlue : AppColors.textMuted,
                          onPressed: !canEdit
                              ? null
                              : () => RecordEditDialog.show(
                                    context,
                                    record: r,
                                    onSave: (req) => notifier.updateRecord(r.id, req),
                                  ),
                        ),
                      ),
                      Tooltip(
                        message: canApprove ? 'Approve Record' : 'Requires Reviewer role',
                        child: IconButton(
                          icon: const Icon(Icons.check, size: 18),
                          color: canApprove ? AppColors.success : AppColors.textMuted,
                          onPressed: (!canApprove || r.status == 'approved')
                              ? null
                              : () => notifier.approveRecord(r.id),
                        ),
                      ),
                      Tooltip(
                        message: canApprove ? 'Reject Record' : 'Requires Reviewer role',
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: canApprove ? AppColors.error : AppColors.textMuted,
                          onPressed: (!canApprove || r.status == 'rejected')
                              ? null
                              : () => notifier.rejectRecord(r.id),
                        ),
                      ),
                    ],
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
    ExtractionState state,
    bool canEdit,
    bool canApprove,
  ) {
    final notifier = ref.read(extractionNotifierProvider.notifier);

    return Column(
      children: state.records.map((r) {
        final isSelected = state.selectedRecordIds.contains(r.id);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.accentTeal : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => notifier.toggleRecordSelection(r.id),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.parameter,
                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${r.mineName ?? '—'} • ${r.subsidiary ?? '—'} • ${r.period ?? '—'}',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _buildConfidenceBadge(r.confidence),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Extracted Value',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${r.value} ${r.unit ?? ''}',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      StatusChip(status: r.status),
                      if (r.editHistory.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${r.editHistory.length} edit(s)',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 10,
                              color: AppColors.accentBlue,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              if (r.sourceText != null && r.sourceText!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '"${r.sourceText}"',
                    style: AppTypography.bodySmall.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentBlue,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    onPressed: !canEdit
                        ? null
                        : () => RecordEditDialog.show(
                              context,
                              record: r,
                              onSave: (req) => notifier.updateRecord(r.id, req),
                            ),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  if (r.status != 'rejected')
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                      ),
                      onPressed: (!canApprove) ? null : () => notifier.rejectRecord(r.id),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                    ),
                  const SizedBox(width: 8),
                  if (r.status != 'approved')
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                      onPressed: (!canApprove) ? null : () => notifier.approveRecord(r.id),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                    ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    final pct = (confidence * (confidence <= 1.0 ? 100 : 1)).round();
    final Color color;
    final Color bg;

    if (pct >= 90) {
      color = AppColors.success;
      bg = AppColors.successBg;
    } else if (pct >= 75) {
      color = AppColors.warning;
      bg = AppColors.warningBg;
    } else {
      color = AppColors.error;
      bg = AppColors.errorBg;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$pct%',
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                label,
                style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
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
