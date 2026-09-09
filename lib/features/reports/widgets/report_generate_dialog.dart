import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/report_model.dart';
import '../../../state/document_state.dart';
import '../../../state/report_state.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

enum _StageStatus { completed, inProgress, pending }

/// Modal dialog for generating a statutory report using AI synthesis.
/// Supports template selection, source document grounding, reporting period,
/// mine/subsidiary specification, custom instructions, animated multi-stage
/// generation tracking, and graceful rate-limit handling matching web reference.
class ReportGenerateDialog extends ConsumerStatefulWidget {
  final Future<ReportModel?> Function(ReportGenerateRequest request) onGenerate;

  const ReportGenerateDialog({
    super.key,
    required this.onGenerate,
  });

  static Future<ReportModel?> show(
    BuildContext context, {
    required Future<ReportModel?> Function(ReportGenerateRequest request) onGenerate,
  }) {
    return showDialog<ReportModel?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReportGenerateDialog(onGenerate: onGenerate),
    );
  }

  @override
  ConsumerState<ReportGenerateDialog> createState() => _ReportGenerateDialogState();
}

class _ReportGenerateDialogState extends ConsumerState<ReportGenerateDialog> {
  String _selectedType = 'production_summary';
  late final TextEditingController _titleController;
  late final TextEditingController _periodController;
  late final TextEditingController _mineController;
  late final TextEditingController _instructionsController;

  final Set<String> _selectedDocIds = {};
  String _language = 'en';

  bool _isSubmitting = false;
  int _currentStage = 0;
  Timer? _stageTimer;

