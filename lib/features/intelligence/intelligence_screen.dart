import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/intelligence_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/error_state.dart';
import '../../widgets/feedback/loading_indicator.dart';
import '../../widgets/layout/responsive_layout.dart';

/// Professional Document Intelligence Screen.
/// Covers:
/// 1. Intelligence Overview & Extraction Trigger (/intelligence, /intelligence/analyze)
/// 2. Temporal Topic Trends (/intelligence/trends)
/// 3. Named Entity Catalog (/intelligence/entities, /intelligence/entities/:id)
/// 4. Semantic Intelligence Clusters (/intelligence/clusters)
/// 5. Document Similarity Matrix (/intelligence/similarity, /intelligence/similarity/:id)
/// 6. Cross-Document Parameter Changes (/intelligence/changes)
/// 7. Bidirectional Evidence Linking (/intelligence/link-evidence/:id)
class IntelligenceScreen extends ConsumerStatefulWidget {
  const IntelligenceScreen({super.key});

  @override
  ConsumerState<IntelligenceScreen> createState() => _IntelligenceScreenState();
}

class _IntelligenceScreenState extends ConsumerState<IntelligenceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(intelligenceNotifierProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(intelligenceNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(state),
          _buildTabBar(),
          if (state.actionMessage != null) _buildActionBanner(state),
          Expanded(
            child: _buildTabContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(IntelligenceState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: ResponsiveBuilder(
        builder: (context, isMobile, isTablet, isDesktop) {
          final titleWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_outlined,
                      size: 24, color: AppColors.accentTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Document Intelligence & Cross-Reasoning',
                      style: AppTypography.headlineMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Corpus-wide named entities, semantic clustering, cosine similarity, and parameter diffs',
                style: AppTypography.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );

          final actionsWidget = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Trigger link-evidence
              OutlinedButton.icon(
                onPressed: state.isLinkingEvidence
                    ? null
                    : () => _promptLinkEvidence(context),
                icon: state.isLinkingEvidence
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link, size: 16),
                label: const Text('Link Evidence'),
              ),

              // Run Intelligence Analysis
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentTeal,
                  foregroundColor: Colors.white,
                ),
                onPressed: state.isAnalyzing
                    ? null
                    : () => _runIntelligenceAnalysis(context),
                icon: state.isAnalyzing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 16),
                label: Text(
                  state.isAnalyzing ? 'Analyzing...' : 'Run Analysis',
                ),
              ),

              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh Intelligence',
                onPressed: state.isLoading
                    ? null
                    : () =>
                        ref.read(intelligenceNotifierProvider.notifier).loadAll(),
              ),
            ],
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleWidget,
                const SizedBox(height: 12),
                actionsWidget,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: titleWidget),
              actionsWidget,
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.accentTeal,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.accentTeal,
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Overview'),
          Tab(icon: Icon(Icons.trending_up, size: 18), text: 'Trends'),
          Tab(icon: Icon(Icons.fingerprint, size: 18), text: 'Entities'),
          Tab(icon: Icon(Icons.bubble_chart_outlined, size: 18), text: 'Clusters'),
          Tab(icon: Icon(Icons.compare_arrows, size: 18), text: 'Similarity'),
          Tab(icon: Icon(Icons.difference_outlined, size: 18), text: 'Changes'),
        ],
      ),
    );
  }

  Widget _buildActionBanner(IntelligenceState state) {
    return Container(
      width: double.infinity,
      color: AppColors.successBg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 18, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.actionMessage!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.success),
            onPressed: () =>
                ref.read(intelligenceNotifierProvider.notifier).clearMessages(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(IntelligenceState state) {
    if (state.isLoading && state.overview == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: AppLoadingIndicator(message: 'Synthesizing document intelligence...'),
        ),
      );
    }

    if (state.errorMessage != null && state.overview == null) {
      return ErrorStateWidget(
        title: 'Failed to Load Intelligence',
        message: state.errorMessage!,
        onRetry: () =>
            ref.read(intelligenceNotifierProvider.notifier).loadAll(),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(state),
        _buildTrendsTab(state),
        _buildEntitiesTab(state),
        _buildClustersTab(state),
        _buildSimilarityTab(state),
        _buildChangesTab(state),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 0: OVERVIEW
  // -------------------------------------------------------------
  Widget _buildOverviewTab(IntelligenceState state) {
    final overview = state.overview;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Metric Cards
          ResponsiveBuilder(
            builder: (context, isMobile, isTablet, isDesktop) {
              final cards = [
                _buildKpiCard(
                  title: 'Discovered Entities',
                  value: '${overview?.totalEntities ?? 0}',
                  subtitle: 'Locations, Mines, Equipment, Figures',
                  icon: Icons.fingerprint,
                  color: AppColors.accentTeal,
                ),
                _buildKpiCard(
                  title: 'Taxonomy Topics',
                  value: '${overview?.totalTopics ?? 0}',
                  subtitle: 'Operational & Compliance themes',
                  icon: Icons.hub_outlined,
                  color: AppColors.accentBlue,
                ),
                _buildKpiCard(
                  title: 'Similarity Clusters',
                  value: '${overview?.similarityClusters ?? 0}',
                  subtitle: 'Semantically clustered document sets',
                  icon: Icons.bubble_chart_outlined,
                  color: AppColors.accentIndigo,
                ),
                _buildKpiCard(
                  title: 'Cross-Doc Changes',
                  value: '${overview?.recentChanges ?? 0}',
                  subtitle: 'Parameter variances identified',
                  icon: Icons.swap_horiz,
                  color: AppColors.warning,
                ),
              ];

              if (isMobile) {
                return Column(
                  children: cards
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: c,
                          ))
                      .toList(),
                );
              }

              return GridView.count(
                crossAxisCount: isTablet ? 2 : 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: isTablet ? 2.2 : 1.8,
                children: cards,
              );
            },
          ),
          const SizedBox(height: 24),

          // Operational Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          size: 20, color: AppColors.accentTeal),
                      const SizedBox(width: 8),
                      Text('Intelligence Synthesis Summary',
                          style: AppTypography.headlineSmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Multi-document intelligence extracts named entities across statutory reports, computes bidirectional citation links between text chunks and verified parameters, and clusters documents by operational topic.',
                    style: AppTypography.bodyMedium,
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _tabController.animateTo(2),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Inspect Named Entities'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _tabController.animateTo(4),
                        icon: const Icon(Icons.compare_arrows, size: 16),
                        label: const Text('Explore Similarity Matrix'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTypography.labelSmall),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.headlineLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: TRENDS
  // -------------------------------------------------------------
  Widget _buildTrendsTab(IntelligenceState state) {
    if (state.trends.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Trends Available',
        description: 'Temporal topic intelligence trends will display here.',
        icon: Icons.trending_up,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: state.trends.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final trend = state.trends[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(trend.name, style: AppTypography.headlineSmall),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.badgeNeutralBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Weight: ${(trend.weight * 100).toStringAsFixed(0)}%',
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Period Frequency Progression:',
                    style: AppTypography.labelSmall),
                const SizedBox(height: 8),
                Row(
                  children: trend.periods.map((p) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${p.count}',
                              style: AppTypography.headlineSmall.copyWith(
                                color: AppColors.accentTeal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(p.period, style: AppTypography.labelSmall),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 2: ENTITIES
  // -------------------------------------------------------------
  Widget _buildEntitiesTab(IntelligenceState state) {
    final types = [
      'ALL',
      'MINE',
      'LOCATION',
      'ORGANIZATION',
      'EQUIPMENT',
      'FIGURE'
    ];
    final entities = state.filteredEntities;

    return Column(
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          color: AppColors.surface,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: types.map((type) {
                final isSelected = state.entityTypeFilter == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        ref
                            .read(intelligenceNotifierProvider.notifier)
                            .setEntityTypeFilter(type);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Entities Grid / Table
        Expanded(
          child: entities.isEmpty
              ? const EmptyStateWidget(
                  title: 'No Entities Matching Filter',
                  description: 'Try switching entity category filters.',
                  icon: Icons.fingerprint,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: entities.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = entities[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _getEntityColor(item.type).withValues(alpha: 0.15),
                          child: Icon(
                            _getEntityIcon(item.type),
                            color: _getEntityColor(item.type),
                            size: 18,
                          ),
                        ),
                        title: Text(item.name,
                            style: AppTypography.bodyMedium
                                .copyWith(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Associated Documents: ${item.documents.join(', ')}',
                          style: AppTypography.labelSmall,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            '${item.count} Mentions',
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Color _getEntityColor(String type) {
    switch (type.toUpperCase()) {
      case 'MINE':
        return AppColors.accentTeal;
      case 'LOCATION':
        return AppColors.accentBlue;
      case 'ORGANIZATION':
        return AppColors.accentIndigo;
      case 'EQUIPMENT':
        return AppColors.warning;
      case 'FIGURE':
        return AppColors.accentGreen;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getEntityIcon(String type) {
    switch (type.toUpperCase()) {
      case 'MINE':
        return Icons.terrain;
      case 'LOCATION':
        return Icons.place;
      case 'ORGANIZATION':
        return Icons.business;
      case 'EQUIPMENT':
        return Icons.precision_manufacturing;
      case 'FIGURE':
        return Icons.numbers;
      default:
        return Icons.tag;
    }
  }

  // -------------------------------------------------------------
  // TAB 3: CLUSTERS
  // -------------------------------------------------------------
  Widget _buildClustersTab(IntelligenceState state) {
    if (state.clusters.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Semantic Clusters',
        description: 'Cross-document topic clusters will appear here.',
        icon: Icons.bubble_chart_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: state.clusters.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final cluster = state.clusters[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(cluster.name,
                          style: AppTypography.headlineSmall),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentTeal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${cluster.documentsCount} Docs Linked',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.accentTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Cluster Keywords:', style: AppTypography.labelSmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: cluster.keywords.map((kw) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Text(kw, style: AppTypography.labelSmall),
                    );
                  }).toList(),
                ),
                if (cluster.relatedTopics.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text('Related Topics & Correlation Strength:',
                      style: AppTypography.labelSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: cluster.relatedTopics.map((rel) {
                      return Chip(
                        label: Text(
                          '${rel.name} (${(rel.strength * 100).toStringAsFixed(0)}%)',
                          style: AppTypography.labelSmall,
                        ),
                        backgroundColor: AppColors.background,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 4: SIMILARITY
  // -------------------------------------------------------------
  Widget _buildSimilarityTab(IntelligenceState state) {
    final simResult = state.similarity;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.document_scanner_outlined,
                      size: 20, color: AppColors.accentBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Target Document for Cosine Similarity Matrix',
                            style: AppTypography.labelSmall),
                        Text(
                          simResult?.targetDocument.isNotEmpty == true
                              ? simResult!.targetDocument
                              : 'doc-001 (ECL Rajmahal Production)',
                          style: AppTypography.bodySmall
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (simResult == null || simResult.similar.isEmpty)
            const EmptyStateWidget(
              title: 'No Similar Documents Found',
              description:
                  'Vector similarity matrix will rank documents with cosine distance >= 0.70.',
              icon: Icons.compare_arrows,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: simResult.similar.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = simResult.similar[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cosine Similarity Meter
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.accentTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.accentTeal.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${(item.similarity * 100).toStringAsFixed(0)}%',
                                style: AppTypography.headlineSmall.copyWith(
                                  color: AppColors.accentTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('Cosine',
                                  style: AppTypography.labelSmall
                                      .copyWith(fontSize: 9)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.documentName,
                                  style: AppTypography.bodySmall
                                      .copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('Document ID: ${item.documentId}',
                                  style: AppTypography.labelSmall),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: item.commonEntities.map((e) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.badgeNeutralBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(e,
                                        style: AppTypography.labelSmall
                                            .copyWith(fontSize: 11)),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 5: CHANGES
  // -------------------------------------------------------------
  Widget _buildChangesTab(IntelligenceState state) {
    final changesResp = state.changes;

    if (changesResp == null || changesResp.changes.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Parameter Diffs',
        description: 'Select two documents to compare parameter changes.',
        icon: Icons.difference_outlined,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Changes Breakdown Strip
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatPill('Total Changes', '${changesResp.totalChanges}',
                      AppColors.accentBlue),
                  _buildStatPill(
                      'Added', '+${changesResp.added}', AppColors.success),
                  _buildStatPill(
                      'Modified', '${changesResp.modified}', AppColors.warning),
                  _buildStatPill(
                      'Removed', '-${changesResp.removed}', AppColors.error),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Parameter Diff Table
          Card(
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.surfaceMuted),
                columns: const [
                  DataColumn(label: Text('Parameter')),
                  DataColumn(label: Text('Doc A (Prior)')),
                  DataColumn(label: Text('Doc B (Current)')),
                  DataColumn(label: Text('Variance')),
                  DataColumn(label: Text('Unit')),
                ],
                rows: changesResp.changes.map((c) {
                  final isPositive = c.variancePct >= 0;
                  return DataRow(
                    cells: [
                      DataCell(Text(
                        c.parameter,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )),
                      DataCell(Text('${c.docAValue}')),
                      DataCell(Text('${c.docBValue}')),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? AppColors.successBg
                              : AppColors.errorBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${isPositive ? '+' : ''}${c.variancePct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: isPositive
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )),
                      DataCell(Text(c.unit ?? '—')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: AppTypography.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            )),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }

  // -------------------------------------------------------------
  // ACTIONS
  // -------------------------------------------------------------
  void _runIntelligenceAnalysis(BuildContext context) {
    ref
        .read(intelligenceNotifierProvider.notifier)
        .analyzeDocument(documentId: 'doc-001');
  }

  void _promptLinkEvidence(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Link Bidirectional Evidence'),
          content: const Text(
            'Link evidence citations between extracted mining parameters and underlying source text chunks for active document doc-001?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref
                    .read(intelligenceNotifierProvider.notifier)
                    .linkEvidence('doc-001');
              },
              child: const Text('Compute Links'),
            ),
          ],
        );
      },
    );
  }
}
