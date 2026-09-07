import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, outline, danger, text }

/// Reusable enterprise button adhering to MineIntel AI design system.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 44,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = isEnabled ? AppColors.primary : AppColors.surfaceMuted;
        fg = isEnabled ? AppColors.textInverse : AppColors.textTertiary;
        break;
      case AppButtonVariant.secondary:
        bg = isEnabled ? AppColors.surfaceMuted : AppColors.surfaceHover;
        fg = isEnabled ? AppColors.textPrimary : AppColors.textTertiary;
        break;
      case AppButtonVariant.outline:
        bg = Colors.transparent;
        fg = isEnabled ? AppColors.textPrimary : AppColors.textTertiary;
        border = BorderSide(
          color: isEnabled ? AppColors.border : AppColors.borderSubtle,
          width: 1,
        );
        break;
      case AppButtonVariant.danger:
        bg = isEnabled ? AppColors.error : AppColors.errorBg;
        fg = isEnabled ? AppColors.textInverse : AppColors.textTertiary;
        break;
      case AppButtonVariant.text:
        bg = Colors.transparent;
        fg = isEnabled ? AppColors.textPrimary : AppColors.textTertiary;
        break;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            text,
            style: AppTypography.labelLarge.copyWith(color: fg),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: border != BorderSide.none ? Border.fromBorderSide(border) : null,
            ),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );
  }
}
