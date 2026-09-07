/// Master API endpoint definitions for MineIntel AI.
/// Source of Truth: OpenAPI 3.0.3 Specification & API_DOCUMENTATION.md.
/// Protocol: REST API v1 (/api/v1).
class ApiEndpoints {
  ApiEndpoints._();

  // Module 01: System Health & Info
  static const String health = '/health';

  // Module 02: Authentication & User Profile
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';
  static const String authProfile = '/auth/profile';
  static const String authChangePassword = '/auth/change-password';
  static const String authRefresh = '/auth/refresh';

  // Module 03: Administration & User Governance
  static const String adminUsers = '/admin/users';
  static String adminUserRole(String id) => '/admin/users/$id/role';
  static String adminUserDelete(String id) => '/admin/users/$id';
  static const String adminStats = '/admin/stats';
  static const String adminSystemHealth = '/admin/system-health';

  // Module 04: Dashboard Analytics
  static const String dashboardOverview = '/dashboard/overview';
  static const String dashboardKpis = '/dashboard/kpis';
  static const String dashboardActivity = '/dashboard/activity';
  static const String dashboardAlerts = '/dashboard/alerts';
  static const String dashboardRecentDocuments = '/dashboard/recent-documents';

  // Module 05: Command Centre
  static const String commandCentreOverview = '/command-centre/overview';
  static const String commandCentrePipeline = '/command-centre/pipeline';
  static const String commandCentreStatus = '/command-centre/status';
  static const String commandCentreAttentionItems = '/command-centre/attention-items';
  static const String commandCentreActivity = '/command-centre/activity';

  // Module 06: User Settings & Preferences
  static const String settings = '/settings';
  static const String settingsLanguage = '/settings/language';
  static const String settingsAppearance = '/settings/appearance';
  static const String settingsNotifications = '/settings/notifications';

  // Module 07: Help & FAQs
  static const String help = '/help';
  static const String helpFaqs = '/help/faqs';
  static const String helpSearch = '/help/search';
  static String helpFaqDetail(String id) => '/help/faqs/$id';

  // Module 08: Document Lifecycle Management
  static const String documents = '/documents';
  static const String documentsUpload = '/documents/upload';
  static String documentDetail(String id) => '/documents/$id';
  static String documentDelete(String id) => '/documents/$id';
  static String documentDownload(String id) => '/documents/$id/download';
  static String documentMetadata(String id) => '/documents/$id/metadata';
  static String documentReprocess(String id) => '/documents/$id/reprocess';
  static String documentRetry(String id) => '/documents/$id/retry';
  static String documentStatus(String id) => '/documents/$id/status';
  static String documentValidation(String id) => '/documents/$id/validation';

  // Module 09: Data Extraction & HITL Records
  static const String extractionRun = '/extraction/run';
  static String extractionSummary(String documentId) => '/extraction/$documentId';
  static String extractionRecords(String documentId) => '/extraction/$documentId/records';
  static String extractionRecordUpdate(String documentId, String recordId) =>
      '/extraction/$documentId/records/$recordId';
  static String extractionReprocess(String documentId) => '/extraction/$documentId/reprocess';
  static String extractionRecordApprove(String id) => '/extraction/records/$id/approve';
  static String extractionRecordReject(String id) => '/extraction/records/$id/reject';
  static const String extractionBulkApprove = '/extraction/records/bulk-approve';

  // Module 10: Validation & Quality Control
  static const String validationRun = '/validation/run';
  static const String validationSummary = '/validation/summary';
  static const String validationList = '/validation';
  static String validationDocument(String documentId) => '/validation/$documentId';
  static String validationIssues(String documentId) => '/validation/$documentId/issues';
  static String validationIssueResolve(String issueId) => '/validation/issues/$issueId';
  static String validationApprove(String documentId) => '/validation/$documentId/approve';
  static String validationReview(String documentId) => '/validation/$documentId/review';

