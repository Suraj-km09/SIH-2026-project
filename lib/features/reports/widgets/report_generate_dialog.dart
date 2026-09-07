import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/report_model.dart';
import '../../../state/document_state.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// Modal dialog for generating a statutory report using AI synthesis.
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
      builder: (context) => ReportGenerateDialog(onGenerate: onGenerate),
    );
  }

  @override
  ConsumerState<ReportGenerateDialog> createState() => _ReportGenerateDialogState();
}

class _ReportGenerateDialogState extends ConsumerState<ReportGenerateDialog> {
  String _selectedType = 'production_summary';
  late final TextEditingController _titleController;
  final Set<String> _selectedDocIds = {};
  String _language = 'en';

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: _defaultTitleForType(_selectedType));
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    _titleController.dispose();
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
      default:
        return 'Statutory Mining Report';
    }
  }

  Future<void> _handleGenerate() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Please enter a report title.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final request = ReportGenerateRequest(
      type: _selectedType,
      title: title,
      documentIds: _selectedDocIds.toList(),
      language: _language,
    );

    final result = await widget.onGenerate(request);

    if (mounted) {
      if (result != null) {
        Navigator.of(context).pop(result);
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to generate statutory report.';
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accentTeal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.auto_awesome, color: AppColors.accentTeal, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Generate Statutory Report',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
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
              const Divider(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.errorBorder),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                  ),
                ),
              ],

              // Report Type Selector
              Text(
                'Report Type',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
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
                        child: Text('Production Summary (ROM & Coal Yield)'),
                      ),
                      DropdownMenuItem(
                        value: 'variance_analysis',
                        child: Text('Variance Analysis (Overburden & Stripping Ratio)'),
                      ),
                      DropdownMenuItem(
                        value: 'compliance_audit',
                        child: Text('Compliance Audit (Dispatch & Weighbridge)'),
                      ),
                      DropdownMenuItem(
                        value: 'environmental_safeguards',
                        child: Text('Environmental Safeguards (Air, Water, Effluent)'),
                      ),
                    ],
                    onChanged: (val) {
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
              const SizedBox(height: 16),

              // Title Field
              Text(
                'Report Title *',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
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
              const SizedBox(height: 16),

              // Language Selector
              Row(
                children: [
                  Text(
                    'Language: ',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('English (en)'),
                    selected: _language == 'en',
                    onSelected: (sel) => setState(() => _language = 'en'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Hindi (hi)'),
                    selected: _language == 'hi',
                    onSelected: (sel) => setState(() => _language = 'hi'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Source Documents Picker
              Text(
                'Source Documents (Verification Context)',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: docs.isEmpty
                    ? const Center(
                        child: Text(
                          'Using default verified documents (doc_001)',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        children: docs.map((doc) {
                          final isChecked = _selectedDocIds.contains(doc.id);
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            title: Text(
                              (doc.filename != null && doc.filename!.isNotEmpty) ? doc.filename! : doc.id,
                              style: AppTypography.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'ID: ${doc.id} • ${doc.category}',
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                            value: isChecked,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedDocIds.add(doc.id);
                                } else {
                                  _selectedDocIds.remove(doc.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                    label: const Text('Generate Report'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
