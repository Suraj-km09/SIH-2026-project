import 'package:flutter/material.dart';
import '../../../models/validation_issue_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/badges/status_chip.dart';

/// Modal dialog for resolving or ignoring a validation issue.
class IssueResolutionDialog extends StatefulWidget {
  final ValidationIssueModel issue;
  final Future<bool> Function(ValidationIssueUpdateRequest request) onSave;

  const IssueResolutionDialog({
    super.key,
    required this.issue,
    required this.onSave,
  });

  static Future<bool?> show(
    BuildContext context, {
    required ValidationIssueModel issue,
    required Future<bool> Function(ValidationIssueUpdateRequest request) onSave,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => IssueResolutionDialog(issue: issue, onSave: onSave),
    );
  }

  @override
  State<IssueResolutionDialog> createState() => _IssueResolutionDialogState();
}

class _IssueResolutionDialogState extends State<IssueResolutionDialog> {
  late String _status; // 'resolved' | 'ignored'
  late String _action; // 'corrected_value' | 'manual_override' | 'false_positive' | 'source_error'
  late final TextEditingController _correctedValueController;
  late final TextEditingController _notesController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _status = widget.issue.status == 'open' ? 'resolved' : widget.issue.status;
    _action = 'corrected_value';
    _correctedValueController = TextEditingController(
      text: widget.issue.suggestedValue ?? widget.issue.currentValue ?? '',
    );
    _notesController = TextEditingController(
      text: widget.issue.resolutionNotes ?? '',
    );
  }

  @override
  void dispose() {
    _correctedValueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final request = ValidationIssueUpdateRequest(
      status: _status,
      resolution: _action,
      correctedValue: (_action == 'corrected_value' || _action == 'manual_override')
          ? _correctedValueController.text.trim()
          : null,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    final success = await widget.onSave(request);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to update validation issue resolution.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Resolve Validation Issue',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              StatusChip(status: widget.issue.severity),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Issue ID: ${widget.issue.id}',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
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

              // Error alert if present
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.errorBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Issue Context Details Card
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            'Field / Parameter',
                            widget.issue.field ?? 'Unspecified',
                          ),
                        ),
                        Expanded(
                          child: _buildDetailItem(
                            'Validation Type',
                            widget.issue.type.replaceAll('_', ' ').toUpperCase(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            'Extracted Value',
                            widget.issue.currentValue ?? 'N/A',
                            valueColor: AppColors.error,
                          ),
                        ),
                        Expanded(
                          child: _buildDetailItem(
                            'Suggested Value',
                            widget.issue.suggestedValue ?? 'None',
                            valueColor: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Message / Rule Violation',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.issue.message,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),

              // Resolution Status Selector
              Text(
                'Resolution Target Status',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusOption(
                      title: 'Resolved',
                      subtitle: 'Fix applied or verified',
                      value: 'resolved',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusOption(
                      title: 'Ignored',
                      subtitle: 'Mark as intentional exception',
                      value: 'ignored',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Resolution Action Dropdown
              Text(
                'Resolution Action',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
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
                    value: _action,
                    items: const [
                      DropdownMenuItem(
                        value: 'corrected_value',
                        child: Text('Corrected Value (Update Extracted Value)'),
                      ),
                      DropdownMenuItem(
                        value: 'manual_override',
                        child: Text('Manual Override (Approved by Operator)'),
                      ),
                      DropdownMenuItem(
                        value: 'false_positive',
                        child: Text('False Positive (Rule does not apply)'),
                      ),
                      DropdownMenuItem(
                        value: 'source_error',
                        child: Text('Source Error (Document contains typo)'),
                      ),
                    ],
                    onChanged: (val) => setState(() => _action = val!),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Corrected Value Field (shown if corrected_value or manual_override)
              if (_action == 'corrected_value' || _action == 'manual_override') ...[
                Text(
                  'Corrected Value',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _correctedValueController,
                  style: AppTypography.bodySmall,
                  decoration: InputDecoration(
                    hintText: 'Enter corrected value for parameter...',
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Resolution Notes
              Text(
                'Resolution Notes',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _notesController,
                maxLines: 2,
                style: AppTypography.bodySmall,
                decoration: InputDecoration(
                  hintText: 'Reason for resolution / audit comments...',
                  filled: true,
                  fillColor: AppColors.surfaceMuted,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: const Text('Save Resolution'),
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

  Widget _buildStatusOption({
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _status == value;
    final color = value == 'resolved' ? AppColors.success : AppColors.textSecondary;

    return InkWell(
      onTap: () => setState(() => _status = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? color : AppColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
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
  }

  Widget _buildDetailItem(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
