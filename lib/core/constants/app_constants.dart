/// Domain constants for MineIntel AI derived from backend schemas and RBAC matrix.
class AppConstants {
  AppConstants._();

  // Application Info
  static const String appName = 'MineIntel AI';
  static const String appSubtitle = 'Mining Intelligence & Automated Compliance Platform';
  static const String appVersion = '1.0.0';

  // RBAC Roles
  static const String roleUser = 'user';
  static const String roleReviewer = 'reviewer';
  static const String roleAdmin = 'admin';

  // Document Processing Statuses
  static const String statusPending = 'pending';
  static const String statusQueued = 'queued';
  static const String statusProcessing = 'processing';
  static const String statusCompleted = 'completed';
  static const String statusFailed = 'failed';
  static const String statusExtracted = 'extracted';

  // Report Governance Statuses
  static const String reportDraft = 'draft';
  static const String reportReview = 'review';
  static const String reportApproved = 'approved';
  static const String reportRejected = 'rejected';

  // Validation Severities
  static const String severityInfo = 'info';
  static const String severityWarning = 'warning';
  static const String severityError = 'error';
  static const String severityCritical = 'critical';

  // Supported Ingestion File Formats
  static const List<String> supportedDocumentExtensions = [
    'pdf',
    'docx',
    'xlsx',
    'csv',
    'pptx',
    'png',
    'jpg',
    'jpeg',
    'tiff',
  ];

  // Document Security Classifications
  static const List<String> classifications = [
    'public',
    'internal',
    'confidential',
    'restricted',
  ];

  // Document Categories
  static const List<String> categories = [
    'Production Report',
    'Statutory Return',
    'Environmental Audit',
    'Safety & DGMS Directive',
    'Geological Log',
    'Weighbridge Dispatch',
    'General Operations',
  ];
}
