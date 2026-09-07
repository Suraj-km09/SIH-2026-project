import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/document_model.dart';
import '../../services/file_service.dart';
import '../../state/document_state.dart';
import '../../theme/app_colors.dart';

/// Modal dialog for uploading documents with 50MB limit check,
/// progress visualization, and SHA-256 duplicate conflict handling.
class DocumentUploadDialog extends ConsumerStatefulWidget {
  final void Function(DocumentModel document)? onUploadSuccess;

  const DocumentUploadDialog({
    super.key,
    this.onUploadSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    void Function(DocumentModel document)? onUploadSuccess,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DocumentUploadDialog(onUploadSuccess: onUploadSuccess),
    );
  }

  @override
  ConsumerState<DocumentUploadDialog> createState() => _DocumentUploadDialogState();
}

class _DocumentUploadDialogState extends ConsumerState<DocumentUploadDialog> {
  File? _selectedFile;
  int? _selectedFileSize;
  String? _clientValidationError;
  bool _isPicking = false;

  static const int _maxBytes = 50 * 1024 * 1024; // 50 MB

  Future<void> _pickFile() async {
    setState(() {
      _isPicking = true;
      _clientValidationError = null;
    });

    try {
      final file = await FileService().pickDocument();
      if (file != null && mounted) {
        final size = await file.length();
        if (size > _maxBytes) {
          setState(() {
            _selectedFile = null;
            _selectedFileSize = null;
            _clientValidationError =
                'Selected file exceeds the 50 MB limit (${(size / (1024 * 1024)).toStringAsFixed(1)} MB).';
          });
        } else {
          setState(() {
            _selectedFile = file;
            _selectedFileSize = size;
            _clientValidationError = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _clientValidationError = 'Failed to pick file: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }

  Future<void> _startUpload() async {
    if (_selectedFile == null) return;

    final notifier = ref.read(documentProcessingNotifierProvider.notifier);
    final uploadedDoc = await notifier.uploadDocument(_selectedFile!);

    if (uploadedDoc != null && mounted) {
      widget.onUploadSuccess?.call(uploadedDoc);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document "${uploadedDoc.originalName}" queued for processing.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final procState = ref.watch(documentProcessingNotifierProvider);
    final isUploading = procState.isUploading;
    final progress = procState.uploadProgress;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.upload_file_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Mining Document',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Max size: 50 MB | Ingestion & OCR pipeline',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isUploading)
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Supported formats tag bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                'Supported: ${AppConstants.supportedDocumentExtensions.map((e) => e.toUpperCase()).join(' • ')}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            // Picked File Card or Picker Trigger
            if (_selectedFile == null)
              InkWell(
                onTap: (isUploading || _isPicking) ? null : _pickFile,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentTeal.withValues(alpha: 0.4),
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 40,
                        color: _isPicking ? AppColors.textTertiary : AppColors.accentTeal,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isPicking ? 'Opening file picker...' : 'Click to select a document file',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Up to 50 MB per file',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description, color: AppColors.accentTeal, size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFile!.path.split(RegExp(r'[/\\]')).last,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedFileSize != null
                                ? 'Size: ${_formatBytes(_selectedFileSize!)}'
                                : '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isUploading)
                      IconButton(
                        icon: const Icon(Icons.change_circle_outlined,
                            color: AppColors.textSecondary),
                        tooltip: 'Change file',
                        onPressed: _pickFile,
                      ),
                  ],
                ),
              ),

            // Client Validation Error
            if (_clientValidationError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.errorBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _clientValidationError!,
                        style: const TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 409 Duplicate Conflict Alert
            if (procState.isDuplicateConflict) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warningBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Duplicate Document Detected (409)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      procState.conflictMessage ??
                          'A document with this SHA-256 checksum has already been uploaded to MineIntel AI. Deduplication prevents redundant storage.',
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],

            // General Upload Error
            if (procState.errorMessage != null && !procState.isDuplicateConflict) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.errorBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        procState.errorMessage!,
                        style: const TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Upload Progress Bar
            if (isUploading) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Uploading document...',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      backgroundColor: AppColors.surfaceMuted,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: (_selectedFile != null && !isUploading) ? _startUpload : null,
                  icon: isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: Text(isUploading ? 'Uploading...' : 'Start Ingestion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}
