import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/analytics_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/cards/app_card.dart';

/// Target vs Actual Production Variance Analysis with Comparative Visual Bar Graph & Detailed Audit Table.
class VarianceAnalysisCard extends StatefulWidget {
  final List<VarianceItemModel> varianceList;

  const VarianceAnalysisCard({super.key, required this.varianceList});

  @override
  State<VarianceAnalysisCard> createState() => _VarianceAnalysisCardState();
}

class _VarianceAnalysisCardState extends State<VarianceAnalysisCard> {
  bool _showGraph = true;

  List<VarianceItemModel> get _activeItems {
    // Filter to items that have either target or actual recorded
    final list = widget.varianceList.where((i) => i.target > 0 || i.actual > 0).toList();
    return list.isNotEmpty ? list : widget.varianceList;
  }

  @override
  Widget build(BuildContext context) {
    final items = _activeItems;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 10,
            spacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.compare_arrows_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target vs Actual Variance',
                        style: AppTypography.headlineSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Mathematical deviation from statutory targets & achievement rate',
                        style: AppTypography.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Toggle Button between Graph View & Table View
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildViewToggle('Graph', _showGraph, () {
                          setState(() => _showGraph = true);
                        }),
                        _buildViewToggle('Table', !_showGraph, () {
                          setState(() => _showGraph = false);
                        }),
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
                      '${items.length} Periods',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No variance analysis data found.', style: AppTypography.bodySmall),
              ),
            )
          else ...[
            if (_showGraph) ...[
              // Comparative Visual Bar Chart
              _buildComparativeBarGraph(items),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 16),
            ],

            // Granular Table / Cards View
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 720;
                return isDesktop ? _buildTableView(items) : _buildMobileCardsView(items);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewToggle(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111827) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildComparativeBarGraph(List<VarianceItemModel> items) {
    // Show top 6 active periods in graph to keep layout clean
    final graphItems = items.length > 6 ? items.sublist(items.length - 6) : items;

    double maxVal = 0;
    for (final it in graphItems) {
      maxVal = max(maxVal, max(it.target, it.actual));
    }
    if (maxVal <= 0) maxVal = 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _buildLegendItem('Target Volume', const Color(0xFFCBD5E1)),
            _buildLegendItem('Actual (Surplus / Met)', const Color(0xFF10B981)),
            _buildLegendItem('Actual (Shortfall)', const Color(0xFFEF4444)),
          ],
        ),
        const SizedBox(height: 14),

        // Side-by-Side Dual Bar Rows
        ...graphItems.map((item) {
          final isPos = item.variance >= 0;
          final targetRatio = (item.target / maxVal).clamp(0.02, 1.0);
          final actualRatio = (item.actual / maxVal).clamp(0.02, 1.0);

          final cleanLabel = item.period.isNotEmpty ? item.period : item.mine;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cleanLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'T: ${_formatNumber(item.target)} | A: ${_formatNumber(item.actual)} ${item.unit}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildDeviationBadge(
                          '${isPos ? "+" : ""}${item.variancePct.toStringAsFixed(1)}%',
                          isPos,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Stacked / paired progress bars
                Row(
                  children: [
                    // Target bar
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: targetRatio,
                            child: Container(
                              height: 7,
                              decoration: BoxDecoration(
                                color: const Color(0xFFCBD5E1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Actual bar
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: actualRatio,
                            child: Container(
                              height: 7,
                              decoration: BoxDecoration(
                                color: isPos ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildTableView(List<VarianceItemModel> items) {
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
          DataColumn(label: Text('PERIOD / LEASE')),
          DataColumn(label: Text('PARAMETER')),
          DataColumn(label: Text('TARGET'), numeric: true),
          DataColumn(label: Text('ACTUAL'), numeric: true),
          DataColumn(label: Text('VARIANCE'), numeric: true),
          DataColumn(label: Text('ACHIEVEMENT')),
          DataColumn(label: Text('STATUS')),
        ],
        rows: items.map((item) {
          final isPos = item.variance >= 0;
          final pctSign = item.variancePct > 0 ? '+' : '';

          return DataRow(
            cells: [
              DataCell(Text(
                item.period.isNotEmpty ? item.period : item.mine,
                style: const TextStyle(fontWeight: FontWeight.w600),
              )),
              DataCell(Text(item.parameter)),
              DataCell(Text('${_formatNumber(item.target)} ${item.unit}')),
              DataCell(Text('${_formatNumber(item.actual)} ${item.unit}')),
              DataCell(
                Text(
                  '${item.variance > 0 ? "+" : ""}${_formatNumber(item.variance)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isPos ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
              DataCell(
                _buildDeviationBadge(
                  '$pctSign${item.variancePct.toStringAsFixed(1)}%',
                  isPos,
                ),
              ),
              DataCell(
                _buildStatusChip(item.status, isPos),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileCardsView(List<VarianceItemModel> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
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
                      item.period.isNotEmpty ? item.period : item.mine,
                      style: AppTypography.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildDeviationBadge(
                    '$pctSign${item.variancePct.toStringAsFixed(1)}%',
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
                  _buildStatPill('Target', '${_formatNumber(item.target)} ${item.unit}'),
                  _buildStatPill('Actual', '${_formatNumber(item.actual)} ${item.unit}'),
                  _buildStatPill(
                    'Variance',
                    '${item.variance > 0 ? "+" : ""}${_formatNumber(item.variance)}',
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

  String _formatNumber(double val) {
    if (val.abs() >= 1000) {
      return val.toStringAsFixed(0);
    }
    return val.toStringAsFixed(1);
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
            fontSize: 12,
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

  Widget _buildStatusChip(String status, bool isPositive) {
    final clean = status.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPositive ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        clean,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isPositive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
        ),
      ),
    );
  }
}
