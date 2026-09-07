import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Reusable status pill badge with refined soft background and status dot.
class StatusChip extends StatelessWidget {
  final String status;
  final double? fontSize;

  const StatusChip({
    super.key,
    required this.status,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final config = _resolveBadgeConfig(status.toLowerCase());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config.textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _formatStatusText(status),
            style: AppTypography.labelSmall.copyWith(
              color: config.textColor,
              fontWeight: FontWeight.w600,
              fontSize: fontSize ?? 11,
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatusText(String raw) {
    if (raw.isEmpty) return '';
    return raw
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  _ChipConfig _resolveBadgeConfig(String s) {
    switch (s) {
      case 'completed':
      case 'approved':
      case 'resolved':
      case 'success':
      case 'active':
        return _ChipConfig(
          backgroundColor: AppColors.successBg,
          borderColor: AppColors.successBorder,
          textColor: AppColors.success,
        );

      case 'processing':
      case 'queued':
      case 'review':
      case 'in review':
      case 'warning':
      case 'suspicious_value':
        return _ChipConfig(
          backgroundColor: AppColors.warningBg,
          borderColor: AppColors.warningBorder,
          textColor: AppColors.warning,
        );

      case 'failed':
      case 'rejected':
      case 'error':
      case 'critical':
      case 'conflict':
        return _ChipConfig(
          backgroundColor: AppColors.errorBg,
          borderColor: AppColors.errorBorder,
          textColor: AppColors.error,
        );

      case 'draft':
      case 'pending':
      case 'open':
      case 'info':
      case 'unit_mismatch':
      default:
        return _ChipConfig(
          backgroundColor: AppColors.badgeNeutralBg,
          borderColor: AppColors.border,
          textColor: AppColors.badgeNeutralText,
        );
    }
  }
}

/// Validation Severity Chip (Critical, Error, Warning, Info)
class SeverityChip extends StatelessWidget {
  final String severity;

  const SeverityChip({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    final s = severity.toLowerCase();
    Color bg;
    Color border;
    Color fg;

    switch (s) {
      case 'critical':
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFCA5A5);
        fg = const Color(0xFFB91C1C);
        break;
      case 'error':
        bg = AppColors.errorBg;
        border = AppColors.errorBorder;
        fg = AppColors.error;
        break;
      case 'warning':
        bg = AppColors.warningBg;
        border = AppColors.warningBorder;
        fg = AppColors.warning;
        break;
      case 'info':
      default:
        bg = AppColors.infoBg;
        border = AppColors.infoBorder;
        fg = AppColors.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        severity.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

/// Category / Metadata Tag Chip
class CategoryChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isSelected;

  const CategoryChip({
    super.key,
    required this.label,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? AppColors.textInverse : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ChipConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  _ChipConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}
