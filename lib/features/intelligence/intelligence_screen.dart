import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/intelligence_model.dart';
import '../../models/topic_model.dart';
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
/// 2. Multi-Topic Temporal Trends Chart (/intelligence/trends) - Image 4
/// 3. Named Entity Catalog & Category Distribution (/intelligence/entities)
/// 4. Cross-Document Comparison & Parameter Diffs (/intelligence/changes) - Image 5
/// 5. Semantic Intelligence Clusters & Weight Distribution (/intelligence/clusters)
/// 6. Document Cosine Similarity Matrix (/intelligence/similarity)
/// 7. Bidirectional Evidence Linking (/intelligence/link-evidence/:id)
class IntelligenceScreen extends ConsumerStatefulWidget {
  const IntelligenceScreen({super.key});

  @override
  ConsumerState<IntelligenceScreen> createState() => _IntelligenceScreenState();
}

class _IntelligenceScreenState extends ConsumerState<IntelligenceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _entitySearchQuery = '';
  String? _selectedDocA;
  String? _selectedDocB;
  bool _showTooltip = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

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

    if (_selectedDocA == null && state.availableDocuments.isNotEmpty) {
      _selectedDocA = state.selectedDocA ?? state.availableDocuments.first['id'];
    }
    if (_selectedDocB == null && state.availableDocuments.length > 1) {
      _selectedDocB = state.selectedDocB ?? state.availableDocuments[1]['id'];
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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

  // -------------------------------------------------------------
  // TOP BAR (MATCHING IMAGES 4 & 5)
  // -------------------------------------------------------------
  Widget _buildTopBar(IntelligenceState state) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: ResponsiveBuilder(
        builder: (context, isMobile, isTablet, isDesktop) {
          final titleWidget = Row(
            children: [
              Container(
                width: isMobile ? 32 : 40,
                height: isMobile ? 32 : 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                  border: Border.all(
                    color: const Color(0xFFFDE68A),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: const Color(0xFFD97706),
                  size: isMobile ? 18 : 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Document Intelligence & Cross-Reasoning',
                      style: AppTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 14 : 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isMobile
                          ? 'Corpus entities, clustering & diffs'
                          : 'Advanced document analysis & insights • Corpus-wide named entities, semantic clustering, cosine similarity, and parameter diffs',
                      style: AppTypography.bodySmall.copyWith(
                        color: const Color(0xFF6B7280),
                        fontSize: isMobile ? 10.5 : 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );

          final actionsWidget = isMobile
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: state.isLinkingEvidence
                            ? null
                            : () => _promptLinkEvidence(context),
                        icon: state.isLinkingEvidence
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.link, size: 15),
                        label: const Text('Link Evidence', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          visualDensity: VisualDensity.compact,
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
                            : const Icon(Icons.auto_awesome, size: 15),
                        label: Text(
                          state.isAnalyzing ? 'Analyzing...' : 'Run Analysis',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Refresh Intelligence',
                      visualDensity: VisualDensity.compact,
                      onPressed: state.isLoading
                          ? null
                          : () => ref.read(intelligenceNotifierProvider.notifier).loadAll(),
                    ),
                  ],
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
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
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          : () => ref.read(intelligenceNotifierProvider.notifier).loadAll(),
                    ),
                  ],
                );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                titleWidget,
                const SizedBox(height: 8),
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
      color: Theme.of(context).colorScheme.surface,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          child: AppLoadingIndicator(
            message: 'Synthesizing corpus-wide intelligence...',
          ),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveBuilder(
            builder: (context, isMobile, isTablet, isDesktop) {
              final cards = [
                _buildKpiCard(
                  title: 'Discovered Entities',
                  value: '${overview?.totalEntities ?? 15}',
                  subtitle: 'Locations, Mines, Equipment, Figures',
                  icon: Icons.fingerprint,
                  color: AppColors.accentTeal,
                ),
                _buildKpiCard(
                  title: 'Taxonomy Topics',
                  value: '${overview?.totalTopics ?? 17}',
                  subtitle: 'Operational & Compliance themes',
                  icon: Icons.hub_outlined,
                  color: AppColors.accentBlue,
                ),
                _buildKpiCard(
                  title: 'Similarity Clusters',
                  value: '${overview?.similarityClusters ?? 2}',
                  subtitle: 'Semantically clustered document sets',
                  icon: Icons.bubble_chart_outlined,
                  color: AppColors.accentIndigo,
                ),
                _buildKpiCard(
                  title: 'Cross-Doc Changes',
                  value: '${overview?.recentChanges ?? 11}',
                  subtitle: 'Parameter variances identified',
                  icon: Icons.swap_horiz,
                  color: AppColors.warning,
                ),
              ];

              if (isMobile) {
                return Column(
                  children: cards
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: c,
                          ))
                      .toList(),
                );
              }

              return GridView.count(
                crossAxisCount: isTablet ? 2 : 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isTablet ? 2.2 : 1.8,
                children: cards,
              );
            },
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          size: 20, color: AppColors.accentTeal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Intelligence Synthesis Summary',
                          style: AppTypography.headlineSmall.copyWith(
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Multi-document intelligence extracts named entities across statutory reports, computes bidirectional citation links between text chunks and verified parameters, and clusters documents by operational topic.',
                    style: AppTypography.bodyMedium,
                  ),
                  const Divider(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _tabController.animateTo(2),
                        icon: const Icon(Icons.arrow_forward, size: 15),
                        label: const Text('Inspect Named Entities'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _tabController.animateTo(4),
                        icon: const Icon(Icons.compare_arrows, size: 15),
                        label: const Text('Explore Similarity Clusters'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _tabController.animateTo(1),
                        icon: const Icon(Icons.trending_up, size: 15),
                        label: const Text('View Topic Trends'),
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
        padding: const EdgeInsets.all(14),
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
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTypography.headlineLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 2),
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
  // TAB 1: TRENDS & MULTI-TOPIC BAR CHART (IMAGE 4)
  // -------------------------------------------------------------
  Widget _buildTrendsTab(IntelligenceState state) {
    if (state.trends.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Trends Available',
        description: 'Temporal topic intelligence trends will display here.',
        icon: Icons.trending_up,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMultiTopicEvolutionCard(state),
          const SizedBox(height: 16),
          _buildTopicTrackingCards(state),
          const SizedBox(height: 20),
          Text(
            'Temporal Progression by Operational Area',
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...state.trends.map((trend) => _buildTopicTrendCard(trend)),
        ],
      ),
    );
  }

  Widget _buildMultiTopicEvolutionCard(IntelligenceState state) {
    final trends = state.trends;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.bar_chart_rounded,
                          color: Color(0xFFD97706),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cross-Period Topic Evolution',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _showTooltip = !_showTooltip),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showTooltip
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showTooltip ? 'Hide Tooltip' : 'Show Tooltip',
                          style: AppTypography.labelSmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              clipBehavior: Clip.none,
              children: [
                _buildBarChartCanvas(trends),
                if (_showTooltip && trends.isNotEmpty)
                  Positioned(
                    top: 16,
                    left: 20,
                    child: _buildChartTooltip(trends),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildChartLegend(trends),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCanvas(List<TopicTrend> trends) {
    final colors = [
      const Color(0xFF5A67D8),
      const Color(0xFFD97706),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFEC4899),
    ];

    final periodLabel = trends.first.periods.isNotEmpty
        ? trends.first.periods.first.period
        : 'FY 2023';

    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.only(left: 36, bottom: 24, top: 12, right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGridLine('1.00'),
                _buildGridLine('0.75'),
                _buildGridLine('0.50'),
                _buildGridLine('0.25'),
                _buildGridLine('0.00'),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 170,
                  height: 180,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: trends.take(3).toList().asMap().entries.map((e) {
                      final i = e.key;
                      final t = e.value;
                      final color = colors[i % colors.length];
                      final count =
                          t.periods.isNotEmpty ? t.periods.first.count : 1;
                      final heightFraction = (count / 1.0).clamp(0.2, 1.0);

                      return Container(
                        width: 44,
                        height: 170 * heightFraction,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 184),
              child: Text(
                periodLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridLine(String label) {
    return Row(
      children: [
        Transform.translate(
          offset: const Offset(-34, 0),
          child: SizedBox(
            width: 30,
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
        ),
      ],
    );
  }

  Widget _buildChartTooltip(List<TopicTrend> trends) {
    final colors = [
      const Color(0xFFD97706),
      const Color(0xFF10B981),
      const Color(0xFF5A67D8),
    ];

    final period = trends.first.periods.isNotEmpty
        ? trends.first.periods.first.period
        : 'FY 2023';

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            period,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ...trends.take(3).toList().asMap().entries.map((entry) {
            final idx = entry.key;
            final t = entry.value;
            final color = colors[idx % colors.length];
            final count = t.periods.isNotEmpty ? t.periods.first.count : 1;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${t.name} : $count',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChartLegend(List<TopicTrend> trends) {
    final colors = [
      const Color(0xFFD97706),
      const Color(0xFF10B981),
      const Color(0xFF5A67D8),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: trends.take(3).toList().asMap().entries.map((entry) {
        final idx = entry.key;
        final t = entry.value;
        final color = colors[idx % colors.length];
        return Container(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  t.name,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopicTrackingCards(IntelligenceState state) {
    final colors = [
      const Color(0xFF5A67D8),
      const Color(0xFFD97706),
      const Color(0xFF10B981),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 450
            ? (constraints.maxWidth - 20) / 2
            : 150.0;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: state.trends.take(3).toList().asMap().entries.map((entry) {
            final i = entry.key;
            final t = entry.value;
            final color = colors[i % colors.length];
            final trackedCount = t.periods.length;

            return Container(
              width: cardWidth,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          t.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$trackedCount periods tracked',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTopicTrendCard(TopicTrend trend) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    trend.name,
                    style: AppTypography.headlineSmall.copyWith(
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            const SizedBox(height: 12),
            Text('Period Frequency Progression:',
                style: AppTypography.labelSmall),
            const SizedBox(height: 8),
            Row(
              children: trend.periods.map((p) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.period,
                          style: AppTypography.labelSmall.copyWith(fontSize: 11),
                        ),
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
  }

  // -------------------------------------------------------------
  // TAB 2: ENTITIES & CATEGORY DISTRIBUTION GRAPH
  // -------------------------------------------------------------
  Widget _buildEntitiesTab(IntelligenceState state) {
    final types = [
      'ALL',
      'MINE',
      'LOCATION',
      'ORGANIZATION',
      'EQUIPMENT',
      'FIGURE',
      'SUBSIDIARY'
    ];
    final entities = state.filteredEntities.where((e) {
      if (_entitySearchQuery.isEmpty) return true;
      return e.name.toLowerCase().contains(_entitySearchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Persistent search & filter bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search entities across corpus...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: AppColors.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                onChanged: (val) => setState(() => _entitySearchQuery = val),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: types.map((type) {
                    final isSelected = state.entityTypeFilter == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(type),
                        visualDensity: VisualDensity.compact,
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
            ],
          ),
        ),

        // Unified scrollable lower section preventing RenderFlex overflow
        Expanded(
          child: entities.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildEntityCategoryDistributionCard(state.entities, inList: true),
                    const SizedBox(height: 16),
                    const EmptyStateWidget(
                      title: 'No Entities Matching Filter',
                      description: 'Try switching entity category filters or clearing the search query.',
                      icon: Icons.fingerprint,
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: entities.length + 1,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildEntityCategoryDistributionCard(state.entities, inList: true);
                    }
                    final item = entities[index - 1];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: _getEntityColor(item.type)
                              .withValues(alpha: 0.15),
                          child: Icon(
                            _getEntityIcon(item.type),
                            color: _getEntityColor(item.type),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          item.documents.isNotEmpty
                              ? 'Associated Documents: ${item.documents.join(', ')}'
                              : 'Extracted across corpus statutory filings',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
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

  Widget _buildEntityCategoryDistributionCard(List<IntelligenceEntity> entities, {bool inList = false}) {
    if (entities.isEmpty) return const SizedBox.shrink();

    final mineCount = entities.where((e) => e.type == 'MINE').length;
    final subCount = entities.where((e) => e.type == 'SUBSIDIARY').length;
    final orgCount = entities.where((e) => e.type == 'ORGANIZATION').length;
    final equipCount = entities.where((e) => e.type == 'EQUIPMENT').length;
    final total = entities.length;

    return Container(
      margin: inList ? const EdgeInsets.only(bottom: 8) : const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Entity Category Distribution',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$total Extracted',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (mineCount > 0)
                    Expanded(
                      flex: mineCount,
                      child: Container(color: AppColors.accentTeal),
                    ),
                  if (subCount > 0)
                    Expanded(
                      flex: subCount,
                      child: Container(color: AppColors.accentBlue),
                    ),
                  if (orgCount > 0)
                    Expanded(
                      flex: orgCount,
                      child: Container(color: AppColors.accentIndigo),
                    ),
                  if (equipCount > 0)
                    Expanded(
                      flex: equipCount,
                      child: Container(color: AppColors.warning),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildCategoryPill('Mine', mineCount, AppColors.accentTeal),
              _buildCategoryPill('Subsidiary', subCount, AppColors.accentBlue),
              _buildCategoryPill('Organization', orgCount, AppColors.accentIndigo),
              _buildCategoryPill('Equipment', equipCount, AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $count',
          style: AppTypography.labelSmall.copyWith(fontSize: 11),
        ),
      ],
    );
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
      padding: const EdgeInsets.all(16),
      itemCount: state.clusters.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final cluster = state.clusters[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        cluster.name,
                        style: AppTypography.headlineSmall.copyWith(
                          fontSize: 15,
                        ),
                      ),
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
                const SizedBox(height: 10),
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
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Text(kw, style: AppTypography.labelSmall),
                    );
                  }).toList(),
                ),
                if (cluster.relatedTopics.isNotEmpty) ...[
                  const Divider(height: 20),
                  Text('Related Topics & Correlation Strength:',
                      style: AppTypography.labelSmall),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: cluster.relatedTopics.map((rel) {
                      return Chip(
                        label: Text(
                          '${rel.name} (${(rel.strength * 100).toStringAsFixed(0)}%)',
                          style: AppTypography.labelSmall.copyWith(fontSize: 11),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
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
                              : 'Active Corpus Statutory Documents',
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
          const SizedBox(height: 12),
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
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = simResult.similar[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
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
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Cosine',
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.documentName,
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Document ID: ${item.documentId}',
                                style: AppTypography.labelSmall,
                              ),
                              const SizedBox(height: 6),
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
                                    child: Text(
                                      e,
                                      style: AppTypography.labelSmall
                                          .copyWith(fontSize: 11),
                                    ),
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
  // TAB 5: CHANGES / COMPARE DOCUMENTS (IMAGE 5)
  // -------------------------------------------------------------
  Widget _buildChangesTab(IntelligenceState state) {
    final docs = state.availableDocuments;
    final changesResp = state.changes;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cross-Document Parameter Comparison',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select two statutory documents to compute parameter deltas and audit variances.',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDocumentDropdown(
                    label: 'Document A...',
                    value: _selectedDocA,
                    items: docs,
                    onChanged: (val) => setState(() => _selectedDocA = val),
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentDropdown(
                    label: 'Document B...',
                    value: _selectedDocB,
                    items: docs,
                    onChanged: (val) => setState(() => _selectedDocB = val),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5A96A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: state.isComparing
                          ? null
                          : () {
                              final a = _selectedDocA ?? 'doc-001';
                              final b = _selectedDocB ?? 'doc-002';
                              ref
                                  .read(intelligenceNotifierProvider.notifier)
                                  .compareDocuments(docA: a, docB: b);
                            },
                      icon: state.isComparing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.sync_alt, size: 18),
                      label: Text(
                        state.isComparing
                            ? 'Comparing Documents...'
                            : 'Compare Documents',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (changesResp == null || changesResp.changes.isEmpty)
            const EmptyStateWidget(
              title: 'No Parameter Diffs',
              description: 'Select two documents to compare parameter changes.',
              icon: Icons.difference_outlined,
            )
          else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatPill('Total',
                          '${changesResp.totalChanges}', AppColors.accentBlue),
                    ),
                    Expanded(
                      child: _buildStatPill(
                          'Added', '+${changesResp.added}', AppColors.success),
                    ),
                    Expanded(
                      child: _buildStatPill('Modified', '${changesResp.modified}',
                          AppColors.warning),
                    ),
                    Expanded(
                      child: _buildStatPill(
                          'Removed', '-${changesResp.removed}', AppColors.error),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Parameter Delta Details (${changesResp.changes.length})',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            ...changesResp.changes.map((item) => _buildDiffItemCard(item)),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentDropdown({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final dropdownItems = items.isNotEmpty
        ? items
        : [
            {
              'id': 'doc-001',
              'name': 'MineIntel_MultiPeriod_Test_Report.pdf',
            },
            {
              'id': 'doc-002',
              'name': 'validation_test_bad_data.pdf',
            },
          ];

    final effectiveValue = dropdownItems.any((d) => d['id'] == value)
        ? value
        : dropdownItems.first['id'];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: effectiveValue,
          hint: Text(label, style: const TextStyle(color: Color(0xFF9CA3AF))),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
          items: dropdownItems.map((doc) {
            return DropdownMenuItem<String>(
              value: doc['id'],
              child: Text(
                doc['name'] ?? 'Document',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDiffItemCard(IntelligenceChangeItem item) {
    final type = item.type?.toLowerCase() ?? 'modified';
    Color badgeColor;
    Color badgeBg;
    String badgeText;

    if (type == 'added') {
      badgeColor = AppColors.success;
      badgeBg = AppColors.successBg;
      badgeText = '+ ADDED';
    } else if (type == 'removed') {
      badgeColor = AppColors.error;
      badgeBg = AppColors.errorBg;
      badgeText = '- REMOVED';
    } else {
      badgeColor = AppColors.warning;
      badgeBg = AppColors.warningBg;
      badgeText = 'MODIFIED';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.parameter,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            if (item.mineName != null && item.mineName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.terrain, size: 13, color: AppColors.accentTeal),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${item.mineName}${item.subsidiary != null && item.subsidiary!.isNotEmpty ? ' (${item.subsidiary})' : ''}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Prior (Doc A)',
                          style: AppTypography.labelSmall.copyWith(fontSize: 10)),
                      const SizedBox(height: 2),
                      Text(
                        item.oldValue != null
                            ? '${item.oldValue}'
                            : (item.docAValue > 0 ? '${item.docAValue}' : '—'),
                        style: TextStyle(
                          fontSize: 12,
                          color: item.oldValue != null
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current (Doc B)',
                          style: AppTypography.labelSmall.copyWith(fontSize: 10)),
                      const SizedBox(height: 2),
                      Text(
                        item.newValue != null
                            ? '${item.newValue}'
                            : (item.docBValue > 0 ? '${item.docBValue}' : '—'),
                        style: TextStyle(
                          fontSize: 12,
                          color: item.newValue != null
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // REUSABLE HELPERS
  // -------------------------------------------------------------
  Widget _buildStatPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headlineSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(label, style: AppTypography.labelSmall.copyWith(fontSize: 11)),
      ],
    );
  }

  Color _getEntityColor(String type) {
    switch (type.toUpperCase()) {
      case 'MINE':
        return AppColors.accentTeal;
      case 'SUBSIDIARY':
        return AppColors.accentBlue;
      case 'LOCATION':
        return const Color(0xFF0284C7);
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
      case 'SUBSIDIARY':
        return Icons.apartment;
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
