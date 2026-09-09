import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/knowledge_base_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/feedback/loading_indicator.dart';
import 'widgets/vector_chunks_modal.dart';

/// Professional Knowledge Base and RAG Vector Search Screen for MineIntel AI.
class KnowledgeBaseScreen extends ConsumerStatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  ConsumerState<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends ConsumerState<KnowledgeBaseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _ragQueryController = TextEditingController();
  int _ragTopK = 5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(knowledgeBaseNotifierProvider.notifier).loadDocuments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _ragQueryController.dispose();
    super.dispose();
  }

  Future<void> _handleSemanticSearch() async {
    final q = _ragQueryController.text.trim();
    if (q.isEmpty) return;
    await ref.read(knowledgeBaseNotifierProvider.notifier).performSemanticSearch(q, topK: _ragTopK);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(knowledgeBaseNotifierProvider);

    // Listen for action or error notifications
    ref.listen(knowledgeBaseNotifierProvider, (previous, next) {
      if (next.actionMessage != null && next.actionMessage != previous?.actionMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.actionMessage!),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      body: Column(
        children: [
          // Header with KPI Stats Cards
          _buildHeaderStats(state),

          // Tab Bar
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 14),
              tabs: const [
                Tab(
                  height: 42,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Vector Indexing Directory',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Tab(
                  height: 42,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.travel_explore_outlined, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Semantic RAG Search Sandbox',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Documents Vector Indexing Directory
                _buildIndexingDirectoryTab(state),

                // Tab 2: Semantic RAG Search Sandbox
                _buildRagSearchSandboxTab(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(KnowledgeBaseState state) {
    final total = state.meta.total;
    final indexed = state.meta.totalIndexedDocuments;
    final chunks = state.meta.totalVectorChunks;
    final rate = total > 0 ? ((indexed / total) * 100).toStringAsFixed(0) : '0';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 14 : 20,
            vertical: isNarrow ? 10 : 16,
          ),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isNarrow ? 6 : 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.hub_outlined, color: AppColors.primary, size: isNarrow ? 18 : 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Knowledge Base & Vector Engine',
                          style: (isNarrow ? AppTypography.titleMedium : AppTypography.headlineLarge)
                              .copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Document chunking, 768-dim embeddings, and semantic RAG retrieval',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isNarrow ? 10 : 14),

              // Compact 3-Stat Grid Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Documents',
                      total.toString(),
                      Icons.description_outlined,
                      AppColors.primary,
                      isCompact: isNarrow,
                    ),
                  ),
                  SizedBox(width: isNarrow ? 6 : 12),
                  Expanded(
                    child: _buildStatCard(
                      'Indexed for RAG',
                      '$indexed ($rate%)',
                      Icons.check_circle_outline,
                      AppColors.success,
                      isCompact: isNarrow,
                    ),
                  ),
                  SizedBox(width: isNarrow ? 6 : 12),
                  Expanded(
                    child: _buildStatCard(
                      'Total Vector Chunks',
                      chunks.toString(),
                      Icons.grain,
                      AppColors.accentTeal,
                      isCompact: isNarrow,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isCompact = false,
  }) {
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: INDEXING DIRECTORY
  // ==========================================

  Widget _buildIndexingDirectoryTab(KnowledgeBaseState state) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Column(
      children: [
        // Filter toolbar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search documents by title or keyword...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: (val) {
                    ref.read(knowledgeBaseNotifierProvider.notifier).setFilter(
                          state.filter.copyWith(search: val),
                        );
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: () => ref.read(knowledgeBaseNotifierProvider.notifier).loadDocuments(),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: state.isLoading
              ? const Center(child: AppLoadingIndicator(message: 'Loading Knowledge Base documents...'))
              : state.documents.isEmpty
                  ? Center(
                      child: Text(
                        'No documents found matching current filters.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    )
                  : isDesktop
                      ? _buildDesktopTable(state)
                      : _buildMobileCards(state),
        ),
      ],
    );
  }

  Widget _buildDesktopTable(KnowledgeBaseState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.background),
            columns: const [
              DataColumn(label: Text('Document Name')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Vector Chunks')),
              DataColumn(label: Text('Last Indexed')),
              DataColumn(label: Text('Actions')),
            ],
            rows: state.documents.map((doc) {
              final isIndexing = state.isIndexing(doc.id);

              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.picture_as_pdf, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 240),
                          child: Text(
                            doc.originalName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      doc.category ?? 'Uncategorized',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: doc.isIndexed ? AppColors.success.withValues(alpha: 0.12) : AppColors.textMuted.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        doc.isIndexed ? 'Indexed' : 'Not Indexed',
                        style: AppTypography.labelSmall.copyWith(
                          color: doc.isIndexed ? AppColors.success : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${doc.chunksCount} chunks',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                  DataCell(
                    Text(
                      doc.lastIndexedAt != null ? doc.lastIndexedAt!.substring(0, 10) : 'Never',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Index / Re-index button
                        if (isIndexing)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          TextButton.icon(
                            icon: Icon(
                              doc.isIndexed ? Icons.refresh : Icons.play_arrow,
                              size: 14,
                            ),
                            label: Text(doc.isIndexed ? 'Re-index' : 'Index'),
                            onPressed: () => _triggerIndexing(doc.id),
                          ),

                        if (doc.isIndexed) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 18),
                            tooltip: 'Inspect Vector Chunks',
                            onPressed: () => _inspectChunks(doc.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                            tooltip: 'Delete Index',
                            onPressed: () => _confirmDeleteIndex(doc.id, doc.originalName),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCards(KnowledgeBaseState state) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.documents.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final doc = state.documents[index];
        final isIndexing = state.isIndexing(doc.id);

        return Card(
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        doc.originalName,
                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: doc.isIndexed ? AppColors.success.withValues(alpha: 0.12) : AppColors.textMuted.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        doc.isIndexed ? 'Indexed' : 'Not Indexed',
                        style: AppTypography.labelSmall.copyWith(
                          color: doc.isIndexed ? AppColors.success : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Chunks: ${doc.chunksCount} | Category: ${doc.category ?? "N/A"}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const Divider(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (isIndexing)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        ElevatedButton.icon(
                          icon: Icon(doc.isIndexed ? Icons.refresh : Icons.play_arrow, size: 14),
                          label: Text(doc.isIndexed ? 'Re-index' : 'Index Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          onPressed: () => _triggerIndexing(doc.id),
                        ),
                      if (doc.isIndexed) ...[
                        OutlinedButton.icon(
                          icon: const Icon(Icons.visibility_outlined, size: 14),
                          label: const Text('Chunks'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          onPressed: () => _inspectChunks(doc.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _confirmDeleteIndex(doc.id, doc.originalName),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _triggerIndexing(String documentId) async {
    final notifier = ref.read(knowledgeBaseNotifierProvider.notifier);
    await notifier.indexDocument(documentId);
  }

  Future<void> _inspectChunks(String documentId) async {
    final notifier = ref.read(knowledgeBaseNotifierProvider.notifier);
    await notifier.loadDocumentChunks(documentId);
    final detail = ref.read(knowledgeBaseNotifierProvider).activeDetail;
    if (detail != null && mounted) {
      VectorChunksModal.show(context, detail);
    }
  }

  Future<void> _confirmDeleteIndex(String documentId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vector Index?'),
        content: Text('Are you sure you want to remove vector embeddings for "$name"? Semantic search and RAG will no longer reference this document.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Index', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(knowledgeBaseNotifierProvider.notifier).deleteDocumentIndex(documentId);
    }
  }

  // ==========================================
  // TAB 2: RAG SEARCH SANDBOX
  // ==========================================

  Widget _buildRagSearchSandboxTab(KnowledgeBaseState state) {
    return Column(
      children: [
        // Query Box & Settings
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ragQueryController,
                      decoration: InputDecoration(
                        hintText: 'Enter semantic query (e.g. "airway methane")...',
                        prefixIcon: const Icon(Icons.travel_explore, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onSubmitted: (_) => _handleSemanticSearch(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: state.isSearching
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                          )
                        : const Icon(Icons.search, size: 16),
                    label: const Text('Search Vectors'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onPressed: state.isSearching ? null : _handleSemanticSearch,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Top Results (K) chips with Wrap for zero-overflow responsiveness
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Top Results (K):',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ...[3, 5, 10, 20].map((k) {
                    final isSelected = _ragTopK == k;
                    return ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                      label: Text('$k', style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      onSelected: (val) {
                        if (val) setState(() => _ragTopK = k);
                      },
                    );
                  }),
                  if (state.searchResults.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    TextButton.icon(
                      icon: const Icon(Icons.close, size: 14),
                      label: const Text('Clear Results', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      ),
                      onPressed: () => ref.read(knowledgeBaseNotifierProvider.notifier).clearSearch(),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Results List
        Expanded(
          child: state.isSearching
              ? const Center(child: AppLoadingIndicator(message: 'Executing vector cosine similarity ranking...'))
              : state.searchResults.isEmpty
                  ? Center(
                      child: Text(
                        state.lastSearchQuery == null
                            ? 'Run a query to explore vector chunk embeddings'
                            : 'No matching vector chunks found above similarity threshold.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.searchResults.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final result = state.searchResults[index];
                        final scorePct = (result.similarity * 100).toStringAsFixed(1);
                        final scoreColor = result.similarity >= 0.85
                            ? AppColors.success
                            : (result.similarity >= 0.70 ? AppColors.warning : AppColors.error);

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: scoreColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: scoreColor.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      '$scorePct% Similarity',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: scoreColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.picture_as_pdf, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      result.documentName,
                                      style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Page ${result.pageNumber}',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SelectableText(
                                result.text,
                                style: AppTypography.bodySmall.copyWith(height: 1.4),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
