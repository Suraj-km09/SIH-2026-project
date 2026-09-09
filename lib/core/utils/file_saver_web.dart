// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

/// Web implementation triggering native browser download via Blob and AnchorElement.
Future<String?> saveAndLaunchFile(
  Uint8List bytes,
  String fileName, {
  String? mimeType,
}) async {
  final effectiveMime = mimeType ?? _lookupMimeType(fileName);
  final blob = html.Blob([bytes], effectiveMime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);

  return fileName;
}

String _lookupMimeType(String fileName) {
  final ext = fileName.split('.').last.toLowerCase();
  switch (ext) {
    case 'pdf':
      return 'application/pdf';
    case 'docx':
    case 'doc':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'csv':
      return 'text/csv;charset=utf-8';
    case 'json':
      return 'application/json;charset=utf-8';
    case 'txt':
    case 'md':
      return 'text/plain;charset=utf-8';
    default:
      return 'application/octet-stream';
  }
}
