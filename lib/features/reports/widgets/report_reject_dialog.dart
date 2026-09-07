import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// Modal dialog for rejecting a report with mandatory justification comments.
class ReportRejectDialog extends StatefulWidget {
  final String reportTitle;
  final Future<bool> Function(String reason) onReject;

  const ReportRejectDialog({
    super.key,
    required this.reportTitle,
    required this.onReject,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String reportTitle,
    required Future<bool> Function(String reason) onReject,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ReportRejectDialog(
        reportTitle: reportTitle,
        onReject: onReject,
      ),
    );
  }

  @override
  State<ReportRejectDialog> createState() => _ReportRejectDialogState();
}

class _ReportRejectDialogState extends State<ReportRejectDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final text = _reasonController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Rejection reason is mandatory.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await widget.onReject(text);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to submit report rejection.';
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
        constraints: const BoxConstraints(maxWidth: 480),
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
                              color: AppColors.errorBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Reject Statutory Report',
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
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const Divider(height: 24),
              Text(
                'Report: ${widget.reportTitle}',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warningBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rejecting will return this report to the author. You must provide specific, actionable feedback on what requires correction.',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
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
              const SizedBox(height: 16),
              Text(
                'Rejection Justification *',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonController,
                maxLines: 4,
                style: AppTypography.bodySmall,
                decoration: InputDecoration(
                  hintText: 'e.g. Overburden variance calculation does not reconcile with weighbridge rake logs in Annexure 2...',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.block, size: 16),
                    label: const Text('Reject Report'),
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
