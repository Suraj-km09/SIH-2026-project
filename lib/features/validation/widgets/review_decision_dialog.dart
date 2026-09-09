import 'package:flutter/material.dart';
import '../../../models/validation_issue_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// Modal dialog for submitting a formal document validation review decision.
class ReviewDecisionDialog extends StatefulWidget {
  final String documentId;
  final String? documentName;
  final Future<bool> Function(ValidationReviewRequest request) onSubmit;

  const ReviewDecisionDialog({
    super.key,
    required this.documentId,
    this.documentName,
    required this.onSubmit,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String documentId,
    String? documentName,
    required Future<bool> Function(ValidationReviewRequest request) onSubmit,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ReviewDecisionDialog(
        documentId: documentId,
        documentName: documentName,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<ReviewDecisionDialog> createState() => _ReviewDecisionDialogState();
}

class _ReviewDecisionDialogState extends State<ReviewDecisionDialog> {
  String _decision = 'approved'; // approved | rejected | needs_correction | in_review
  late final TextEditingController _commentsController;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _commentsController = TextEditingController();
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final request = ValidationReviewRequest(
      decision: _decision,
      comments: _commentsController.text.trim().isEmpty ? null : _commentsController.text.trim(),
    );

    final success = await widget.onSubmit(request);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to submit validation review decision.';
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
        constraints: const BoxConstraints(maxWidth: 520),
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
                          Text(
                            'Submit Review Decision',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Document: ${widget.documentName ?? widget.documentId}',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const Divider(height: 24),

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

              // Decision Selection
              Text(
                'Review Governance Decision',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              _buildDecisionOption(
                value: 'approved',
                title: 'Approved',
                description: 'All validation criteria met or resolved. Ready for report generation.',
                icon: Icons.check_circle_outline,
                color: AppColors.success,
              ),
              const SizedBox(height: 8),

              _buildDecisionOption(
                value: 'needs_correction',
                title: 'Needs Correction',
                description: 'Critical or math discrepancies require operator adjustment.',
                icon: Icons.edit_note_outlined,
                color: AppColors.warning,
              ),
              const SizedBox(height: 8),

              _buildDecisionOption(
                value: 'in_review',
                title: 'In Review',
                description: 'Pending external SME or subsidiary operational sign-off.',
                icon: Icons.pending_actions_outlined,
                color: AppColors.accentBlue,
              ),
              const SizedBox(height: 8),

              _buildDecisionOption(
                value: 'rejected',
                title: 'Rejected',
                description: 'Unresolvable data integrity failures or incompatible schema.',
                icon: Icons.cancel_outlined,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),

              // Review Comments
              Text(
                'Reviewer Comments & Rationale',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _commentsController,
                maxLines: 3,
                style: AppTypography.bodySmall,
                decoration: InputDecoration(
                  hintText: 'Enter compliance rationale, audit observations, or next steps...',
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
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _getDecisionButtonColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_outlined, size: 18),
                    label: const Text('Submit Decision'),
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

  Color _getDecisionButtonColor() {
    switch (_decision) {
      case 'approved':
        return AppColors.success;
      case 'needs_correction':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      case 'in_review':
      default:
        return AppColors.primary;
    }
  }

  Widget _buildDecisionOption({
    required String value,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _decision == value;

    return InkWell(
      onTap: () => setState(() => _decision = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            Icon(icon, color: isSelected ? color : AppColors.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? color : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