  // Module 11: Automated Reports & Review Workflow
  static const String reports = '/reports';
  static const String reportsGenerate = '/reports/generate';
  static String reportDetail(String id) => '/reports/$id';
  static String reportUpdate(String id) => '/reports/$id';
  static String reportDelete(String id) => '/reports/$id';
  static String reportSubmitReview(String id) => '/reports/$id/submit-review';
  static String reportApprove(String id) => '/reports/$id/approve';
  static String reportReject(String id) => '/reports/$id/reject';
  static String reportEvidence(String id) => '/reports/$id/evidence';
  static String reportVersionHistory(String id) => '/reports/$id/version-history';
  static String reportChanges(String id) => '/reports/$id/changes';
  static String reportExportPdf(String id) => '/reports/$id/export/pdf';
  static String reportExportDocx(String id) => '/reports/$id/export/docx';
  static String reportExportCsv(String id) => '/reports/$id/export/csv';
  static String reportExportJson(String id) => '/reports/$id/export/json';
  static String reportExport(String id) => '/reports/$id/export';

  // Module 12: Dedicated Review Governance
  static const String reviewsPending = '/reviews/pending';
  static String reviewDetail(String id) => '/reviews/$id';
  static String reviewApprove(String id) => '/reviews/$id/approve';
  static String reviewReject(String id) => '/reviews/$id/reject';

  // Module 13: Knowledge Base & Vector Indexing
  static const String knowledgeBase = '/knowledge-base';
  static const String knowledgeBaseIndex = '/knowledge-base/index';
  static const String knowledgeBaseSearch = '/knowledge-base/search';
  static String knowledgeBaseDocument(String documentId) => '/knowledge-base/$documentId';
  static String knowledgeBaseDelete(String documentId) => '/knowledge-base/$documentId';

  // Module 14: RAG Vector Engine
  static String ragIndex(String documentId) => '/rag/$documentId/index';
  static const String ragSearch = '/rag/search';

  // Module 15: AI Conversational Assistant
  static const String aiAssistantQuery = '/ai-assistant/query';
  static const String aiAssistantAsk = '/ai-assistant/ask';
  static const String aiAssistantHistory = '/ai-assistant/history';
  static String aiAssistantHistoryDetail(String id) => '/ai-assistant/history/$id';
  static String aiAssistantHistoryDelete(String id) => '/ai-assistant/history/$id';

  // Module 16: Analytics & Production Variance
  static const String analyticsOverview = '/analytics/overview';
  static const String analyticsKpis = '/analytics/kpis';
  static const String analyticsProduction = '/analytics/production';
  static const String analyticsDispatch = '/analytics/dispatch';
  static const String analyticsTrends = '/analytics/trends';
  static const String analyticsVariance = '/analytics/variance';
  static const String analyticsAnomalies = '/analytics/anomalies';

  // Module 17: Topic Discovery & Taxonomy
  static const String topics = '/topics';
  static const String topicsAnalyze = '/topics/analyze';
  static const String topicsTrends = '/topics/trends';
  static const String topicsClusters = '/topics/clusters';
  static const String topicsEntities = '/topics/entities';
  static const String topicsEmerging = '/topics/emerging';
  static const String topicsChanges = '/topics/changes';

  // Module 18: Multi-Agent Orchestrator
  static const String agentsOrchestrate = '/agents/orchestrate';

  // Module 19: Audit Trail & Provenance
  static const String audit = '/audit';
  static const String auditStats = '/audit/stats';
  static const String auditExport = '/audit/export';
  static String auditUser(String userId) => '/audit/user/$userId';
  static String auditDocument(String documentId) => '/audit/document/$documentId';
  static String auditReport(String reportId) => '/audit/report/$reportId';
  static String auditDetail(String id) => '/audit/$id';

  // Module 20: Notification Center
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationMarkRead(String id) => '/notifications/$id/read';

  // Module 21: Document Intelligence
  static const String intelligence = '/intelligence';
  static const String intelligenceAnalyze = '/intelligence/analyze';
  static const String intelligenceTrends = '/intelligence/trends';
  static const String intelligenceEntities = '/intelligence/entities';
  static const String intelligenceClusters = '/intelligence/clusters';
  static const String intelligenceSimilarity = '/intelligence/similarity';
  static const String intelligenceChanges = '/intelligence/changes';
  static String intelligenceDocumentEntities(String documentId) =>
      '/intelligence/entities/$documentId';
  static String intelligenceDocumentSimilarity(String documentId) =>
      '/intelligence/similarity/$documentId';
  static String intelligenceLinkEvidence(String documentId) =>
      '/intelligence/link-evidence/$documentId';

  // Module 22: External DMS/MIS & GIS Integration
  static const String integrationDocuments = '/integration/documents';
  static const String integrationRecords = '/integration/records';
  static const String integrationGis = '/integration/gis';
}
