import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../buttons/app_button.dart';

/// Reusable modal dialogs adhering to MineIntel design standards.
class AppDialog {
  AppDialog._();

  /// Show a standard confirmation dialog (returns true if confirmed).
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: AppTypography.headlineSmall),
        content: SingleChildScrollView(
          child: Text(message, style: AppTypography.bodyMedium),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(
                text: cancelText,
                variant: AppButtonVariant.outline,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              AppButton(
                text: confirmText,
                variant: isDestructive ? AppButtonVariant.danger : AppButtonVariant.primary,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Show an information or alert dialog.
  static Future<void> alert(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: AppTypography.headlineSmall),
        content: SingleChildScrollView(
          child: Text(message, style: AppTypography.bodyMedium),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          AppButton(
            text: buttonText,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  /// Show a custom form dialog.
  static Future<T?> showCustomDialog<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    List<Widget>? actions,
    double maxWidth = 540,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
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
                        child: Text(
                          title,
                          style: AppTypography.headlineSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  content,
                  if (actions != null) ...[
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: actions,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
