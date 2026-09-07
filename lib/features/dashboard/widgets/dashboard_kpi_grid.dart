import 'package:flutter/material.dart';
import '../../../models/dashboard_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/cards/app_card.dart';

/// Responsive KPI Summary Grid for Executive Dashboard.
class DashboardKpiGrid extends StatelessWidget {
  final DashboardOverviewModel overview;
  final DashboardKpisModel kpis;

  const DashboardKpiGrid({
    super.key,
    required this.overview,
    required this.kpis,
  });

  @override
  Widget build(BuildContext context) {
    final docTotal = overview.stats.totalDocuments > 0
        ? overview.stats.totalDocuments
        : kpis.documentCount;
    final validated = overview.stats.validatedDocuments;
    final docProgress = docTotal > 0 ? (validated / docTotal).clamp(0.0, 1.0) : 0.0;

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
            // Hero Card: Total Ingested Documents
            HeroMetricCard(
              title: 'Total Documents',
              value: '$docTotal',
              subtitle: '$validated verified & validated',
              progress: docProgress > 0 ? docProgress : null,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Live Ingestion',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            // Extraction Accuracy KPI
            MetricCard(
              title: 'Extraction Accuracy',
              value: '${kpis.extractionAccuracy.toStringAsFixed(1)}%',
              progress: (kpis.extractionAccuracy / 100).clamp(0.0, 1.0),
              progressColor: AppColors.accentTeal,
              icon: Icons.table_chart_outlined,
            ),

            // Average Quality Score KPI
            MetricCard(
              title: 'Average Quality Score',
              value: '${overview.stats.avgQualityScore.toStringAsFixed(1)}%',
              progress: (overview.stats.avgQualityScore / 100).clamp(0.0, 1.0),
              progressColor: AppColors.accentBlue,
              icon: Icons.verified_outlined,
            ),

            // Compliance Rate & Pending Reviews KPI
            MetricCard(
              title: 'Compliance Rate',
              value: '${kpis.complianceRate.toStringAsFixed(1)}%',
              subtitle: '${overview.stats.pendingReviews} pending governance reviews',
              progress: (kpis.complianceRate / 100).clamp(0.0, 1.0),
              progressColor: AppColors.accentGreen,
              icon: Icons.fact_check_outlined,
            ),
          ],
        );
      },
    );
  }
}
