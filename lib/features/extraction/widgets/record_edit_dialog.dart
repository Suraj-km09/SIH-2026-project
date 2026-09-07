import 'package:flutter/material.dart';
import '../../../models/extracted_record_model.dart';
import '../../../theme/app_colors.dart';

/// Modal dialog for editing an extracted record with audit history inspection.
class RecordEditDialog extends StatefulWidget {
  final ExtractedRecordModel record;
  final Future<bool> Function(ExtractedRecordUpdateRequest request) onSave;

  const RecordEditDialog({
    super.key,
    required this.record,
    required this.onSave,
  });

  static Future<bool?> show(
    BuildContext context, {
    required ExtractedRecordModel record,
    required Future<bool> Function(ExtractedRecordUpdateRequest request) onSave,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => RecordEditDialog(record: record, onSave: onSave),
    );
  }

  @override
  State<RecordEditDialog> createState() => _RecordEditDialogState();
}

class _RecordEditDialogState extends State<RecordEditDialog> {
  late final TextEditingController _paramController;
  late final TextEditingController _valueController;
  late final TextEditingController _unitController;
  late final TextEditingController _periodController;
  late final TextEditingController _mineController;
  late final TextEditingController _subsidiaryController;
  late String _status;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _paramController = TextEditingController(text: widget.record.parameter);
    _valueController = TextEditingController(text: widget.record.value);
    _unitController = TextEditingController(text: widget.record.unit ?? '');
    _periodController = TextEditingController(text: widget.record.period ?? '');
    _mineController = TextEditingController(text: widget.record.mineName ?? '');
    _subsidiaryController = TextEditingController(text: widget.record.subsidiary ?? '');
    _status = widget.record.status;
  }

  @override
  void dispose() {
    _paramController.dispose();
    _valueController.dispose();
    _unitController.dispose();
    _periodController.dispose();
    _mineController.dispose();
    _subsidiaryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final req = ExtractedRecordUpdateRequest(
      parameter: _paramController.text.trim(),
      value: _valueController.text.trim(),
      unit: _unitController.text.trim().isNotEmpty ? _unitController.text.trim() : null,
      period: _periodController.text.trim().isNotEmpty ? _periodController.text.trim() : null,
      mineName: _mineController.text.trim().isNotEmpty ? _mineController.text.trim() : null,
      subsidiary:
          _subsidiaryController.text.trim().isNotEmpty ? _subsidiaryController.text.trim() : null,
      status: _status,
    );

    try {
      final success = await widget.onSave(req);
      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
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
                    const Icon(Icons.edit_note, color: AppColors.primary, size: 26),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Edit Extracted Parameter',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // Parameter Name
              TextField(
                controller: _paramController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Parameter Name',
                  filled: true,
                  fillColor: AppColors.surfaceMuted,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),

              // Value & Unit
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _valueController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Extracted Value',
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _unitController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Unit (e.g. Tonnes)',
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Period & Mine Name
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _periodController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Reporting Period',
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _mineController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Mine Name',
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Subsidiary & Status
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subsidiaryController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Subsidiary (e.g. ECL)',
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _status,
                          isExpanded: true,
                          dropdownColor: AppColors.surface,
                          items: const [
                            DropdownMenuItem(value: 'pending', child: Text('PENDING')),
                            DropdownMenuItem(value: 'approved', child: Text('APPROVED')),
                            DropdownMenuItem(value: 'rejected', child: Text('REJECTED')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _status = val);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Source text quote (if available)
              if (widget.record.sourceText != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ground Truth Source Text (Page ${1}):',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"${widget.record.sourceText}"',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Edit History Audit Log
              if (widget.record.editHistory.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Audit Edit History',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: widget.record.editHistory.map((h) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.history, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${h.field}: "${h.oldValue}" → "${h.newValue}" by ${h.editedBy ?? 'reviewer'}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
              ],

              const SizedBox(height: 24),

              // Actions
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
                    child: Text(_isSaving ? 'Saving...' : 'Save Changes'),
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
