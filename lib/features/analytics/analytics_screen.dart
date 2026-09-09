import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/analytics_model.dart';
import '../../state/analytics_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/error_state.dart';
import '../../widgets/feedback/loading_indicator.dart';
import 'widgets/analytics_kpi_grid.dart';
import 'widgets/anomalies_card.dart';
import 'widgets/dispatch_breakdown_card.dart';
import 'widgets/production_breakdown_card.dart';
import 'widgets/trends_chart_card.dart';
import 'widgets/trending_items_card.dart';
import 'widgets/variance_analysis_card.dart';

/// Main Mining Analytics & Production Screen for MineIntel AI.
/// Renders comprehensive production & dispatch metrics, time-series trends,
/// target vs actual mathematical variance analysis, and statistical anomalies.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    // Defer initial fetch to avoid modifying provider during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsNotifierProvider.notifier).loadAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsNotifierProvider);

    // Error State (when no prior data exists)
    if (state.isError && (state.overview == null || state.kpis == null)) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        body: ErrorStateWidget(
          title: 'Unable to Load Analytics',
          message: state.errorMessage ?? 'Failed to connect to MineIntel Analytics API.',
          onRetry: () => ref.read(analyticsNotifierProvider.notifier).loadAnalytics(),
        ),
      );
    }

    // Initial or Loading State (when no data exists yet)
    if (state.overview == null || state.kpis == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        body: const AppLoadingIndicator(
          message: 'Loading mining production and dispatch analytics...',
        ),
      );
    }

    // Empty State
    if (state.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        body: EmptyStateWidget(
          icon: Icons.trending_up_outlined,
          title: 'No Analytics Records',
          description:
              'No production records or dispatch logs were found for the selected criteria.',
          actionText: 'Reset Filters',
          onAction: () => ref
              .read(analyticsNotifierProvider.notifier)
              .updateFilter(const AnalyticsFilter()),
        ),
      );
    }

    final overview = state.overview!;
    final kpis = state.kpis!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      body: RefreshIndicator(
        onRefresh: () => ref.read(analyticsNotifierProvider.notifier).refresh(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header with Circular Filter & Refresh Action matching Screen 2
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Analytics',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Mining Analytics & Production',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppButton(
                        text: 'Refresh',
                        icon: Icons.refresh,
                        variant: AppButtonVariant.outline,
                        height: 36,
                        isLoading: state.isLoading,
                        onPressed: () =>
                            ref.read(analyticsNotifierProvider.notifier).refresh(),
                      ),
                      const SizedBox(width: 10),
                      // Circular Filter Button matching Screen 2 mockup
                      InkWell(
                        onTap: () {
                          // Filter toggle
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Color(0xFF111827),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Filter Bar
              _buildFilterBar(state.activeFilter),
              const SizedBox(height: 24),

              // KPI Summary Cards
              AnalyticsKpiGrid(overview: overview, kpis: kpis),
              const SizedBox(height: 24),

              // Historical Production vs Dispatch Trends Chart
              AnalyticsTrendsChartCard(
                trends: state.trends,
                periods: overview.periods,
              ),
              const SizedBox(height: 24),

              // Trending Mining Assets Section (Real Data, No Fake Items)
              TrendingItemsCard(
                production: state.production,
                topMines: overview.topProducingMines,
              ),
              const SizedBox(height: 24),

              // Responsive Categorical Breakdowns
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMultiColumn = constraints.maxWidth >= 900;

                  if (isMultiColumn && state.production != null && state.dispatch != null) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ProductionBreakdownCard(production: state.production!),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: DispatchBreakdownCard(dispatch: state.dispatch!),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      if (state.production != null)
                        ProductionBreakdownCard(production: state.production!),
                      if (state.dispatch != null) ...[
                        const SizedBox(height: 20),
                        DispatchBreakdownCard(dispatch: state.dispatch!),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Target vs Actual Variance Table / Cards
              VarianceAnalysisCard(varianceList: state.variance),
              const SizedBox(height: 24),

              // 3-Sigma Statistical Anomalies & Outliers
              AnalyticsAnomaliesCard(anomalies: state.anomalies),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(AnalyticsFilter filter) {
    const subsidiaries = ['All Subsidiaries', 'ECL', 'BCCL', 'CCL'];
    final currentSub = filter.subsidiary ?? 'All Subsidiaries';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.filter_list, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Filter By Subsidiary:',
                style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          ...subsidiaries.map((sub) {
            final isSelected = currentSub == sub;
            return ChoiceChip(
              label: Text(sub),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(analyticsNotifierProvider.notifier).updateFilter(
                        filter.copyWith(
                          subsidiary: sub == 'All Subsidiaries' ? null : sub,
                          clearSubsidiary: sub == 'All Subsidiaries',
                        ),
                      );
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.textInverse : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
