import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/file_saver.dart';
import '../../models/document_model.dart';
import '../../models/extracted_record_model.dart';
import '../../network/api_client.dart';
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
  bool _isReprocessing = false;
  String _activeTab = 'all'; // 'all', 'needs_review', 'approved', 'rejected'

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

    final docs = docListState.documents;
    final targetDocId = widget.initialDocumentId ??
        (docs.isNotEmpty ? docs.first.id : 'doc-001');

    final extractionState = ref.read(extractionNotifierProvider);
    if (extractionState.activeDocumentId != targetDocId ||
        extractionState.status == ViewStatus.initial) {
      ref.read(extractionNotifierProvider.notifier).loadDocument(targetDocId);
    }
  }

  void _applyFilter() {
    final notifier = ref.read(extractionNotifierProvider.notifier);

    String? statusToQuery;
    if (_activeTab == 'needs_review') {
      statusToQuery = 'pending';
    } else if (_activeTab == 'approved') {
      statusToQuery = 'approved';
    } else if (_activeTab == 'rejected') {
      statusToQuery = 'rejected';
    } else if (_statusFilter != 'all') {
      statusToQuery = _statusFilter;
    }

    notifier.setFilter(
      ExtractionFilter(
        status: statusToQuery,
        parameter: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        minConfidence: _minConfidenceFilter,
      ),
    );
  }

  void _switchTab(String tab) {
    setState(() {
      _activeTab = tab;
      if (tab == 'needs_review') {
        _statusFilter = 'pending';
        _minConfidenceFilter = null;
      } else if (tab == 'approved') {
        _statusFilter = 'approved';
      } else if (tab == 'rejected') {
        _statusFilter = 'rejected';
      } else {
        _statusFilter = 'all';
      }
    });
    _applyFilter();
  }

  String _getDocumentTitle(DocumentModel? doc, String fallbackId) {
    if (doc != null) {
      if (doc.originalName.isNotEmpty &&
          doc.originalName != 'Untitled Document' &&
          !doc.originalName.startsWith('doc_') &&
          !doc.originalName.startsWith('doc-')) {
        return doc.originalName;
      }
      if (doc.filename != null && doc.filename!.isNotEmpty) {
        return doc.filename!;
      }
    }
    if (fallbackId == 'doc-001' || fallbackId == 'doc_001') {
      return 'ECL Rajmahal Production Report August.pdf';
    }
    if (fallbackId == 'doc-002' || fallbackId == 'doc_002') {
      return 'BCCL Dhanbad Safety Audit Q2 2026.docx';
    }
    if (fallbackId == 'doc-003' || fallbackId == 'doc_003') {
      return 'CCL Ranchi Environmental Compliance.pdf';
    }
    return 'Document $fallbackId';
  }

  Future<void> _reprocessDocument(String documentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.restart_alt, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Reprocess Document', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: const Text(
          'Reprocessing will clear the current extraction records and execute the full AI extraction pipeline from scratch on this source document.\n\nDo you want to proceed?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reprocess Now'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isReprocessing = true);
    try {
      try {
        await ApiClient().dio.post(ApiEndpoints.extractionReprocess(documentId));
      } catch (_) {
        // Fallback for mock/offline repository mode
      }
      await ref.read(extractionNotifierProvider.notifier).runExtraction(documentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document reprocessed successfully.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reprocess failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReprocessing = false);
      }
    }
  }

  void _showCitationSheet(BuildContext context, ExtractedRecordModel record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.verified_outlined, color: AppColors.accentTeal, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ground-Truth Citation & Audit',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildConfidenceBadge(record.confidence),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildDetailRow('Parameter', record.parameter),
                  _buildDetailRow('Extracted Value', '${record.value} ${record.unit ?? ''}'),
                  if (record.originalValue != null && record.originalValue != record.value)
                    _buildDetailRow('Original AI Value', '${record.originalValue} ${record.unit ?? ''}'),
                  _buildDetailRow('Page Number', 'Page ${record.pageNumber}'),
                  _buildDetailRow('Mine & Subsidiary', '${record.mineName ?? '—'} / ${record.subsidiary ?? '—'}'),
                  _buildDetailRow('Reporting Period', record.period ?? '—'),
                  _buildDetailRow('Verification Status', record.status.toUpperCase()),
                  const SizedBox(height: 16),
                  Text(
                    'Exact Document Excerpt:',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      record.sourceText != null && record.sourceText!.isNotEmpty
                          ? '"${record.sourceText}"'
                          : 'No ground-truth source text excerpt attached to this record.',
                      style: AppTypography.bodySmall.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (record.editHistory.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Audit Edit History (${record.editHistory.length} modification${record.editHistory.length > 1 ? 's' : ''}):',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: record.editHistory.map((h) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.history, size: 14, color: AppColors.accentBlue),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${h.field}: "${h.oldValue}" → "${h.newValue}" by ${h.editedBy ?? 'reviewer'}${h.editedAt != null ? ' (${h.editedAt})' : ''}',
                                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          RecordEditDialog.show(
                            context,
                            record: record,
                            onSave: (req) =>
                                ref.read(extractionNotifierProvider.notifier).updateRecord(record.id, req),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit Record'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportRecords(List<ExtractedRecordModel> records, String format) {
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No extracted records to export.')),
      );
      return;
    }

    if (format == 'csv') {
      final buffer = StringBuffer();
      buffer.write('\uFEFF');
      buffer.writeln('Parameter,Value,Unit,Period,Mine,Subsidiary,Confidence,Status,Page,SourceText');
      for (final r in records) {
        final escapedSource = (r.sourceText ?? '').replaceAll('"', '""');
        buffer.writeln(
          '"${r.parameter}","${r.value}","${r.unit ?? ''}","${r.period ?? ''}","${r.mineName ?? ''}","${r.subsidiary ?? ''}",${(r.confidence * 100).toStringAsFixed(1)},"${r.status}",${r.pageNumber},"$escapedSource"',
        );
      }
      final csvContent = buffer.toString();
      Clipboard.setData(ClipboardData(text: csvContent));
      FileSaver.saveAndLaunchText(
        csvContent,
        'extracted_records_${DateTime.now().millisecondsSinceEpoch}.csv',
        mimeType: 'text/csv;charset=utf-8',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${records.length} records to CSV format. Download started.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final jsonList = records.map((r) => r.toJson()).toList();
      final jsonContent = const JsonEncoder.withIndent('  ').convert(jsonList);
      Clipboard.setData(ClipboardData(text: jsonContent));
      FileSaver.saveAndLaunchText(
        jsonContent,
        'extracted_records_${DateTime.now().millisecondsSinceEpoch}.json',
        mimeType: 'application/json;charset=utf-8',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${records.length} records to JSON format. Download started.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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

    final docListState = ref.watch(documentListNotifierProvider);
    final docs = docListState.documents;

    // Automatically align active document with loaded list if fallback is obsolete
    ref.listen<DocumentListState>(documentListNotifierProvider, (prev, next) {
      if (next.documents.isNotEmpty) {
        final currentDocId = ref.read(extractionNotifierProvider).activeDocumentId;
        final hasMatch = next.documents.any((d) => d.id == currentDocId);
        if (!hasMatch && widget.initialDocumentId == null) {
          ref.read(extractionNotifierProvider.notifier).loadDocument(next.documents.first.id);
        }
      }
    });

    final activeDocId = state.activeDocumentId ??
        widget.initialDocumentId ??
        (docs.isNotEmpty ? docs.first.id : 'doc-001');

    final activeDoc = docs.cast<DocumentModel?>().firstWhere(
      (d) => d?.id == activeDocId,
      orElse: () => docs.isNotEmpty ? docs.first : null,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, state, activeDocId, activeDoc, docs, canApprove),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    DocumentModel? activeDoc,
    List<DocumentModel> docs,
    bool canApprove,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 800;
    final effectiveDocId = activeDoc?.id ?? activeDocId;
    final titleText = _getDocumentTitle(activeDoc, effectiveDocId);

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

    final documentDropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: docs.any((d) => d.id == effectiveDocId)
              ? effectiveDocId
              : (docs.isNotEmpty ? docs.first.id : null),
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isCompact ? 140 : 200),
                child: Text(
                  titleText,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          dropdownColor: AppColors.surface,
          items: docs.isEmpty
              ? [
                  DropdownMenuItem(
                    value: effectiveDocId,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Row(
                        children: [
                          const Icon(Icons.description_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              titleText,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ]
              : docs.map<DropdownMenuItem<String>>((d) {
                  final displayName = _getDocumentTitle(d, d.id);
                  final category = d.category.isNotEmpty ? d.category : d.fileType.toUpperCase();
                  return DropdownMenuItem<String>(
                    value: d.id,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isCompact ? 220 : 320),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '$category • ${d.totalPages > 0 ? '${d.totalPages} pages' : d.formattedFileSize}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          onChanged: (newId) {
            if (newId != null && newId != effectiveDocId) {
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: (state.isActionLoading || _isReprocessing)
          ? null
          : () => ref.read(extractionNotifierProvider.notifier).runExtraction(effectiveDocId),
      icon: state.isActionLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.play_arrow_outlined, size: 16),
      label: const Text('Run Extraction'),
    );

    final reprocessButton = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.warning,
        side: BorderSide(color: AppColors.warning.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: (state.isActionLoading || _isReprocessing)
          ? null
          : () => _reprocessDocument(effectiveDocId),
      icon: _isReprocessing
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.warning),
            )
          : const Icon(Icons.restart_alt, size: 16),
      label: const Text('Reprocess'),
    );

    final exportMenu = PopupMenuButton<String>(
      tooltip: 'Export Extracted Records',
      icon: const Icon(Icons.file_download_outlined, color: AppColors.textPrimary, size: 20),
      onSelected: (format) => _exportRecords(state.records, format),
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'csv',
          child: Row(
            children: [
              Icon(Icons.table_chart_outlined, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Export as CSV'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'json',
          child: Row(
            children: [
              Icon(Icons.code_outlined, size: 16, color: AppColors.accentTeal),
              SizedBox(width: 8),
              Text('Export as JSON'),
            ],
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 14 : 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
                    documentDropdown,
                    runButton,
                    reprocessButton,
                    exportMenu,
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: titleSection),
                const SizedBox(width: 12),
                documentDropdown,
                const SizedBox(width: 8),
                runButton,
                const SizedBox(width: 8),
                reprocessButton,
                const SizedBox(width: 4),
                exportMenu,
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
            : ((constraints.maxWidth - (count - 1) * 12 - 2) / count).floorToDouble();

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
    final total = state.summary?.totalRecords ?? state.records.length;
    final pending = state.summary?.pendingRecords ??
        state.records.where((r) => r.status == 'pending').length;
    final approved = state.summary?.approvedRecords ??
        state.records.where((r) => r.status == 'approved').length;
    final rejected = state.summary?.rejectedRecords ??
        state.records.where((r) => r.status == 'rejected').length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SegmentTab(
                  label: 'All Records',
                  count: total,
                  isActive: _activeTab == 'all',
                  onTap: () => _switchTab('all'),
                ),
                const SizedBox(width: 8),
                _SegmentTab(
                  label: 'Needs Review',
                  count: pending,
                  isActive: _activeTab == 'needs_review',
                  badgeColor: AppColors.warning,
                  onTap: () => _switchTab('needs_review'),
                ),
                const SizedBox(width: 8),
                _SegmentTab(
                  label: 'Approved',
                  count: approved,
                  isActive: _activeTab == 'approved',
                  badgeColor: AppColors.success,
                  onTap: () => _switchTab('approved'),
                ),
                const SizedBox(width: 8),
                _SegmentTab(
                  label: 'Rejected',
                  count: rejected,
                  isActive: _activeTab == 'rejected',
                  badgeColor: AppColors.error,
                  onTap: () => _switchTab('rejected'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Search & Filter input
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
                      hintText: 'Search parameter, mine, or keyword...',
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
          // Filter Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
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
              if (_searchController.text.isNotEmpty ||
                  _minConfidenceFilter != null ||
                  _statusFilter != 'all' ||
                  _activeTab != 'all')
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _minConfidenceFilter = null;
                      _statusFilter = 'all';
                      _activeTab = 'all';
                    });
                    _applyFilter();
                  },
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Reset Filters'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        final selectButtons = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: notifier.selectAllRecords,
              child: const Text('Select All'),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: notifier.clearSelection,
              child: const Text('Clear'),
            ),
          ],
        );

        final approveButton = Tooltip(
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
                        backgroundColor: AppColors.surface,
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
        );

        if (isNarrow) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_box_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$count of $total selected',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    selectButtons,
                  ],
                ),
                const SizedBox(height: 8),
                approveButton,
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_box_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                '$count of $total selected',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              selectButtons,
              const SizedBox(width: 12),
              approveButton,
            ],
          ),
        );
      },
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
        child: AppLoadingIndicator(message: 'Loading extracted parameters...'),
      );
    }

    if (state.isError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: ErrorStateWidget(
          message: state.errorMessage ?? 'Failed to load extraction records.',
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
          description: 'Click below to execute AI extraction of parameters and metrics from this document.',
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surfaceMuted),
          horizontalMargin: 16,
          columnSpacing: 18,
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
              label: Text('Source Citation',
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
                          message: 'Edited ${r.editHistory.length} time(s). Click citation to inspect.',
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
                      message: r.sourceText ?? 'No source citation',
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
                        message: 'Inspect Citation & Audit Details',
                        child: IconButton(
                          icon: const Icon(Icons.menu_book_outlined, size: 18),
                          color: AppColors.textSecondary,
                          onPressed: () => _showCitationSheet(context, r),
                        ),
                      ),
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.accentTeal : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Checkbox + Parameter Name + Confidence Badge
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
                  const SizedBox(width: 6),
                  _buildConfidenceBadge(r.confidence),
                ],
              ),
              const Divider(height: 16),

              // Value & Status Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
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
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
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

              // Source citation preview
              if (r.sourceText != null && r.sourceText!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '"${r.sourceText}"',
                    style: AppTypography.bodySmall.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Responsive Action Buttons (Zero-Overflow Wrap Layout)
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _showCitationSheet(context, r),
                      icon: const Icon(Icons.menu_book_outlined, size: 15),
                      label: const Text('Citation'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentBlue,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: !canEdit
                          ? null
                          : () => RecordEditDialog.show(
                                context,
                                record: r,
                                onSave: (req) => notifier.updateRecord(r.id, req),
                              ),
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: const Text('Edit'),
                    ),
                    if (r.status != 'rejected')
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: (!canApprove) ? null : () => notifier.rejectRecord(r.id),
                        icon: const Icon(Icons.close, size: 15),
                        label: const Text('Reject'),
                      ),
                    if (r.status != 'approved')
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: (!canApprove) ? null : () => notifier.approveRecord(r.id),
                        icon: const Icon(Icons.check, size: 15),
                        label: const Text('Approve'),
                      ),
                  ],
                ),
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

class _SegmentTab extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.label,
    required this.count,
    required this.isActive,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isActive ? Colors.white : AppColors.textPrimary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.25)
                    : (badgeColor?.withValues(alpha: 0.15) ?? AppColors.surface),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 10,
                  color: isActive ? Colors.white : (badgeColor ?? AppColors.textSecondary),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
