import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/analytics_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/cards/app_card.dart';

/// Coal Dispatch and Transportation Breakdown by Mine and Subsidiary.
class DispatchBreakdownCard extends StatelessWidget {
  final DispatchAnalyticsModel dispatch;

  const DispatchBreakdownCard({super.key, required this.dispatch});

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
                  Icons.local_shipping_outlined,
                  size: 20,
                  color: AppColors.accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dispatch & Evacuation Breakdown', style: AppTypography.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('Coal offtake distribution across transport routes', style: AppTypography.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // By Mine section
          Text(
            'BY MINING DISPATCH HUB',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          if (dispatch.byMine.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No mine dispatch records found.', style: AppTypography.bodySmall),
            )
          else
            ..._buildMineBars(dispatch.byMine),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // By Subsidiary section
          Text(
            'BY SUBSIDIARY EVACUATION',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          if (dispatch.bySubsidiary.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No subsidiary dispatch records found.', style: AppTypography.bodySmall),
            )
          else
            ..._buildSubsidiaryBars(dispatch.bySubsidiary),
        ],
      ),
    );
  }

  List<Widget> _buildMineBars(List<MineDispatchModel> items) {
    double maxVal = 0.0;
    for (final item in items) {
      maxVal = max(maxVal, item.dispatch);
    }
    if (maxVal == 0.0) maxVal = 1.0;

    return items.map((item) {
      final ratio = (item.dispatch / maxVal).clamp(0.0, 1.0);

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
                  '${item.dispatch.toStringAsFixed(1)} T',
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
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildSubsidiaryBars(List<SubsidiaryDispatchModel> items) {
    double maxVal = 0.0;
    for (final item in items) {
      maxVal = max(maxVal, item.dispatch);
    }
    if (maxVal == 0.0) maxVal = 1.0;

    return items.map((item) {
      final ratio = (item.dispatch / maxVal).clamp(0.0, 1.0);

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
                  '${item.dispatch.toStringAsFixed(1)} T',
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
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentIndigo),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
