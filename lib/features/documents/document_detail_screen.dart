import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/document_model.dart';
import '../../services/file_service.dart';
import '../../state/document_state.dart';
import '../../theme/app_colors.dart';
import '../extraction/extraction_screen.dart';
import '../validation/validation_screen.dart';
import 'document_metadata_dialog.dart';

/// Screen displaying document details, extracted OCR pages, GIS & technical metadata,
/// live processing status telemetry, and management actions (reprocess, download, delete).
class DocumentDetailScreen extends ConsumerStatefulWidget {
  final String documentId;

  const DocumentDetailScreen({
    super.key,
    required this.documentId,
  });

  @override
  ConsumerState<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen>
    with SingleTickerProviderStateMixin {
  int _selectedPageIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Explicit trigger on load - NEVER triggers from widget build()
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentDetailNotifierProvider.notifier).loadDocument(widget.documentId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(DocumentModel doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 26),
            SizedBox(width: 10),
            Text('Delete Document?', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${doc.originalName}"?\n\nThis will remove all associated OCR pages, vector chunks, and extracted records permanently.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(documentListNotifierProvider.notifier)
          .deleteDocument(widget.documentId);
      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document deleted successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
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
            content: Text('Saved to $savePath'),
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

  Future<void> _handleReprocess() async {
    final notifier = ref.read(documentDetailNotifierProvider.notifier);
    final success = await notifier.reprocess(widget.documentId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document queued for reprocessing.'),
          backgroundColor: AppColors.accentTeal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentDetailNotifierProvider);
    final procState = ref.watch(documentProcessingNotifierProvider);

    // Watch live status updates if available
    final liveStatus = procState.statuses[widget.documentId] ?? state.processingStatus;

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Document Details')),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (state.isError || state.detail == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Document Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                state.errorMessage ?? 'Failed to load document details.',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref
                    .read(documentDetailNotifierProvider.notifier)
                    .loadDocument(widget.documentId),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final doc = state.detail!.document;
    final pages = state.detail!.pages;
    final metadata = state.metadata;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          doc.originalName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            tooltip: 'Extracted Records',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ExtractionScreen(initialDocumentId: doc.id),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.rule_outlined),
            tooltip: 'Validation Engine',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ValidationScreen(initialDocumentId: doc.id),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download File',
            onPressed: () => _handleDownload(doc),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reprocess Document',
            onPressed: state.isActionLoading ? null : _handleReprocess,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Delete Document',
            onPressed: state.isActionLoading ? null : () => _confirmDelete(doc),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentTeal,
          labelColor: AppColors.accentTeal,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.article_outlined, size: 18), text: 'OCR Extracted Pages'),
            Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Metadata & GIS'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Processing Status Telemetry Banner
          _buildStatusBanner(doc, liveStatus),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: OCR Pages
                _buildOcrPagesView(pages),

