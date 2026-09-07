import 'package:flutter/material.dart';
import '../../../models/analytics_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/cards/app_card.dart';

/// Target vs Actual Production Variance Analysis Table and Cards.
class VarianceAnalysisCard extends StatelessWidget {
  final List<VarianceItemModel> varianceList;

  const VarianceAnalysisCard({super.key, required this.varianceList});

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
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.compare_arrows_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Target vs Actual Variance', style: AppTypography.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('Mathematical deviation from statutory targets', style: AppTypography.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                  color: AppColors.badgeNeutralBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${varianceList.length} Parameters',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (varianceList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No variance analysis data found.', style: AppTypography.bodySmall),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 720;
                return isDesktop ? _buildTableView() : _buildMobileCardsView();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTableView() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.surfaceMuted),
        headingTextStyle: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
        dataTextStyle: AppTypography.bodySmall,
        columnSpacing: 24,
        horizontalMargin: 16,
        columns: const [
          DataColumn(label: Text('MINE / LOCATION')),
          DataColumn(label: Text('PARAMETER')),
          DataColumn(label: Text('TARGET'), numeric: true),
          DataColumn(label: Text('ACTUAL'), numeric: true),
          DataColumn(label: Text('VARIANCE'), numeric: true),
          DataColumn(label: Text('DEVIATION %')),
        ],
        rows: varianceList.map((item) {
          final isPos = item.variance >= 0;
          final pctSign = item.variancePct > 0 ? '+' : '';

          return DataRow(
            cells: [
              DataCell(Text(item.mine, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(item.parameter)),
              DataCell(Text(item.target.toStringAsFixed(1))),
              DataCell(Text(item.actual.toStringAsFixed(1))),
              DataCell(
                Text(
                  '${item.variance > 0 ? "+" : ""}${item.variance.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isPos ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
              DataCell(
                _buildDeviationBadge(
                  '$pctSign${item.variancePct.toStringAsFixed(2)}%',
                  isPos,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileCardsView() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: varianceList.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = varianceList[index];
        final isPos = item.variance >= 0;
        final pctSign = item.variancePct > 0 ? '+' : '';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.mine,
                      style: AppTypography.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildDeviationBadge(
                    '$pctSign${item.variancePct.toStringAsFixed(2)}%',
                    isPos,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.parameter,
                style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatPill('Target', item.target.toStringAsFixed(1)),
                  _buildStatPill('Actual', item.actual.toStringAsFixed(1)),
                  _buildStatPill(
                    'Variance',
                    '${item.variance > 0 ? "+" : ""}${item.variance.toStringAsFixed(1)}',
                    color: isPos ? AppColors.success : AppColors.error,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatPill(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviationBadge(String text, bool isPositive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPositive ? AppColors.successBg : AppColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPositive ? AppColors.successBorder : AppColors.errorBorder,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isPositive ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}
