import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/topic_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/error_state.dart';
import '../../widgets/feedback/loading_indicator.dart';
import '../../widgets/layout/responsive_layout.dart';

/// Professional Topics Modeling & Taxonomy Discovery screen.
/// Covers:
/// 1. Topic Taxonomy & Discovery (/topics, /topics/analyze)
/// 2. Temporal Topic Trends (/topics/trends)
/// 3. Topic Clusters (/topics/clusters)
/// 4. Topic-Entity Associations (/topics/entities)
/// 5. Emerging Topics (/topics/emerging)
/// 6. Period Topic Changes (/topics/changes)
class TopicsScreen extends ConsumerStatefulWidget {
  const TopicsScreen({super.key});

  @override
  ConsumerState<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends ConsumerState<TopicsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(topicNotifierProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(topicNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      body: Column(
        children: [
          _buildHeader(state),
          _buildTabBar(),
          if (state.actionMessage != null) _buildActionBanner(state),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildHeader(TopicState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: ResponsiveBuilder(
        builder: (context, isMobile, isTablet, isDesktop) {
          final titleWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.hub_outlined,
                      size: 24, color: AppColors.accentTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Topic Modeling & Taxonomy Discovery',
                      style: AppTypography.headlineMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Corpus taxonomy, accelerating emerging topics, and period-to-period semantic shifts',
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
              // Trigger Topic Discovery
              ElevatedButton.icon(
                onPressed: state.isAnalyzing
                    ? null
                    : () => ref
                        .read(topicNotifierProvider.notifier)
                        .analyzeTopics(documentId: 'doc-001'),
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
                  state.isAnalyzing ? 'Discovering...' : 'Discover Topics',
                ),
              ),

              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh Topics',
                onPressed: state.isLoading
                    ? null
                    : () =>
                        ref.read(topicNotifierProvider.notifier).loadAll(),
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
          Tab(icon: Icon(Icons.list_alt, size: 18), text: 'Taxonomy Catalog'),
          Tab(icon: Icon(Icons.speed_outlined, size: 18), text: 'Emerging Topics'),
          Tab(icon: Icon(Icons.swap_horiz, size: 18), text: 'Period Shifts'),
          Tab(icon: Icon(Icons.bubble_chart_outlined, size: 18), text: 'Clusters & Entities'),
        ],
      ),
    );
  }

  Widget _buildActionBanner(TopicState state) {
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
                ref.read(topicNotifierProvider.notifier).clearMessages(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(TopicState state) {
    if (state.isLoading && state.topics.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: AppLoadingIndicator(message: 'Discovering statutory mining topics...'),
        ),
      );
    }

    if (state.errorMessage != null && state.topics.isEmpty) {
      return ErrorStateWidget(
        title: 'Failed to Load Topics',
        message: state.errorMessage!,
        onRetry: () => ref.read(topicNotifierProvider.notifier).loadAll(),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildTaxonomyTab(state),
        _buildEmergingTab(state),
        _buildChangesTab(state),
        _buildClustersEntitiesTab(state),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 0: TAXONOMY
  // -------------------------------------------------------------
  Widget _buildTaxonomyTab(TopicState state) {
    final topics = state.filteredTopics;

    return Column(
      children: [
        // Search Filter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          color: Theme.of(context).colorScheme.surface,
          child: TextField(
            controller: _searchController,
            onChanged: (query) =>
                ref.read(topicNotifierProvider.notifier).setSearchQuery(query),
            decoration: InputDecoration(
              hintText: 'Search topics by name, description, or keywords...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref
                            .read(topicNotifierProvider.notifier)
                            .setSearchQuery('');
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),

        // Topic Cards List
        Expanded(
          child: topics.isEmpty
              ? const EmptyStateWidget(
                  title: 'No Topics Found',
                  description: 'Try a different search query or discover topics.',
                  icon: Icons.hub_outlined,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: topics.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final topic = topics[index];
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
                                  child: Text(topic.name,
                                      style: AppTypography.headlineSmall),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentTeal
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Relevance: ${(topic.relevanceScore * 100).toStringAsFixed(0)}%',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.accentTeal,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(topic.description,
                                style: AppTypography.bodySmall),
                            const SizedBox(height: 14),

                            // Keyword tags
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: topic.keywords.map((kw) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                    border:
                                        Border.all(color: AppColors.borderSubtle),
                                  ),
                                  child: Text(kw,
                                      style: AppTypography.labelSmall),
                                );
                              }).toList(),
                            ),
                            const Divider(height: 24),

                            // Stats Footer
                            Row(
                              children: [
                                const Icon(Icons.folder_outlined,
                                    size: 16, color: AppColors.textTertiary),
                                const SizedBox(width: 4),
                                Text('${topic.documentCount} Documents',
                                    style: AppTypography.labelSmall),
                                const SizedBox(width: 16),
                                const Icon(Icons.forum_outlined,
                                    size: 16, color: AppColors.textTertiary),
                                const SizedBox(width: 4),
                                Text('${topic.mentionCount} Mentions',
                                    style: AppTypography.labelSmall),
                                const Spacer(),
                                Text(
                                  'Weight: ${(topic.weight * 100).toStringAsFixed(0)}%',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 1: EMERGING TOPICS
  // -------------------------------------------------------------
  Widget _buildEmergingTab(TopicState state) {
    if (state.emerging.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Emerging Topics Detected',
        description: 'Accelerating statutory themes will be displayed here.',
        icon: Icons.speed_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: state.emerging.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = state.emerging[index];
        final isAccelerating = item.status == 'ACCELERATING';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isAccelerating ? AppColors.accentTeal : AppColors.accentBlue)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isAccelerating ? Icons.rocket_launch : Icons.trending_up,
                    color: isAccelerating ? AppColors.accentTeal : AppColors.accentBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: AppTypography.headlineSmall),
                      const SizedBox(height: 4),
                      Text('Latest Active Period: ${item.latestPeriod}',
                          style: AppTypography.labelSmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAccelerating
                            ? AppColors.successBg
                            : AppColors.badgeNeutralBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${item.growthRate.toStringAsFixed(1)}% Growth',
                        style: TextStyle(
                          color: isAccelerating
                              ? AppColors.success
                              : AppColors.badgeNeutralText,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.status,
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isAccelerating
                            ? AppColors.accentTeal
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 2: PERIOD SHIFTS / CHANGES
  // -------------------------------------------------------------
  Widget _buildChangesTab(TopicState state) {
    if (state.changes.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Period Shifts Identified',
        description: 'Topic expansion and contraction trends will show here.',
        icon: Icons.swap_horiz,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: state.changes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final change = state.changes[index];
        final isExpanding = change.direction == 'EXPANDING';

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isExpanding
                  ? AppColors.successBg
                  : AppColors.errorBg,
              child: Icon(
                isExpanding ? Icons.north_east : Icons.south_east,
                color: isExpanding ? AppColors.success : AppColors.error,
                size: 20,
              ),
            ),
            title: Text(change.name,
                style: AppTypography.bodySmall
                    .copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Shift from ${change.fromPeriod} to ${change.toPeriod}',
              style: AppTypography.labelSmall,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isExpanding ? '+' : ''}${change.countChange} mentions',
                  style: TextStyle(
                    color: isExpanding ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  change.direction,
                  style: AppTypography.labelSmall.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 3: CLUSTERS & ENTITIES
  // -------------------------------------------------------------
  Widget _buildClustersEntitiesTab(TopicState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Topic Clusters', style: AppTypography.headlineSmall),
          const SizedBox(height: 12),
          if (state.clusters.isEmpty)
            const Text('No topic clusters available.')
          else
            ...state.clusters.map((c) {
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
                          Text(c.name,
                              style: AppTypography.bodySmall
                                  .copyWith(fontWeight: FontWeight.bold)),
                          Text('${c.documentsCount} Docs',
                              style: AppTypography.labelSmall),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: c.keywords.map((kw) {
                          return Chip(
                            label: Text(kw, style: AppTypography.labelSmall),
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),
          Text('Topic-Entity Associations',
              style: AppTypography.headlineSmall),
          const SizedBox(height: 12),
          if (state.entities.isEmpty)
            const Text('No topic-entity associations available.')
          else
            ...state.entities.map((assoc) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(assoc.topicName,
                          style: AppTypography.bodySmall
                              .copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: assoc.entities.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${e.name} (${e.type}: ${e.mentions})',
                              style: AppTypography.labelSmall,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