                // Tab 2: Metadata & GIS
                _buildMetadataView(doc, metadata),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(DocumentModel doc, DocumentStatusModel? liveStatus) {
    final status = liveStatus?.status ?? doc.status;
    final progress = liveStatus?.progress ?? (doc.isCompleted ? 100 : (doc.isProcessing ? 50 : 0));
    final isProcessing = status == 'processing' || status == 'queued';
    final isFailed = status == 'failed';
    final isCompleted = status == 'completed' || status == 'extracted';

    Color bannerColor = AppColors.surfaceMuted;
    IconData statusIcon = Icons.info_outline;
    if (isProcessing) {
      bannerColor = AppColors.infoBg;
      statusIcon = Icons.hourglass_top_rounded;
    } else if (isCompleted) {
      bannerColor = AppColors.successBg;
      statusIcon = Icons.check_circle_outline;
    } else if (isFailed) {
      bannerColor = AppColors.errorBg;
      statusIcon = Icons.error_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: bannerColor,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isProcessing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                  ),
                )
              else
                Icon(statusIcon,
                    size: 20,
                    color: isCompleted
                        ? AppColors.success
                        : (isFailed ? AppColors.error : AppColors.primary)),
              const SizedBox(width: 10),
              Text(
                'Status: ${status.toUpperCase()}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isCompleted
                      ? AppColors.success
                      : (isFailed ? AppColors.error : AppColors.textPrimary),
                ),
              ),
              const Spacer(),
              Text(
                'Progress: $progress%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              if (isFailed) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _handleReprocess,
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('Retry Ingestion', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ],
          ),
          if (liveStatus?.error != null) ...[
            const SizedBox(height: 6),
            Text(
              liveStatus!.error!,
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ],
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress / 100.0,
              backgroundColor: AppColors.borderSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted
                    ? AppColors.success
                    : (isFailed ? AppColors.error : AppColors.primary),
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrPagesView(List<DocumentPageModel> pages) {
    if (pages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.text_snippet_outlined, size: 48, color: AppColors.textTertiary),
            SizedBox(height: 12),
            Text(
              'No OCR text pages available yet.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 4),
            Text(
              'Extracted text will appear here once the ingestion pipeline completes.',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final currentPage = _selectedPageIndex < pages.length ? pages[_selectedPageIndex] : pages.first;

    return Column(
      children: [
        // Page Selector Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surface,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous Page',
                onPressed: _selectedPageIndex > 0
                    ? () => setState(() => _selectedPageIndex--)
                    : null,
              ),
              Text(
                'Page ${_selectedPageIndex + 1} of ${pages.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next Page',
                onPressed: _selectedPageIndex < pages.length - 1
                    ? () => setState(() => _selectedPageIndex++)
                    : null,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: 'Copy Page Text',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: currentPage.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Page text copied to clipboard.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Text Content
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                currentPage.text,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.6,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataView(DocumentModel doc, DocumentMetadataModel? metadata) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Edit action bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Document Intelligence & Metadata',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final updated = await DocumentMetadataDialog.show(
                    context,
                    documentId: doc.id,
                    document: doc,
                    onSave: (req) => ref
                        .read(documentDetailNotifierProvider.notifier)
                        .updateMetadata(doc.id, req),
                  );
                  if (updated == true && mounted) {
                    ref
                        .read(documentDetailNotifierProvider.notifier)
                        .loadDocument(doc.id);
                  }
                },
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit Metadata'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Technical Metadata Card
          _buildInfoCard(
            title: 'Technical Properties',
            icon: Icons.settings_outlined,
            items: [
              MapEntry('Original Filename', doc.originalName),
              MapEntry('File Type', doc.fileType.toUpperCase()),
              MapEntry('File Size', doc.formattedFileSize),
              MapEntry('Total Pages', doc.totalPages.toString()),
              MapEntry('SHA-256 Hash', doc.hash ?? 'Not computed'),
              MapEntry('Uploaded At', doc.uploadedAt ?? 'Unknown'),
              MapEntry('Processed At', metadata?.processedAt ?? 'Pending'),
            ],
          ),
          const SizedBox(height: 16),

          // Classification & Governance Card
          _buildInfoCard(
            title: 'Classification & Governance',
            icon: Icons.shield_outlined,
            items: [
              MapEntry('Category', doc.category),
              MapEntry('Classification', doc.classification.toUpperCase()),
              MapEntry('Retention Date', metadata?.retentionDate ?? '2031-09-07'),
              MapEntry('User ID', doc.userId ?? 'Unknown'),
            ],
          ),
          const SizedBox(height: 16),

          // GIS & Mine Coordinates Card
          _buildInfoCard(
            title: 'GIS & Geographic Coordinates',
            icon: Icons.location_on_outlined,
            items: [
              MapEntry('Latitude', doc.gisMetadata?.latitude?.toString() ?? 'Unset'),
              MapEntry('Longitude', doc.gisMetadata?.longitude?.toString() ?? 'Unset'),
              MapEntry('Elevation',
                  doc.gisMetadata?.elevation != null ? '${doc.gisMetadata!.elevation} m' : 'Unset'),
              MapEntry('Mine Code', doc.gisMetadata?.mineCode ?? 'Unset'),
              MapEntry('Region', doc.gisMetadata?.region ?? 'Unset'),
            ],
          ),
          const SizedBox(height: 16),

          // Named Entities (if any)
          if (doc.entities != null && doc.entities!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bubble_chart_outlined,
                          color: AppColors.accentTeal, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Extracted Named Entities',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: doc.entities!.map((e) {
                      return Chip(
                        backgroundColor: AppColors.surfaceMuted,
                        avatar: CircleAvatar(
                          backgroundColor: AppColors.accentTeal.withValues(alpha: 0.15),
                          child: Text(
                            e.type[0],
                            style: const TextStyle(
                                color: AppColors.accentTeal,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        label: Text(
                          '${e.name} (${e.type})',
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppColors.border),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<MapEntry<String, String>> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
