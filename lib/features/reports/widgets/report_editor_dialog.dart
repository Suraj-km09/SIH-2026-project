import 'package:flutter/material.dart';
import '../../../models/report_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// Modal dialog for editing report title and markdown content.
class ReportEditorDialog extends StatefulWidget {
  final ReportModel report;
  final Future<bool> Function(ReportUpdateRequest request) onSave;

  const ReportEditorDialog({
    super.key,
    required this.report,
    required this.onSave,
  });

  static Future<bool?> show(
    BuildContext context, {
    required ReportModel report,
    required Future<bool> Function(ReportUpdateRequest request) onSave,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ReportEditorDialog(report: report, onSave: onSave),
    );
  }

  @override
  State<ReportEditorDialog> createState() => _ReportEditorDialogState();
}

class _ReportEditorDialogState extends State<ReportEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late String _type;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.report.title);
    _contentController = TextEditingController(text: widget.report.contentAsString);
    _type = widget.report.type;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Title cannot be empty.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final request = ReportUpdateRequest(
      title: title,
      content: _contentController.text,
      type: _type,
    );

    final success = await widget.onSave(request);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to save report updates.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Statutory Report (v${widget.report.version})',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Report ID: ${widget.report.id} • Status: ${widget.report.status.toUpperCase()}',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const Divider(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
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

              // Title and Type
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 500;
                  final titleField = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Report Title',
                          style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _titleController,
                        style: AppTypography.bodySmall,
                        decoration: InputDecoration(
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

                  final typeField = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Report Type',
                          style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _type,
                            items: const [
                              DropdownMenuItem(value: 'production_summary', child: Text('Production Summary')),
                              DropdownMenuItem(value: 'variance_analysis', child: Text('Variance Analysis')),
                              DropdownMenuItem(value: 'compliance_audit', child: Text('Compliance Audit')),
                              DropdownMenuItem(value: 'environmental_safeguards', child: Text('Environmental')),
                            ],
                            onChanged: (v) => setState(() => _type = v!),
                          ),
                        ),
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        titleField,
                        const SizedBox(height: 10),
                        typeField,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(flex: 2, child: titleField),
                      const SizedBox(width: 12),
                      Expanded(flex: 1, child: typeField),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Content Markdown Field
              Text(
                'Report Content (Markdown & Statistical Narrative)',
                style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.4),
                  decoration: InputDecoration(
                    hintText: 'Enter report markdown content...',
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
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
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSaving ? null : _handleSave,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_outlined, size: 16),
                      label: const Text('Save Changes'),
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
}
