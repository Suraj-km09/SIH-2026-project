import 'package:intl/intl.dart';

/// Formatting helpers for data tables, metric cards, and reports.
class Formatters {
  Formatters._();

  /// Format file size from bytes to human-readable string.
  static String formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// Format ISO 8601 date string to human-friendly format (e.g., 'Jul 20, 2026').
  static String formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  /// Format date with time (e.g., 'Jul 20, 2026 14:30').
  static String formatDateTime(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('MMM dd, yyyy HH:mm').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  /// Format large numbers with comma separators (e.g. 1,425,000).
  static String formatNumber(num? value) {
    if (value == null) return '0';
    return NumberFormat('#,##0').format(value);
  }

  /// Format compact numbers (e.g., 35K, 2.1M).
  static String formatCompactNumber(num? value) {
    if (value == null) return '0';
    return NumberFormat.compact().format(value);
  }

  /// Format percentage string (e.g. 94.2%).
  static String formatPercentage(double? ratio, [int decimals = 1]) {
    if (ratio == null) return '0%';
    final pct = ratio <= 1.0 ? ratio * 100 : ratio;
    return '${pct.toStringAsFixed(decimals)}%';
  }
}
