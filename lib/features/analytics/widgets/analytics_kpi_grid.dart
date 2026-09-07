import 'package:flutter/material.dart';
import '../../../models/analytics_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/cards/app_card.dart';

/// Responsive KPI Summary Grid for Mining Analytics.
class AnalyticsKpiGrid extends StatelessWidget {
  final AnalyticsOverviewModel overview;
  final AnalyticsKpisModel kpis;

  const AnalyticsKpiGrid({
    super.key,
    required this.overview,
    required this.kpis,
  });

  @override
  Widget build(BuildContext context) {
    final achievement = overview.productionTargetAchievement > 0
        ? overview.productionTargetAchievement
        : kpis.targetAchievementPct;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
        final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 1);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isDesktop ? 1.4 : (isTablet ? 1.35 : (constraints.maxWidth < 360 ? 1.6 : 1.85)),
          children: [
            // Hero Card: Total Raw Coal Production
            HeroMetricCard(
              title: 'Total Production',
              value: '${_formatNumber(overview.totalProduction)} T',
              subtitle: 'Target Achievement: ${achievement.toStringAsFixed(1)}%',
              progress: (achievement / 100).clamp(0.0, 1.0),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Active Month',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Total Coal Dispatch
            MetricCard(
              title: 'Total Dispatch',
              value: '${_formatNumber(overview.totalDispatch)} T',
              subtitle: 'Evacuated via Rail, Road & MGR',
              progress: overview.totalProduction > 0
                  ? (overview.totalDispatch / overview.totalProduction).clamp(0.0, 1.0)
                  : null,
              progressColor: AppColors.accentBlue,
              icon: Icons.local_shipping_outlined,
            ),

            // Production - Dispatch Net Gap
            MetricCard(
              title: 'Net Inventory Gap',
              value: '${_formatNumber(overview.netGap)} T',
              subtitle: overview.netGap >= 0
                  ? 'Stockyard buffer available'
                  : 'Dispatch exceeds current production',
              icon: Icons.swap_vert_outlined,
            ),

            // Verification & Record Extraction Quality
            MetricCard(
              title: 'Verified Extraction Records',
              value: '${kpis.verifiedRecords} / ${kpis.totalRecords}',
              subtitle: 'Avg Confidence: ${(kpis.averageConfidence * 100).toStringAsFixed(1)}%',
              progress: kpis.totalRecords > 0
                  ? (kpis.verifiedRecords / kpis.totalRecords).clamp(0.0, 1.0)
                  : null,
              progressColor: AppColors.accentTeal,
              icon: Icons.verified_user_outlined,
            ),
          ],
        );
      },
    );
  }

  String _formatNumber(double val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(2)}M';
    } else if (val >= 1000) {
      return val.toStringAsFixed(1);
    }
    return val.toStringAsFixed(1);
  }
}
