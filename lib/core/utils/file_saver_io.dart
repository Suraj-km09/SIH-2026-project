import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Desktop and Mobile (Android/iOS/Windows/macOS/Linux) implementation.
Future<String?> saveAndLaunchFile(
  Uint8List bytes,
  String fileName, {
  String? mimeType,
}) async {
  Directory? dir;
  if (!kIsWeb && Platform.isAndroid) {
    dir = await getExternalStorageDirectory();
  }
  dir ??= await getApplicationDocumentsDirectory();

  final filePath = '/';
  final file = File(filePath);
  await file.writeAsBytes(bytes, flush: true);

  try {
    await OpenFilex.open(filePath);
  } catch (_) {
    // Viewer may not be available on headless/minimal systems
  }

  return filePath;
}
