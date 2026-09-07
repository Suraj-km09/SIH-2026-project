import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/dashboard_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/error_state.dart';
import '../../widgets/feedback/loading_indicator.dart';
import 'widgets/alerts_card.dart';
import 'widgets/dashboard_kpi_grid.dart';
import 'widgets/quality_highlight_card.dart';
import 'widgets/recent_activity_card.dart';
import 'widgets/recent_documents_card.dart';
import '../documents/document_detail_screen.dart';

/// Main Executive Dashboard Screen for MineIntel AI.
/// Summarizes operational KPIs, real-time alerts, document ingestion status,
/// validation scoring, and chronological audit activities.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Defer initial fetch to avoid modifying provider during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardNotifierProvider.notifier).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardNotifierProvider);

    // Error State (when no prior data exists)
    if (state.isError && (state.overview == null || state.kpis == null)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorStateWidget(
          title: 'Unable to Load Dashboard',
          message: state.errorMessage ?? 'Failed to connect to MineIntel API.',
          onRetry: () => ref.read(dashboardNotifierProvider.notifier).loadDashboard(),
        ),
      );
    }

    // Initial or Loading State (when no data exists yet)
    if (state.overview == null || state.kpis == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: AppLoadingIndicator(
          message: 'Loading executive mining intelligence dashboard...',
        ),
      );
    }

    // Empty State
    if (state.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: EmptyStateWidget(
          icon: Icons.dashboard_outlined,
          title: 'No Operational Data',
          description:
              'No mining documents, telemetry, or activity feeds have been recorded yet.',
          actionText: 'Refresh Dashboard',
          onAction: () => ref.read(dashboardNotifierProvider.notifier).loadDashboard(),
        ),
      );
    }

    final overview = state.overview!;
    final kpis = state.kpis!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardNotifierProvider.notifier).refresh(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard Title & Refresh Action Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Executive Dashboard', style: AppTypography.headlineLarge),
                        const SizedBox(height: 4),
                        Text(
                          'Aggregated operational throughput, validation scoring, and real-time audit feed.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  AppButton(
                    text: 'Refresh',
                    icon: Icons.refresh,
                    variant: AppButtonVariant.outline,
                    height: 36,
                    isLoading: state.isLoading,
                    onPressed: () =>
                        ref.read(dashboardNotifierProvider.notifier).refresh(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Responsive KPI Cards Grid
              DashboardKpiGrid(overview: overview, kpis: kpis),
              const SizedBox(height: 24),

              // Responsive Multi-Section Layout
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMultiColumn = constraints.maxWidth >= 900;

                  if (isMultiColumn) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Alerts & Quality Highlights
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              DashboardAlertsCard(alerts: overview.alerts),
                              const SizedBox(height: 20),
                              DashboardQualityHighlightCard(
                                stats: overview.stats,
                                kpis: kpis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Right Column: Documents & Activity Feed
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              DashboardRecentDocumentsCard(
                                documents: overview.recentDocuments,
                                onDocumentTap: (id) => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DocumentDetailScreen(documentId: id),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              DashboardRecentActivityCard(
                                activity: overview.recentActivity,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  // Single Column for Mobile
                  return Column(
                    children: [
                      DashboardAlertsCard(alerts: overview.alerts),
                      const SizedBox(height: 20),
                      DashboardQualityHighlightCard(
                        stats: overview.stats,
                        kpis: kpis,
                      ),
                      const SizedBox(height: 20),
                      DashboardRecentDocumentsCard(
                        documents: overview.recentDocuments,
                        onDocumentTap: (id) => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DocumentDetailScreen(documentId: id),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      DashboardRecentActivityCard(
                        activity: overview.recentActivity,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
