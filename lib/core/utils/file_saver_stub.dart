import 'dart:typed_data';

/// Stub implementation for platforms without html or io libraries.
Future<String?> saveAndLaunchFile(
  Uint8List bytes,
  String fileName, {
  String? mimeType,
}) async {
  throw UnsupportedError('FileSaver is not supported on this platform.');
}
