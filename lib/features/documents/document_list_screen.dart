import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/document_model.dart';
import '../../services/file_service.dart';
import '../../state/document_state.dart';
import '../../theme/app_colors.dart';
import 'document_detail_screen.dart';
import 'document_upload_dialog.dart';

/// Responsive Document List Screen showing cards on mobile and a rich data table on desktop.
/// Supports search, category/type/status/classification filtering, upload modal, and quick actions.
class DocumentListScreen extends ConsumerStatefulWidget {
  const DocumentListScreen({super.key});

  @override
  ConsumerState<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends ConsumerState<DocumentListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Load documents on initial mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentListNotifierProvider.notifier).loadDocuments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openUploadDialog() {
    DocumentUploadDialog.show(
      context,
      onUploadSuccess: (doc) {
        // Automatically refreshed by DocumentListNotifier
      },
    );
  }

  void _navigateToDetail(DocumentModel doc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentDetailScreen(documentId: doc.id),
      ),
    );
  }

  Future<void> _handleDownload(DocumentModel doc) async {
    try {
      final storageDir = await FileService().getStorageDirectory();
      final savePath = '${storageDir.path}/${doc.originalName}';

      final repo = ref.read(documentRepositoryProvider);
      await repo.downloadDocument(doc.id, savePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded to $savePath'),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () => FileService().openFile(savePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(DocumentModel doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text('Delete Document?', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${doc.originalName}"?',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(documentListNotifierProvider.notifier)
          .deleteDocument(doc.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document deleted successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(documentListNotifierProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => ref.read(documentListNotifierProvider.notifier).refresh(),
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // Sliver Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isDesktop
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Document Lifecycle & Ingestion',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Multi-format ingestion, OCR extraction, GIS metadata & governance',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: _openUploadDialog,
                                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                                label: const Text('Upload Document'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Document Lifecycle & Ingestion',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Multi-format ingestion, OCR extraction, GIS metadata & governance',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _openUploadDialog,
                                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                                label: const Text('Upload Document'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 18),

                    // Search and Filter Bar
                    _buildFilterControls(listState),
                  ],
                ),
              ),
            ),

            // Content Area (Loading, Error, Empty, or Responsive Data)
            if (listState.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (listState.isError)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        listState.errorMessage ?? 'Failed to load documents.',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(documentListNotifierProvider.notifier)
                            .loadDocuments(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (listState.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open_outlined,
                          size: 64, color: AppColors.textTertiary),
                      const SizedBox(height: 16),
                      const Text(
                        'No documents found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Try adjusting your search criteria or upload a new mining document.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _openUploadDialog,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Document'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Desktop Data Table or Mobile Card Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: isDesktop
                    ? SliverToBoxAdapter(child: _buildDesktopTable(listState.documents))
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildMobileCard(listState.documents[index]),
                          childCount: listState.documents.length,
                        ),
                      ),
              ),

              // Pagination Footer
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildPaginationBar(listState.meta),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterControls(DocumentListState state) {
    final filter = state.filter;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Search input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search documents by filename or mine...',
                    hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: AppColors.textTertiary),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(documentListNotifierProvider.notifier).setSearch(null);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (val) {
                    ref.read(documentListNotifierProvider.notifier).setSearch(val);
                  },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(documentListNotifierProvider.notifier)
                      .setSearch(_searchController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceMuted,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter Dropdowns Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Type Filter
                _buildFilterDropdown<String>(
                  label: 'Type: ${filter.type?.toUpperCase() ?? 'All'}',
                  value: filter.type,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Types')),
                    DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                    DropdownMenuItem(value: 'docx', child: Text('DOCX')),
                    DropdownMenuItem(value: 'xlsx', child: Text('XLSX')),
                    DropdownMenuItem(value: 'pptx', child: Text('PPTX')),
                    DropdownMenuItem(value: 'csv', child: Text('CSV')),
                    DropdownMenuItem(value: 'image', child: Text('Image')),
                  ],
                  onChanged: (val) =>
                      ref.read(documentListNotifierProvider.notifier).setType(val),
                ),
                const SizedBox(width: 10),

                // Status Filter
                _buildFilterDropdown<String>(
                  label: 'Status: ${filter.status?.toUpperCase() ?? 'All'}',
                  value: filter.status,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Statuses')),
                    DropdownMenuItem(value: 'queued', child: Text('Queued')),
                    DropdownMenuItem(value: 'processing', child: Text('Processing')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'failed', child: Text('Failed')),
                  ],
                  onChanged: (val) =>
                      ref.read(documentListNotifierProvider.notifier).setStatus(val),
                ),
                const SizedBox(width: 10),

                // Category Filter
                _buildFilterDropdown<String>(
                  label: 'Category: ${filter.category ?? 'All'}',
                  value: filter.category,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Categories')),
                    ...AppConstants.categories.map(
                      (c) => DropdownMenuItem(value: c, child: Text(c)),
                    ),
                  ],
                  onChanged: (val) =>
                      ref.read(documentListNotifierProvider.notifier).setCategory(val),
                ),
                const SizedBox(width: 10),

                // Classification Filter
                _buildFilterDropdown<String>(
                  label: 'Security: ${filter.classification?.toUpperCase() ?? 'All'}',
                  value: filter.classification,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Classifications')),
                    ...AppConstants.classifications.map(
                      (c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase())),
                    ),
                  ],
                  onChanged: (val) =>
                      ref.read(documentListNotifierProvider.notifier).setClassification(val),
                ),
                const SizedBox(width: 10),

                // Reset Filters Button
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    ref.read(documentListNotifierProvider.notifier).clearFilters();
                  },
                  icon: const Icon(Icons.filter_alt_off, size: 16, color: AppColors.textSecondary),
                  label: const Text('Reset', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T?>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: value,
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
          items: items,
          onChanged: onChanged,
          hint: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List<DocumentModel> documents) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surfaceMuted),
          dataRowMinHeight: 52,
          dataRowMaxHeight: 56,
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Document', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Classification', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Size / Pages', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: documents.map((doc) {
            return DataRow(
              cells: [
                // Filename & Icon
                DataCell(
                  InkWell(
                    onTap: () => _navigateToDetail(doc),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFileTypeIcon(doc.fileType),
                        const SizedBox(width: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: Text(
                            doc.originalName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Category
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      doc.category,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                // Classification
                DataCell(_buildClassificationBadge(doc.classification)),
                // Size & Pages
                DataCell(
                  Text(
                    '${doc.formattedFileSize} • ${doc.totalPages} ${doc.totalPages == 1 ? 'pg' : 'pgs'}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                // Status
                DataCell(_buildStatusBadge(doc.status)),
                // Actions
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        tooltip: 'View Extracted Text & Metadata',
                        onPressed: () => _navigateToDetail(doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.download_rounded, size: 18),
                        tooltip: 'Download File',
                        onPressed: () => _handleDownload(doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        tooltip: 'Delete Document',
                        onPressed: () => _confirmDelete(doc),
                      ),
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

  Widget _buildMobileCard(DocumentModel doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(doc),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFileTypeIcon(doc.fileType),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.originalName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${doc.category} • ${doc.formattedFileSize}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(doc.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildClassificationBadge(doc.classification),
                  const SizedBox(width: 8),
                  Text(
                    '${doc.totalPages} ${doc.totalPages == 1 ? 'Page' : 'Pages'}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.download_rounded, size: 18),
                    tooltip: 'Download',
                    onPressed: () => _handleDownload(doc),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(doc),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type.toLowerCase()) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = AppColors.error;
        break;
      case 'docx':
        icon = Icons.description;
        color = AppColors.accentBlue;
        break;
      case 'xlsx':
      case 'csv':
        icon = Icons.table_chart;
        color = AppColors.accentGreen;
        break;
      case 'pptx':
        icon = Icons.slideshow;
        color = AppColors.warning;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    Widget leading;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'extracted':
        bg = AppColors.successBg;
        fg = AppColors.success;
        leading = const Icon(Icons.check_circle, size: 12, color: AppColors.success);
        break;
      case 'processing':
        bg = AppColors.infoBg;
        fg = AppColors.accentBlue;
        leading = const SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
          ),
        );
        break;
      case 'queued':
      case 'pending':
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        leading = const Icon(Icons.access_time, size: 12, color: AppColors.warning);
        break;
      case 'failed':
      default:
        bg = AppColors.errorBg;
        fg = AppColors.error;
        leading = const Icon(Icons.error_outline, size: 12, color: AppColors.error);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _buildClassificationBadge(String classification) {
    Color color;
    switch (classification.toLowerCase()) {
      case 'restricted':
        color = AppColors.error;
        break;
      case 'confidential':
        color = AppColors.warning;
        break;
      case 'internal':
        color = AppColors.accentBlue;
        break;
      case 'public':
      default:
        color = AppColors.accentGreen;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        classification.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildPaginationBar(DocumentPaginationMeta meta) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(
          'Total: ${meta.total} ${meta.total == 1 ? 'document' : 'documents'}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              tooltip: 'Previous Page',
              onPressed: meta.page > 1
                  ? () => ref
                      .read(documentListNotifierProvider.notifier)
                      .setPage(meta.page - 1)
                  : null,
            ),
            Text(
              'Page ${meta.page} of ${meta.pages}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              tooltip: 'Next Page',
              onPressed: meta.page < meta.pages
                  ? () => ref
                      .read(documentListNotifierProvider.notifier)
                      .setPage(meta.page + 1)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}
