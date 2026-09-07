import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants/app_constants.dart';

/// Cross-platform file operations for Android, iOS, and Windows Desktop.
class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  /// Pick a single document file supported by MineIntel AI ingestion.
  Future<File?> pickDocument() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.supportedDocumentExtensions,
    );

    if (files.isNotEmpty && files.first.path != null) {
      return File(files.first.path!);
    }
    return null;
  }

  /// Pick multiple documents for batch upload.
  Future<List<File>> pickBatchDocuments() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.supportedDocumentExtensions,
    );

    return files
        .where((f) => f.path != null)
        .map((f) => File(f.path!))
        .toList();
  }

  /// Resolve platform-appropriate documents directory for saving reports/downloads.
  Future<Directory> getStorageDirectory() async {
    if (Platform.isAndroid) {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) return externalDir;
    }
    return await getApplicationDocumentsDirectory();
  }

  /// Open downloaded file in the native system viewer (PDF, Word, CSV, etc.).
  Future<OpenResult> openFile(String filePath) async {
    return await OpenFilex.open(filePath);
  }
}
