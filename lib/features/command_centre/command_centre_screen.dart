import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/command_centre_model.dart';
import '../../state/command_centre_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/error_state.dart';
import '../../widgets/feedback/loading_indicator.dart';
import '../../widgets/layout/responsive_layout.dart';

/// Production-grade Command Centre Screen.
/// Telemetry monitor for ingestion pipelines, microservices health,
/// attention queues, and real-time audit activity feed.
class CommandCentreScreen extends ConsumerStatefulWidget {
  const CommandCentreScreen({super.key});

  @override
  ConsumerState<CommandCentreScreen> createState() =>
      _CommandCentreScreenState();
}

class _CommandCentreScreenState extends ConsumerState<CommandCentreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commandCentreNotifierProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commandCentreNotifierProvider);
    final theme = Theme.of(context);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(
          child: AppLoadingIndicator(
            message: 'Connecting to Command Centre telemetry streams...',
          ),
        ),
      );
    }

    if (state.errorMessage != null && state.overview == null) {
      return Scaffold(
        body: ErrorStateWidget(
          title: 'Command Centre Offline',
          message: state.errorMessage!,
          onRetry: () =>
              ref.read(commandCentreNotifierProvider.notifier).loadAll(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(commandCentreNotifierProvider.notifier)
            .loadAll(isSilent: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: ResponsiveBuilder(
            builder: (context, isMobile, isTablet, isDesktop) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, state, isMobile),
                  const SizedBox(height: 14),
                  _buildKpiGrid(state.overview, isMobile, isDesktop),
                  const SizedBox(height: 14),
                  _buildSystemMetricsStrip(state.overview?.systemMetrics, isMobile),
                  const SizedBox(height: 16),
                  _buildPipelineTelemetryCard(state.pipeline, isMobile),
                  const SizedBox(height: 16),
                  _buildServicesMatrix(state.systemStatus, isMobile, isDesktop),
                  const SizedBox(height: 16),
                  _buildAttentionQueue(state, isMobile),
                  const SizedBox(height: 16),
                  _buildActivityFeed(state.activities),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. HEADER BAR
  // ---------------------------------------------------------------------------
  Widget _buildHeader(
      BuildContext context, CommandCentreState state, bool isMobile) {
    final status = state.systemStatus?.overallStatus ?? 'OPERATIONAL';
    final isOperational = status.toUpperCase() == 'OPERATIONAL';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.accentTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.terminal,
              color: AppColors.accentTeal,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Operations Command Centre',
                        style: AppTypography.headlineMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 15 : 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOperational
                            ? AppColors.successBg
                            : AppColors.errorBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOperational
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isOperational
                                  ? AppColors.success
                                  : AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            status,
                            style: AppTypography.labelSmall.copyWith(
                              color: isOperational
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isMobile
                      ? 'Live pipeline telemetry & system monitoring'
                      : 'Live ingestion telemetry, asynchronous processing status, and attention queues',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: state.isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, size: 20),
            tooltip: 'Sync Command Centre',
            visualDensity: VisualDensity.compact,
            onPressed: state.isRefreshing
                ? null
                : () => ref
                    .read(commandCentreNotifierProvider.notifier)
                    .loadAll(isSilent: true),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. KPI METRICS GRID
  // ---------------------------------------------------------------------------
  Widget _buildKpiGrid(
      CommandCentreOverviewModel? overview, bool isMobile, bool isDesktop) {
    if (overview == null) return const SizedBox.shrink();

    final stats = [
      _KpiData(
        title: overview.docsProcessed.label,
        value: overview.docsProcessed.display,
        subtitle: 'Ingested & cataloged files',
        icon: Icons.description_outlined,
        color: AppColors.accentTeal,
      ),
      _KpiData(
        title: overview.validationScore.label,
        value: overview.validationScore.display,
        subtitle: 'Rule conformance rate',
        icon: Icons.verified_outlined,
        color: AppColors.accentGreen,
      ),
      _KpiData(
        title: overview.openIssues.label,
        value: overview.openIssues.display,
        subtitle: 'Pending human-in-the-loop review',
        icon: Icons.error_outline,
        color: AppColors.warning,
      ),
      _KpiData(
        title: overview.reportsGenerated.label,
        value: overview.reportsGenerated.display,
        subtitle: 'AI statutory filings synthesized',
        icon: Icons.assessment_outlined,
        color: AppColors.accentBlue,
      ),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.45,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: stats.map(_buildKpiCard).toList(),
      );
    }

    return Row(
      children: stats
          .map((item) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _buildKpiCard(item),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildKpiCard(_KpiData item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(item.icon, size: 14, color: item.color),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.value,
              style: AppTypography.headlineLarge.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.subtitle,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. SECONDARY SYSTEM METRICS STRIP
  // ---------------------------------------------------------------------------
  Widget _buildSystemMetricsStrip(
      CommandCentreSystemMetrics? metrics, bool isMobile) {
    if (metrics == null) return const SizedBox.shrink();

    final items = [
      _MetricPair('Total Ingested', '${metrics.totalDocuments} files', Icons.folder_open),
      _MetricPair('Extracted Records', '${metrics.totalExtractedRecords}', Icons.data_usage),
      _MetricPair('Active Specialists', '${metrics.activeUsers}', Icons.people_outline),
      _MetricPair('Memory Footprint', '${metrics.memoryUsageMb} MB', Icons.memory),
      _MetricPair('System Uptime', '${(metrics.uptimeSeconds / 60).toStringAsFixed(0)} min', Icons.timer_outlined),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items.map((pair) {
            return Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Row(
                children: [
                  Icon(pair.icon, size: 14, color: AppColors.accentTeal),
                  const SizedBox(width: 6),
                  Text(
                    '${pair.label}: ',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    pair.value,
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. PIPELINE TELEMETRY CARD
  // ---------------------------------------------------------------------------
  Widget _buildPipelineTelemetryCard(
      CommandCentrePipelineModel? pipeline, bool isMobile) {
    if (pipeline == null) return const SizedBox.shrink();

    final stages = [
      _StageInfo('1. Upload', pipeline.upload.count, pipeline.upload.status,
          Icons.cloud_upload_outlined, AppColors.accentTeal),
      _StageInfo('2. Extraction', pipeline.extraction.count,
          pipeline.extraction.status, Icons.document_scanner_outlined, AppColors.accentBlue),
      _StageInfo('3. Validation', pipeline.validation.count,
          pipeline.validation.status, Icons.rule_outlined, AppColors.warning),
      _StageInfo('4. Vector Index', pipeline.indexing.count,
          pipeline.indexing.status, Icons.hub_outlined, AppColors.accentIndigo),
      _StageInfo('5. Completed', pipeline.completed.count,
          pipeline.completed.status, Icons.check_circle_outline, AppColors.accentGreen),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.sync_alt,
                          size: 18, color: AppColors.accentTeal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Document Ingestion & Telemetry Pipeline',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${pipeline.healthSummary.pipelineSuccessRate}% Success Rate',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Pipeline Stage Cards
            if (isMobile)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: stages
                      .map((s) => Container(
                            width: 130,
                            margin: const EdgeInsets.only(right: 8),
                            child: _buildStageBox(s),
                          ))
                      .toList(),
                ),
              )
            else
              Row(
                children: stages
                    .map((s) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _buildStageBox(s),
                          ),
                        ))
                    .toList(),
              ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Total in Active Pipeline: ${pipeline.healthSummary.totalInPipeline} documents • Active Telemetry Workers: ${pipeline.healthSummary.activeWorkers} • Failed: ${pipeline.healthSummary.failedExtractions}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageBox(_StageInfo stage) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: stage.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: stage.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(stage.icon, size: 16, color: stage.color),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: stage.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${stage.count}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: stage.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            stage.title,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            stage.status.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: stage.color,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. MICROSERVICES STATUS MATRIX
  // ---------------------------------------------------------------------------
  Widget _buildServicesMatrix(
      CommandCentreStatusModel? status, bool isMobile, bool isDesktop) {
    if (status == null) return const SizedBox.shrink();

    final services = [
      _ServiceDisplay(
        name: status.database.name,
        subtitle: 'Primary Document & Metadata Store',
        status: status.database.status,
        meta: status.database.latencyMs != null
            ? '${status.database.latencyMs} ms latency'
            : 'Operational',
        icon: Icons.storage,
        color: AppColors.accentTeal,
      ),
      _ServiceDisplay(
        name: status.ragEngine.name,
        subtitle: 'Vector Embeddings & Semantic Index',
        status: status.ragEngine.status,
        meta: '${status.ragEngine.totalIndexedChunks ?? 0} indexed chunks',
        icon: Icons.hub,
        color: AppColors.accentIndigo,
      ),
      _ServiceDisplay(
        name: status.llmEngine.name,
        subtitle: 'Synthesizer & Extraction LLM',
        status: status.llmEngine.status,
        meta: status.llmEngine.model ?? 'gemini-1.5-flash',
        icon: Icons.psychology,
        color: AppColors.accentBlue,
      ),
      _ServiceDisplay(
        name: status.agentOrchestrator.name,
        subtitle: 'Autonomous Worker Swarm',
        status: status.agentOrchestrator.status,
        meta:
            '${status.agentOrchestrator.supportedAgents.length} Agents active',
        icon: Icons.smart_toy_outlined,
        color: AppColors.accentGreen,
      ),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_done_outlined,
                          size: 18, color: AppColors.accentBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Microservices & Intelligence Status Matrix',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${status.platform} • Node ${status.nodeVersion}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (isMobile)
              Column(
                children: services.map(_buildServiceRow).toList(),
              )
            else
              Row(
                children: services
                    .map((s) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _buildServiceBox(s),
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceRow(_ServiceDisplay s) {
    final isOnline = s.status.toLowerCase() == 'connected' ||
        s.status.toLowerCase() == 'ready' ||
        s.status.toLowerCase() == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(s.icon, size: 18, color: s.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name,
                    style: AppTypography.bodySmall
                        .copyWith(fontWeight: FontWeight.bold)),
                Text(s.meta,
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textSecondary, fontSize: 10.5)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isOnline ? AppColors.successBg : AppColors.errorBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              s.status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isOnline ? AppColors.success : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceBox(_ServiceDisplay s) {
    final isOnline = s.status.toLowerCase() == 'connected' ||
        s.status.toLowerCase() == 'ready' ||
        s.status.toLowerCase() == 'active';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(s.icon, size: 18, color: s.color),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.successBg : AppColors.errorBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isOnline ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(s.name,
              style: AppTypography.bodySmall
                  .copyWith(fontWeight: FontWeight.bold, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(s.meta,
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textSecondary, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. URGENT ATTENTION ITEMS QUEUE
  // ---------------------------------------------------------------------------
  Widget _buildAttentionQueue(CommandCentreState state, bool isMobile) {
    final items = state.filteredAttentionItems;
    final filters = [
      'ALL',
      'HIGH',
      'DOCUMENT_PROCESSING',
      'REPORT_APPROVAL',
      'DATA_VALIDATION',
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_outlined,
                          size: 18, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Action & Attention Queue',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${state.attention?.totalItems ?? 0} Pending',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((f) {
                  final isSelected = state.attentionFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(f.replaceAll('_', ' ')),
                      selected: isSelected,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => ref
                          .read(commandCentreNotifierProvider.notifier)
                          .setAttentionFilter(f),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: EmptyStateWidget(
                  title: 'No Pending Attention Items',
                  description: 'All document pipelines and reports are cleared.',
                  icon: Icons.check_circle_outline,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isHigh = item.priority.toLowerCase() == 'high';

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isHigh
                            ? AppColors.error.withValues(alpha: 0.3)
                            : AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isHigh
                                    ? AppColors.errorBg
                                    : AppColors.warningBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.priority.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: isHigh
                                      ? AppColors.error
                                      : AppColors.warning,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.category.replaceAll('_', ' '),
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textTertiary,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.title,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.touch_app_outlined,
                                size: 12, color: AppColors.accentTeal),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Action: ${item.actionRequired}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.accentTeal,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. REAL-TIME ACTIVITY FEED
  // ---------------------------------------------------------------------------
  Widget _buildActivityFeed(List<CommandCentreActivityModel> activities) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline,
                    size: 18, color: AppColors.accentIndigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Real-Time Ingestion & Audit Activity Stream',
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (activities.isEmpty)
              const EmptyStateWidget(
                title: 'No Recent Activities',
                description: 'Pipeline events will stream here live.',
                icon: Icons.history,
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.take(5).length,
                separatorBuilder: (_, _) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final act = activities[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accentIndigo.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bolt,
                          size: 14,
                          color: AppColors.accentIndigo,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              act.description.isNotEmpty
                                  ? act.description
                                  : act.action.replaceAll('_', ' '),
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'By ${act.actor} • ${act.source}',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HELPER DATA CLASSES
// ---------------------------------------------------------------------------
class _KpiData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _MetricPair {
  final String label;
  final String value;
  final IconData icon;

  const _MetricPair(this.label, this.value, this.icon);
}

class _StageInfo {
  final String title;
  final int count;
  final String status;
  final IconData icon;
  final Color color;

  const _StageInfo(this.title, this.count, this.status, this.icon, this.color);
}

class _ServiceDisplay {
  final String name;
  final String subtitle;
  final String status;
  final String meta;
  final IconData icon;
  final Color color;

  const _ServiceDisplay({
    required this.name,
    required this.subtitle,
    required this.status,
    required this.meta,
    required this.icon,
    required this.color,
  });
}