  String? _errorHeader;
  String? _errorMessage;
  String? _suggestedAction;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: _defaultTitleForType(_selectedType));
    _periodController = TextEditingController(text: 'Q1 FY 2024-25');
    _mineController = TextEditingController(text: 'Jayant OCP / NCL');
    _instructionsController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentListNotifierProvider.notifier).loadDocuments();
      final docState = ref.read(documentListNotifierProvider);
      if (docState.documents.isNotEmpty) {
        setState(() {
          _selectedDocIds.add(docState.documents.first.id);
        });
      } else {
        _selectedDocIds.add('doc_001');
      }
    });
  }

  @override
  void dispose() {
    _stageTimer?.cancel();
    _titleController.dispose();
    _periodController.dispose();
    _mineController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  String _defaultTitleForType(String type) {
    switch (type) {
      case 'production_summary':
        return 'Monthly Statutory Production Summary - ${DateTime.now().year}';
      case 'variance_analysis':
        return 'Quarterly Overburden & Stripping Ratio Variance Analysis';
      case 'compliance_audit':
        return 'Statutory Mining Compliance & Dispatch Verification Audit';
      case 'environmental_safeguards':
        return 'Environmental Safeguards & Water Quality Effluent Audit';
      case 'comprehensive':
        return 'Comprehensive Mining Operations & Regulatory Analysis';
      default:
        return 'Statutory Mining Report';
    }
  }

  Future<void> _handleGenerate() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _errorHeader = 'Validation Error';
        _errorMessage = 'Please enter a formal report title.';
        _suggestedAction = 'Provide a descriptive title for this statutory filing.';
      });
      return;
    }

    if (_selectedDocIds.isEmpty) {
      setState(() {
        _errorHeader = 'Missing Context';
        _errorMessage = 'Please select at least one source document.';
        _suggestedAction = 'Select a verified document to ground the statutory synthesis.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _errorHeader = null;
      _suggestedAction = null;
      _currentStage = 0;
    });

    // Start animated progress stepper milestones
    _stageTimer?.cancel();
    _stageTimer = Timer.periodic(const Duration(milliseconds: 1500), (t) {
      if (!mounted) return;
      if (_currentStage < 3) {
        setState(() => _currentStage++);
      }
    });

    final request = ReportGenerateRequest(
      type: _selectedType,
      title: title,
      documentIds: _selectedDocIds.toList(),
      language: _language,
      period: _periodController.text.trim(),
      mine: _mineController.text.trim(),
      instructions: _instructionsController.text.trim(),
    );

    try {
      final result = await widget.onGenerate(request);
      _stageTimer?.cancel();

      if (mounted) {
        if (result != null) {
          Navigator.of(context).pop(result);
        } else {
          final errorState = ref.read(reportListNotifierProvider).errorMessage;
          final isRateLimit = errorState != null &&
              (errorState.toLowerCase().contains('rate limit') ||
                  errorState.toLowerCase().contains('429'));

          setState(() {
            _isSubmitting = false;
            _errorHeader = 'Report Generation Failed';
            _errorMessage = errorState ?? 'Failed to generate statutory report.';
            _suggestedAction = isRateLimit
                ? 'Narrow the source document or reporting period, or retry after a moment.'
                : 'Verify selected source document parameters and retry.';
          });
        }
      }
    } catch (e) {
      _stageTimer?.cancel();
      if (mounted) {
        final errText = e.toString().replaceFirst('Exception: ', '');
        final isRateLimit = errText.toLowerCase().contains('rate limit') ||
            errText.toLowerCase().contains('429');

        setState(() {
          _isSubmitting = false;
          _errorHeader = 'Report Generation Failed';
          _errorMessage = errText;
          _suggestedAction = isRateLimit
              ? 'Narrow the source document or reporting period, or retry after a moment.'
              : 'Verify network connection and retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(documentListNotifierProvider).documents;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Report Generator',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Statutory Mining Intelligence & Regulatory Filings',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Scrollable Body
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rate Limit / Failure Alert Banner (Matches Image 2)
                      if (_errorMessage != null) ...[
                        _buildErrorBanner(),
                        const SizedBox(height: 16),
                      ],

                      // Multi-Stage Progress Tracker (Matches User Request)
                      if (_isSubmitting) ...[
                        _buildMultiStageTracker(),
                        const SizedBox(height: 16),
                      ],

                      // Report Template / Type Selector
                      _buildSectionLabel('Report Template *'),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedType,
                            items: const [
                              DropdownMenuItem(
                                value: 'production_summary',
                                child: Text('Monthly Statutory Production Summary (ROM & Coal)'),
                              ),
                              DropdownMenuItem(
                                value: 'variance_analysis',
                                child: Text('Quarterly Variance Analysis (OB & Stripping Ratio)'),
                              ),
                              DropdownMenuItem(
                                value: 'compliance_audit',
                                child: Text('Compliance Audit (Dispatch & Weighbridge)'),
                              ),
                              DropdownMenuItem(
                                value: 'environmental_safeguards',
                                child: Text('Environmental Safeguards (Air, Water, Effluent)'),
                              ),
                              DropdownMenuItem(
                                value: 'comprehensive',
                                child: Text('Comprehensive Mining Operations Analysis'),
                              ),
                            ],
                            onChanged: _isSubmitting
                                ? null
                                : (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedType = val;
                                        _titleController.text = _defaultTitleForType(val);
                                      });
                                    }
                                  },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Title Field
                      _buildSectionLabel('Report Title *'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _titleController,
                        enabled: !_isSubmitting,
                        style: AppTypography.bodySmall,
                        decoration: InputDecoration(
                          hintText: 'Enter formal statutory report title...',
                          filled: true,
                          fillColor: AppColors.surfaceMuted,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Period & Mine Fields in 2 columns (Responsive)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 420;
                          final periodField = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionLabel('Reporting Period'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _periodController,
                                enabled: !_isSubmitting,
                                style: AppTypography.bodySmall,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Q1 FY 2024-25',
                                  filled: true,
                                  fillColor: AppColors.surfaceMuted,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: AppColors.border),
                                  ),
                                ),
                              ),
                            ],
                          );

                          final mineField = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionLabel('Mine / Subsidiary'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _mineController,
                                enabled: !_isSubmitting,
                                style: AppTypography.bodySmall,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Jayant OCP / NCL',
                                  filled: true,
                                  fillColor: AppColors.surfaceMuted,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: AppColors.border),
                                  ),
                                ),
                              ),
                            ],
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                periodField,
                                const SizedBox(height: 12),
                                mineField,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: periodField),
                              const SizedBox(width: 12),
                              Expanded(child: mineField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Custom Instructions (Optional)
                      _buildSectionLabel('Custom Instructions (Optional)'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _instructionsController,
                        enabled: !_isSubmitting,
                        maxLines: 2,
                        style: AppTypography.bodySmall,
                        decoration: InputDecoration(
                          hintText: 'e.g. Focus on stripping ratio variance and compliance notes...',
                          filled: true,
                          fillColor: AppColors.surfaceMuted,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Language Selector (Wrap prevents right overflow on mobile screens)
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Text(
                            'Language:',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('English (en)'),
                            selected: _language == 'en',
                            onSelected: _isSubmitting
                                ? null
                                : (sel) => setState(() => _language = 'en'),
                          ),
                          ChoiceChip(
                            label: const Text('Hindi (hi)'),
                            selected: _language == 'hi',
                            onSelected: _isSubmitting
                                ? null
                                : (sel) => setState(() => _language = 'hi'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Source Documents Picker (Fixes bug: shows originalName instead of hash ID)
                      Row(
                        children: [
                          Expanded(
                            child: _buildSectionLabel('Source Documents (Grounding Context)'),
                          ),
                          if (_selectedDocIds.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_selectedDocIds.length} Selected',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Material(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox(
                          height: 120,
                          child: docs.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Using default verified document context (doc_001)',
                                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  itemCount: docs.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 48),
                                  itemBuilder: (context, index) {
                                    final doc = docs[index];
                                    final isChecked = _selectedDocIds.contains(doc.id);
                                    // Clean user-friendly original document name
                                    final displayName = (doc.originalName.isNotEmpty &&
                                            doc.originalName != 'Untitled Document')
                                        ? doc.originalName
                                        : (doc.filename != null && doc.filename!.isNotEmpty
                                            ? doc.filename!
                                            : doc.id);

                                    return CheckboxListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                      secondary: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: isChecked
                                              ? AppColors.primary.withValues(alpha: 0.12)
                                              : AppColors.surface,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          doc.fileType.toLowerCase() == 'pdf'
                                              ? Icons.picture_as_pdf_outlined
                                              : (doc.fileType.toLowerCase() == 'csv' ||
                                                      doc.fileType.toLowerCase() == 'xlsx'
                                                  ? Icons.table_chart_outlined
                                                  : Icons.description_outlined),
                                          size: 16,
                                          color: isChecked ? AppColors.primary : AppColors.textSecondary,
                                        ),
                                      ),
                                      title: Text(
                                        displayName,
                                        style: AppTypography.bodySmall.copyWith(
                                          fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '${doc.fileType.toUpperCase()} • ${doc.formattedFileSize} • ${doc.category.toUpperCase()}',
                                        style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                      ),
                                      value: isChecked,
                                      onChanged: _isSubmitting
                                          ? null
                                          : (val) {
                                              setState(() {
                                                if (val == true) {
                                                  _selectedDocIds.add(doc.id);
                                                } else {
                                                  _selectedDocIds.remove(doc.id);
                                                }
                                              });
                                            },
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Action Buttons (Wrap ensures no overflow on narrow mobile screens)
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: const Text('Cancel'),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSubmitting ? null : _handleGenerate,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome, size: 16),
                      label: Text(_isSubmitting ? 'Synthesizing...' : 'Generate Statutory Report'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTypography.labelMedium.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  /// Multi-stage visual progress tracker during AI synthesis.
  Widget _buildMultiStageTracker() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Synthesizing Statutory Report...',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStageItem(
            stepNumber: 1,
            title: 'Document Context Loaded & Grounded',
            status: _currentStage >= 1 ? _StageStatus.completed : _StageStatus.inProgress,
          ),
          const SizedBox(height: 8),
          _buildStageItem(
            stepNumber: 2,
            title: 'RAG Retrieval & Mining Telemetry Query',
            status: _currentStage > 1
                ? _StageStatus.completed
                : (_currentStage == 1 ? _StageStatus.inProgress : _StageStatus.pending),
          ),
          const SizedBox(height: 8),
          _buildStageItem(
            stepNumber: 3,
            title: 'LLM Synthesis & Statutory Variance Analysis',
            status: _currentStage > 2
                ? _StageStatus.completed
                : (_currentStage == 2 ? _StageStatus.inProgress : _StageStatus.pending),
          ),
          const SizedBox(height: 8),
          _buildStageItem(
            stepNumber: 4,
            title: 'Formatting Structured Tables & Citations',
            status: _currentStage >= 3 ? _StageStatus.inProgress : _StageStatus.pending,
          ),
        ],
      ),
    );
  }

  Widget _buildStageItem({
    required int stepNumber,
    required String title,
    required _StageStatus status,
  }) {
    final Widget indicator;
    final Color textColor;
    final String statusLabel;

    switch (status) {
      case _StageStatus.completed:
        indicator = const Icon(Icons.check_circle, size: 16, color: AppColors.success);
        textColor = AppColors.textPrimary;
        statusLabel = 'Completed';
        break;
      case _StageStatus.inProgress:
        indicator = const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        );
        textColor = AppColors.primary;
        statusLabel = 'In progress...';
        break;
      case _StageStatus.pending:
        indicator = const Icon(Icons.radio_button_unchecked, size: 16, color: AppColors.textMuted);
        textColor = AppColors.textMuted;
        statusLabel = 'Queued';
        break;
    }

    return Row(
      children: [
        indicator,
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: textColor,
              fontWeight: status == _StageStatus.inProgress ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          statusLabel,
          style: TextStyle(
            fontSize: 10.5,
            color: status == _StageStatus.completed
                ? AppColors.success
                : (status == _StageStatus.inProgress ? AppColors.primary : AppColors.textMuted),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Rate Limit / Failure Alert Banner matching Web Generator screenshot (Image 2).
  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _errorHeader ?? 'Report Generation Failed',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                    children: [
                      const TextSpan(
                        text: 'Reason: ',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                      ),
                      TextSpan(text: _errorMessage!),
                    ],
                  ),
                ),
                if (_suggestedAction != null) ...[
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      children: [
                        const TextSpan(
                          text: 'Suggested action: ',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        TextSpan(text: _suggestedAction!),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
