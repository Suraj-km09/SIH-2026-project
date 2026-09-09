import 'package:flutter/material.dart';
import '../../../models/dashboard_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/cards/app_card.dart';

/// Processing & Validation Quality Highlights card for Dashboard.
class DashboardQualityHighlightCard extends StatelessWidget {
  final DashboardStatsModel stats;
  final DashboardKpisModel kpis;

  const DashboardQualityHighlightCard({
    super.key,
    required this.stats,
    required this.kpis,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedBg = isDark ? const Color(0xFF374151) : AppColors.surfaceMuted;
    final qualityScore = stats.avgQualityScore;
    final processedPct = kpis.documentCount > 0
        ? (kpis.processedCount / kpis.documentCount * 100).clamp(0.0, 100.0)
        : 100.0;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
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
                        color: mutedBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.analytics_outlined,
                        size: 20,
                        color: AppColors.accentBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Validation & Processing Highlights',
                        style: AppTypography.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.badgeNeutralBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Score: ${qualityScore.toStringAsFixed(1)}',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Highlight breakdown metrics
          Row(
            children: [
              // Ingestion Throughput Gauge
              Expanded(
                child: _buildMetricItem(
                  context,
                  label: 'Pipeline Processed',
                  value: '${kpis.processedCount} / ${kpis.documentCount}',
                  percentage: processedPct,
                  barColor: AppColors.accentTeal,
                ),
              ),
              const SizedBox(width: 16),
              // Validated Documents Gauge
              Expanded(
                child: _buildMetricItem(
                  context,
                  label: 'Rule Validated',
                  value: '${stats.validatedDocuments} / ${stats.totalDocuments}',
                  percentage: stats.totalDocuments > 0
                      ? (stats.validatedDocuments / stats.totalDocuments * 100).clamp(0.0, 100.0)
                      : 0.0,
                  barColor: AppColors.accentGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Attention indicators footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: mutedBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.rate_review_outlined, size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${stats.pendingReviews} Maker-Checker Queue',
                          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        kpis.errorCount > 0 ? Icons.error_outline : Icons.check_circle_outline,
                        size: 16,
                        color: kpis.errorCount > 0 ? AppColors.error : AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${kpis.errorCount} Ingestion Failures',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                            color: kpis.errorCount > 0 ? AppColors.error : AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required String label,
    required String value,
    required double percentage,
    required Color barColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final metricBg = isDark ? theme.colorScheme.surface : AppColors.background;
    final metricBorder = isDark ? const Color(0xFF374151) : AppColors.borderSubtle;
    final progressTrack = isDark ? const Color(0xFF374151) : AppColors.surfaceMuted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: metricBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: metricBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: progressTrack,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
