import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Reusable Standard Card with clean 1px border and 14px radius.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderSide? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.fromBorderSide(
              border ?? const BorderSide(color: AppColors.border, width: 1),
            ),
            boxShadow: const [AppColors.cardShadow],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Dark Hero Metric Card derived from the visual reference.
class HeroMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final double? progress;
  final Widget? trailing;
  final VoidCallback? onTap;

  const HeroMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.progress,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.heroSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: AppTypography.kpiNumberHero,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textInverseMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (progress != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accentTeal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(progress! * 100).toInt()}%',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textInverseMuted,
                    ),
                  ),
                ],
              ),
            ] else if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                subtitle!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textInverseMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standard White KPI Metric Card.
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final double? progress;
  final Color progressColor;
  final IconData? icon;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.progress,
    this.progressColor = AppColors.accentBlue,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: const [AppColors.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: AppTypography.kpiNumber,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: AppTypography.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (progress != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceMuted,
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(progress! * 100).toInt()}%',
                    style: AppTypography.labelSmall,
                  ),
                ],
              ),
            ] else if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                subtitle!,
                style: AppTypography.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
