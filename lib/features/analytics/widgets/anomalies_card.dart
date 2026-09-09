import 'package:flutter/material.dart';
import '../../../models/analytics_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/badges/status_chip.dart';
import '../../../widgets/cards/app_card.dart';

/// Machine-learning Statistical Anomaly & Outlier Detection Card.
/// Displays 3-sigma deviations, parameter outliers, and operational drop alerts
/// with interactive statistical deviation meters.
class AnalyticsAnomaliesCard extends StatelessWidget {
  final List<AnomalyItemModel> anomalies;

  const AnalyticsAnomaliesCard({super.key, required this.anomalies});

  @override
  Widget build(BuildContext context) {
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
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.troubleshoot_outlined,
                        size: 20,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Statistical Anomalies & Outliers',
                            style: AppTypography.headlineSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '3-sigma deviations and operational ratio alerts from live mining returns',
                            style: AppTypography.labelSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: anomalies.isEmpty ? AppColors.successBg : AppColors.errorBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: anomalies.isEmpty ? AppColors.successBorder : AppColors.errorBorder,
                  ),
                ),
                child: Text(
                  '${anomalies.length} Flagged',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: anomalies.isEmpty ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (anomalies.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined, color: AppColors.success, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No statistical anomalies or 3-sigma outliers detected in the active dataset.',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: anomalies.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = anomalies[index];
                final isCrit = item.isCritical;
                final isWarn = item.isWarning;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isCrit
                        ? AppColors.errorBg
                        : (isWarn ? AppColors.warningBg : AppColors.background),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCrit
                          ? AppColors.errorBorder
                          : (isWarn ? AppColors.warningBorder : AppColors.borderSubtle),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isCrit
                                ? Icons.error_outline
                                : (isWarn ? Icons.warning_amber_rounded : Icons.info_outline),
                            size: 20,
                            color: isCrit
                                ? AppColors.error
                                : (isWarn ? AppColors.warning : AppColors.info),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.type.replaceAll('_', ' '),
                                        style: AppTypography.labelLarge.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    StatusChip(status: item.severity, fontSize: 10),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    if (item.parameter != null)
                                      _buildTag(Icons.tune_rounded, item.parameter!),
                                    if (item.period != null && item.period!.isNotEmpty)
                                      _buildTag(Icons.calendar_today_outlined, item.period!),
                                    if (item.documentName != null)
                                      _buildTag(Icons.description_outlined, item.documentName!),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.details,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Visual Statistical Deviation Gauge (for Z-scores or percentage drops)
                      if (item.zScore != null) ...[
                        const SizedBox(height: 10),
                        _buildZScoreDeviationMeter(item.zScore!),
                      ] else if (item.percentageChange != null) ...[
                        const SizedBox(height: 10),
                        _buildPercentageDropMeter(item.percentageChange!),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZScoreDeviationMeter(double zScore) {
    // Meter spans 0 to 6 sigma; 3 sigma threshold marked
    final ratio = (zScore / 6.0).clamp(0.05, 1.0);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '3-Sigma Boundary (Critical > 3.0σ)',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
              ),
              Text(
                'Z-Score: ${zScore.toStringAsFixed(2)}σ',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              // Base track
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // Threshold indicator at 50% (3.0 / 6.0)
              Positioned(
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    const Spacer(),
                    Container(
                      width: 2,
                      height: 6,
                      color: const Color(0xFFF59E0B),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              // Z-Score fill
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: zScore >= 3.0 ? const Color(0xFFDC2626) : const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageDropMeter(double pctChange) {
    final absDrop = pctChange.abs().clamp(0.0, 100.0);
    final ratio = absDrop / 100.0;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Operational Period Variance',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
              ),
              Text(
                '${pctChange.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
  }
}
