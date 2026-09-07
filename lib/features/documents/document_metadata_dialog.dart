import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../models/document_model.dart';
import '../../theme/app_colors.dart';

/// Modal dialog for editing technical & GIS document metadata (PUT /documents/:id/metadata).
class DocumentMetadataDialog extends StatefulWidget {
  final String documentId;
  final DocumentModel document;
  final Future<bool> Function(DocumentMetadataUpdateRequest request) onSave;

  const DocumentMetadataDialog({
    super.key,
    required this.documentId,
    required this.document,
    required this.onSave,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String documentId,
    required DocumentModel document,
    required Future<bool> Function(DocumentMetadataUpdateRequest request) onSave,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DocumentMetadataDialog(
        documentId: documentId,
        document: document,
        onSave: onSave,
      ),
    );
  }

  @override
  State<DocumentMetadataDialog> createState() => _DocumentMetadataDialogState();
}

class _DocumentMetadataDialogState extends State<DocumentMetadataDialog> {
  late String _category;
  late String _classification;
  late final TextEditingController _latController;
  late final TextEditingController _lonController;
  late final TextEditingController _elevationController;
  late final TextEditingController _mineCodeController;
  late final TextEditingController _retentionController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _category = widget.document.category;
    if (!AppConstants.categories.contains(_category)) {
      _category = AppConstants.categories.first;
    }

    _classification = widget.document.classification;
    if (!AppConstants.classifications.contains(_classification)) {
      _classification = AppConstants.classifications[1]; // internal
    }

    final gis = widget.document.gisMetadata;
    _latController = TextEditingController(text: gis?.latitude?.toString() ?? '');
    _lonController = TextEditingController(text: gis?.longitude?.toString() ?? '');
    _elevationController = TextEditingController(text: gis?.elevation?.toString() ?? '');
    _mineCodeController = TextEditingController(text: gis?.mineCode ?? '');
    _retentionController = TextEditingController(text: '2031-09-07');
  }

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    _elevationController.dispose();
    _mineCodeController.dispose();
    _retentionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());
    final elevation = double.tryParse(_elevationController.text.trim());
    final mineCode = _mineCodeController.text.trim();
    final retention = _retentionController.text.trim();

    final req = DocumentMetadataUpdateRequest(
      category: _category,
      classification: _classification,
      gisMetadata: GisMetadata(
        latitude: lat,
        longitude: lon,
        elevation: elevation,
        mineCode: mineCode.isNotEmpty ? mineCode : null,
        region: widget.document.gisMetadata?.region,
      ),
      retentionDate: retention.isNotEmpty ? retention : null,
    );

    try {
      final success = await widget.onSave(req);
      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Row(
                children: [
                  const Icon(Icons.edit_note, color: AppColors.primary, size: 26),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Edit Document Metadata',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category dropdown
              const Text(
                'Document Category',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    items: AppConstants.categories.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c, style: const TextStyle(color: AppColors.textPrimary)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Classification dropdown
              const Text(
                'Security Classification',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _classification,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    items: AppConstants.classifications.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c.toUpperCase(),
                            style: const TextStyle(color: AppColors.textPrimary)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _classification = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // GIS Section Header
              const Row(
                children: [
                  Icon(Icons.location_on_outlined, color: AppColors.accentTeal, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Geographic & Mine Coordinates (GIS)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentTeal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Latitude & Longitude
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Latitude',
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _lonController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Longitude',
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Elevation & Mine Code
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _elevationController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Elevation (m)',
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _mineCodeController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Mine Code (e.g. ECL-04)',
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Retention Date
              TextField(
                controller: _retentionController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Statutory Retention Date (YYYY-MM-DD)',
                  labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  filled: true,
                  fillColor: AppColors.surfaceMuted,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ],

              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(_isSaving ? 'Saving...' : 'Update Metadata'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
