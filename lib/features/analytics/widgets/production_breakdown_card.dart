import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/analytics_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/cards/app_card.dart';

/// Production Breakdown by Mine and Subsidiary.
class ProductionBreakdownCard extends StatelessWidget {
  final ProductionAnalyticsModel production;

  const ProductionBreakdownCard({super.key, required this.production});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.precision_manufacturing_outlined,
                  size: 20,
                  color: AppColors.accentTeal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Production by Mine & Subsidiary', style: AppTypography.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('Distribution of declared extraction volumes', style: AppTypography.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // By Mine section
          Text(
            'BY MINING LEASE / AREA',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          if (production.byMine.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No mine production records found.', style: AppTypography.bodySmall),
            )
          else
            ..._buildMineBars(production.byMine),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // By Subsidiary section
          Text(
            'BY SUBSIDIARY DIVISION',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          if (production.bySubsidiary.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No subsidiary production records found.', style: AppTypography.bodySmall),
            )
          else
            ..._buildSubsidiaryBars(production.bySubsidiary),
        ],
      ),
    );
  }

  List<Widget> _buildMineBars(List<MineProductionModel> items) {
    double maxVal = 0.0;
    for (final item in items) {
      maxVal = max(maxVal, item.production);
    }
    if (maxVal == 0.0) maxVal = 1.0;

    return items.map((item) {
      final ratio = (item.production / maxVal).clamp(0.0, 1.0);

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.mine, style: AppTypography.labelLarge),
                Text(
                  '${item.production.toStringAsFixed(1)} T',
                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: AppColors.surfaceMuted,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildSubsidiaryBars(List<SubsidiaryProductionModel> items) {
    double maxVal = 0.0;
    for (final item in items) {
      maxVal = max(maxVal, item.production);
    }
    if (maxVal == 0.0) maxVal = 1.0;

    return items.map((item) {
      final ratio = (item.production / maxVal).clamp(0.0, 1.0);

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.subsidiary, style: AppTypography.labelLarge),
                Text(
                  '${item.production.toStringAsFixed(1)} T',
                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: AppColors.surfaceMuted,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.heroSurfaceLight),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
