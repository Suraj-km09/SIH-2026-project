import 'package:flutter/material.dart';
import '../../../models/analytics_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/badges/status_chip.dart';
import '../../../widgets/cards/app_card.dart';

/// Machine-learning Statistical Anomaly & Outlier Detection Card.
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
                          Text('Statistical Anomalies & Outliers', style: AppTypography.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('3-sigma deviations and operational ratio alerts', style: AppTypography.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                color: AppColors.surfaceMuted,
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
                  child: Row(
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
                            Text(
                              'Location: ${item.mine}',
                              style: AppTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
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
                );
              },
            ),
        ],
      ),
    );
  }
}
