import 'package:flutter/material.dart';
import '../../../models/analytics_model.dart';

/// Responsive KPI Summary Grid for Mining Analytics.
/// Styled to match Screen 2 of the uploaded mockup:
/// - Top 2 cards: 35K Total Production & 2,153 Total Dispatch (with mini pill icon)
/// - Bottom 2 cards: Net Inventory Gap & Verified Extraction Records
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
    // Format values matching operational scale from live API
    final prodDisplay = _formatMetric(overview.totalProduction);
    final dispatchDisplay = _formatDispatch(overview.totalDispatch);
    final gapDisplay = overview.netGap == 0.0
        ? '0 MT'
        : '${overview.netGap > 0 ? '+' : ''}${_formatMetric(overview.netGap)}';

    final String verifiedDisplay;
    if (kpis.verifiedRecords > 0 && kpis.totalRecords > 0) {
      verifiedDisplay = '${kpis.verifiedRecords} / ${kpis.totalRecords}';
    } else if (kpis.totalRecords > 0) {
      verifiedDisplay = '${kpis.totalRecords} Records';
    } else {
      verifiedDisplay = '0 Records';
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        final isTablet = constraints.maxWidth >= 640 && constraints.maxWidth < 1024;
        final crossAxisCount = isDesktop ? 4 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: isDesktop ? 1.4 : (isTablet ? 1.45 : 1.3),
          children: [
            // Card 1: Total Production
            _AnalyticsKpiCard(
              icon: Icons.bar_chart_rounded,
              value: prodDisplay,
              title: 'Total Production',
            ),

            // Card 2: Total Dispatch
            _AnalyticsKpiCard(
              icon: Icons.show_chart_rounded,
              value: dispatchDisplay,
              title: 'Total Dispatch',
            ),

            // Card 3: Net Inventory Gap
            _AnalyticsKpiCard(
              icon: Icons.swap_vert_rounded,
              value: gapDisplay,
              title: 'Net Inventory Gap',
            ),

            // Card 4: Verified Extraction Records
            _AnalyticsKpiCard(
              icon: Icons.verified_user_rounded,
              value: verifiedDisplay,
              title: 'Verified Extraction Records',
            ),
          ],
        );
      },
    );
  }

  String _formatMetric(double val) {
    if (val.abs() >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val.abs() >= 1000) {
      final k = val / 1000;
      return k >= 100 ? '${k.toStringAsFixed(0)}K' : '${k.toStringAsFixed(1)}K';
    }
    return val.toStringAsFixed(1);
  }

  String _formatDispatch(double val) {
    if (val.abs() >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    }
    if (val >= 1000) {
      final parts = val.toStringAsFixed(0);
      if (parts.length > 3) {
        return '${parts.substring(0, parts.length - 3)},${parts.substring(parts.length - 3)}';
      }
    }
    return val.toStringAsFixed(1);
  }
}

class _AnalyticsKpiCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String title;

  const _AnalyticsKpiCard({
    required this.icon,
    required this.value,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Icon Pill
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF374151),
            ),
          ),

          // Big Metric and Subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
