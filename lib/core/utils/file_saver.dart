import 'dart:convert';
import 'dart:typed_data';

import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_io.dart' as saver;

/// Unified cross-platform file saving and browser download utility.
class FileSaver {
  FileSaver._();

  /// Saves or triggers browser download of raw binary bytes.
  static Future<String?> saveAndLaunchFile(
    Uint8List bytes,
    String fileName, {
    String? mimeType,
  }) {
    return saver.saveAndLaunchFile(bytes, fileName, mimeType: mimeType);
  }

  /// Saves or triggers browser download of UTF-8 text content (CSV, JSON, Markdown).
  static Future<String?> saveAndLaunchText(
    String content,
    String fileName, {
    String? mimeType,
  }) {
    final bytes = Uint8List.fromList(utf8.encode(content));
    return saver.saveAndLaunchFile(bytes, fileName, mimeType: mimeType);
  }
}
