import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/env_config.dart';
import '../../core/constants/app_constants.dart';
import '../../state/auth_state.dart';
import '../../state/notification_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/badges/status_chip.dart';
import '../../widgets/dialogs/app_dialog.dart';
import '../../widgets/layout/responsive_layout.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../analytics/analytics_screen.dart';
import '../audit/audit_trail_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../documents/document_list_screen.dart';
import '../extraction/extraction_screen.dart';
import '../gis/gis_map_screen.dart';
import '../intelligence_topics/intelligence_topics_screen.dart';
import '../knowledge_base/knowledge_base_screen.dart';
import '../notifications/notification_center_screen.dart';
import '../reports/reports_list_screen.dart';
import '../reviews/review_queue_screen.dart';
import '../settings/settings_screen.dart';
import '../validation/validation_screen.dart';
import 'module_placeholder.dart';

/// Main Authenticated Application Shell for MineIntel AI.
/// Hosts responsive navigation across Desktop (Persistent Sidebar),
/// Tablet (Adaptive Rail), and Mobile (Bottom Bar + More Sheet).
/// Strictly enforces Role-Based Access Control: hides Review Queue from standard users,
/// and hides Admin Console from non-administrators.
class MainShell extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onNavigate(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _confirmLogout() async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Confirm Log Out',
      message: 'Are you sure you want to end your current mining intelligence session?',
      confirmText: 'Log Out',
      cancelText: 'Stay Logged In',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final user = authState.user;
    final role = user?.role ?? AppConstants.roleUser;
    final username = user?.username ?? 'Mining Specialist';

    // Verify role permission on active index (prevent unauthorized view if role changed)
    if (_currentIndex == 12 && role == AppConstants.roleUser) {
      _currentIndex = 0; // Redirect from Review Queue to Dashboard
    }
    if (_currentIndex == 14 && role != AppConstants.roleAdmin) {
      _currentIndex = 0; // Redirect from Admin Console to Dashboard
    }

    final moduleData = _getModuleData(_currentIndex);

    return ResponsiveScaffold(
      selectedIndex: _currentIndex,
      onDestinationSelected: _onNavigate,
      title: moduleData.title,
      username: username,
      userRole: role,
      actions: _buildResponsiveActions(context, unreadCount),
      body: _buildActiveScreen(_currentIndex),
    );
  }

  List<Widget> _buildResponsiveActions(BuildContext context, int unreadCount) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 520;

    final notifBtn = IconButton(
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text('$unreadCount'),
        backgroundColor: AppColors.accentBlue,
        child: const Icon(Icons.notifications_none_outlined, size: 22),
      ),
      tooltip: 'Notification Center',
      onPressed: () => _onNavigate(15),
    );

    if (isCompact) {
      return [
        notifBtn,
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 22),
          tooltip: 'Quick Actions',
          onSelected: (val) {
            if (val == 'settings') {
              _onNavigate(16);
            } else if (val == 'audit') {
              _onNavigate(13);
            } else if (val == 'logout') {
              _confirmLogout();
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Profile & Settings'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'audit',
              child: Row(
                children: [
                  Icon(Icons.history_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Audit Trail'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_outlined, size: 18, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Log Out', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ];
    }

    return [
      StatusChip(
        status: EnvConfig.useMockData ? 'mock_mode' : 'active',
      ),
      const SizedBox(width: 12),
      notifBtn,
      IconButton(
        icon: const Icon(Icons.account_circle_outlined, size: 22),
        tooltip: 'Profile & Settings',
        onPressed: () => _onNavigate(16),
      ),
      IconButton(
        icon: const Icon(Icons.logout_outlined, size: 22, color: AppColors.error),
        tooltip: 'Log Out',
        onPressed: _confirmLogout,
      ),
      const SizedBox(width: 8),
    ];
  }

  Widget _buildActiveScreen(int index) {
    if (index == 0) {
      return const DashboardScreen();
    }
    if (index == 2) {
      return const DocumentListScreen();
    }
    if (index == 3) {
      return const ExtractionScreen();
    }
    if (index == 4) {
      return const ValidationScreen();
    }
    if (index == 5) {
      return const AiAssistantScreen();
    }
    if (index == 6) {
      return const KnowledgeBaseScreen();
    }
    if (index == 7) {
      return const AnalyticsScreen();
    }
    if (index == 8) {
      return const GisMapScreen();
    }
    if (index == 9) {
      return const IntelligenceTopicsScreen();
    }
    if (index == 11) {
      return const ReportsListScreen();
    }
    if (index == 12) {
      return const ReviewQueueScreen();
    }
    if (index == 13) {
      return const AuditTrailScreen();
    }
    if (index == 15) {
      return const NotificationCenterScreen();
    }
    if (index == 16) {
      return const SettingsScreen();
    }

    final data = _getModuleData(index);
    return ModulePlaceholder(
      title: data.title,
      description: data.description,
      icon: data.icon,
      targetPhase: data.targetPhase,
      plannedFeatures: data.plannedFeatures,
    );
  }

  _ModuleInfo _getModuleData(int index) {
    switch (index) {
      case 0:
        return const _ModuleInfo(
          title: 'Executive Dashboard',
          description:
              'High-level mining operational metrics, active document pipeline throughput, compliance alert cards, and anomaly summaries.',
          icon: Icons.dashboard_outlined,
          targetPhase: 'Phase 5 Baseline',
          plannedFeatures: [
            'Total processed documents & overall data quality score',
            'Pending HITL extraction items and active report drafts',
            'Urgent production variance and safety alerts',
            'Recent documents timeline with direct navigation shortcuts',
          ],
        );
      case 1:
        return const _ModuleInfo(
          title: 'Command Centre',
          description:
              'Real-time ingestion pipeline telemetry, asynchronous processing job monitor, microservice health gauges, and attention queues.',
          icon: Icons.terminal_outlined,
          targetPhase: 'Phase 5 Telemetry',
          plannedFeatures: [
            '4-step pipeline progress monitor (Ingest -> OCR -> Extract -> Vector Index)',
            'Microservices health matrix (Express backend, MongoDB, Gemini LLM)',
            'Attention queue for failed or high-concurrency documents',
            'Real-time polling with safe backoff constraints',
          ],
        );
      case 2:
        return const _ModuleInfo(
          title: 'Document Management',
          description:
              'Multi-format file upload (PDF, DOCX, XLSX, CSV, Images), SHA-256 deduplication, page-by-page OCR viewer, and GIS metadata editor.',
          icon: Icons.folder_outlined,
          targetPhase: 'Phase 6 Integration',
          plannedFeatures: [
            'Single and batch document upload with file picker',
            'SHA-256 conflict detection (409 Conflict handling)',
            'Page-by-page OCR text inspection',
            'Geographic coordinates (Latitude, Longitude) and category tagging',
          ],
        );
      case 3:
        return const _ModuleInfo(
          title: 'Data Extraction & HITL',
          description:
              'Gemini AI extraction of tabular parameters, Human-in-the-Loop review, inline value editing, and bulk verification.',
          icon: Icons.table_chart_outlined,
          targetPhase: 'Phase 7 AI Pipelines',
          plannedFeatures: [
            'Extracted parameter data grid (Value, Unit, Period, Mine Name)',
            'AI confidence score badge per record',
            'Inline record editing with immutable audit history',
            'Bulk approval and rejection workflows',
          ],
        );
      case 4:
        return const _ModuleInfo(
          title: 'Validation & Quality Engine',
          description:
              '8-rule algorithmic validation engine, dynamic quality score dial, anomaly issue resolution, and batch quality checks.',
          icon: Icons.rule_outlined,
          targetPhase: 'Phase 8 Rules Engine',
          plannedFeatures: [
            'Dynamic Quality Score calculation dial',
            'Rule violation cards (unit mismatch, duplicate, suspicious values)',
            'Issue resolution dialog with corrective value inputs',
            'Batch document verification and quality clearance',
          ],
        );
      case 5:
        return const _ModuleInfo(
          title: 'AI Conversational Assistant',
          description:
              'Hybrid semantic/analytical mining assistant with strict RAG evidence citations, calculation verification, and conversation history.',
          icon: Icons.auto_awesome_outlined,
          targetPhase: 'Phase 9 RAG Intelligence',
          plannedFeatures: [
            'Operational and statutory compliance Q&A chat interface',
            'Direct clickable document and page citations',
            'Mathematical variance calculation explanations',
            'Conversation session history management',
          ],
        );
      case 6:
        return const _ModuleInfo(
          title: 'Knowledge Base & Search',
          description:
              'Vector embeddings search, document indexing status, and semantic exploration across multi-year statutory mining archives.',
          icon: Icons.travel_explore_outlined,
          targetPhase: 'Phase 9 Vector Storage',
          plannedFeatures: [
            'Semantic vector similarity search across all parsed pages',
            'Document chunk index inspection',
            'Index rebuild and deletion management',
          ],
        );
      case 7:
        return const _ModuleInfo(
          title: 'Mining Analytics & Production',
          description:
              'Production variance analytics, stripping ratios, dispatch trends, and 3-sigma statistical anomaly detection.',
          icon: Icons.trending_up_outlined,
          targetPhase: 'Phase 10 Analytics',
          plannedFeatures: [
            'Monthly and annual mineral production charts',
            'Overburden removal and stripping ratio trends',
            '3-sigma statistical outlier detection on declared tonnages',
            'Interactive date range filters',
          ],
        );
      case 8:
        return const _ModuleInfo(
          title: 'GIS Spatial Map',
          description:
              'Interactive geospatial map displaying mining lease boundaries, production clusters, dispatch hubs, and spatial document links.',
          icon: Icons.map_outlined,
          targetPhase: 'Phase 10 Geospatial',
          plannedFeatures: [
            'Interactive mine lease pinpoints and boundary polygons',
            'Spatial filtering by subsidiary and region',
            'Geotagged document and statutory report attachments',
          ],
        );
      case 9:
        return const _ModuleInfo(
          title: 'Topics & Taxonomy',
          description:
              'Topic modeling, co-occurrence cluster discovery, emerging statutory themes, and entity extraction.',
          icon: Icons.hub_outlined,
          targetPhase: 'Phase 11 Taxonomy',
          plannedFeatures: [
            'Mining topic clusters (Environment, Safety, Production, Lease)',
            'Co-occurrence graph visualization',
            'Emerging statutory issue alerts',
          ],
        );
      case 10:
        return const _ModuleInfo(
          title: 'Autonomous Multi-Agent Orchestrator',
          description:
              'Specialized multi-agent system coordinating document ingestion, extraction verification, validation checks, and statutory reporting.',
          icon: Icons.smart_toy_outlined,
          targetPhase: 'Phase 11 Agents',
          plannedFeatures: [
            'Intent classification and autonomous task delegation',
            'Agent task execution logs and concurrency locking',
            'Multi-step compliance workflow automation',
          ],
        );
      case 11:
        return const _ModuleInfo(
          title: 'Statutory Reports',
          description:
              'Draft, review, approve, and export formal statutory mining reports in English and Hindi with citation evidence.',
          icon: Icons.description_outlined,
          targetPhase: 'Phase 12 Reporting',
          plannedFeatures: [
            'Statutory report generator with RAG synthesis',
            'Version history and diff comparison viewer',
            'Evidence drawer linking citations to source pages',
            'Multi-format export (PDF, Word DOCX, CSV, JSON)',
          ],
        );
      case 12:
        return const _ModuleInfo(
          title: 'Review Queue (Governance)',
          description:
              'Dedicated Maker-Checker evaluation portal for Reviewers and Administrators with mandatory rejection reasons.',
          icon: Icons.rate_review_outlined,
          targetPhase: 'Phase 12 Maker-Checker',
          plannedFeatures: [
            'Pending review queue table with SLA counters',
            'Side-by-side evidence inspection panel',
            'Administrator approval barrier (Admin only)',
            'Reviewer rejection workflow with mandatory justification notes',
          ],
        );
      case 13:
        return const _ModuleInfo(
          title: 'Audit Trail & Provenance',
          description:
              'Tamper-evident audit log tracking every user action, report approval, record edit, and document mutation with CSV export.',
          icon: Icons.history_outlined,
          targetPhase: 'Phase 13 Compliance',
          plannedFeatures: [
            'Immutable chronological audit event table',
            'User, document, and report filter dropdowns',
            'Full event JSON detail modal',
            'Statutory compliance CSV export',
          ],
        );
      case 14:
        return const _ModuleInfo(
          title: 'Admin Console & Governance',
          description:
              'User governance, RBAC role assignment (User, Reviewer), user deactivation, and system infrastructure health monitors.',
          icon: Icons.admin_panel_settings_outlined,
          targetPhase: 'Phase 13 Administration',
          plannedFeatures: [
            'User management table (list, change role, delete)',
            'Self-deletion prevention and Admin protection barriers',
            'System health monitor (MongoDB Atlas, Node backend, AI latency)',
            'Aggregate platform statistics',
          ],
        );
      case 15:
        return const _ModuleInfo(
          title: 'Notification Center',
          description:
              'In-app alerts for ingestion completions, critical validation errors, report review updates, and system announcements.',
          icon: Icons.notifications_none_outlined,
          targetPhase: 'Phase 14 Alerts',
          plannedFeatures: [
            'Real-time notifications with priority badges',
            'Mark single / Mark all read endpoints',
            'Deep-links to relevant document or report',
          ],
        );
      case 17:
        return const _ModuleInfo(
          title: 'Help & Documentation',
          description:
              'Interactive FAQ search, statutory compliance guidelines, system documentation, and administrator contact directory.',
          icon: Icons.help_outline,
          targetPhase: 'Phase 14 Support',
          plannedFeatures: [
            'Categorized FAQ search engine',
            'Mining statutory guidelines (DGMS, IBM, MCDR)',
            'System administrator contact directory',
          ],
        );
      default:
        return const _ModuleInfo(
          title: 'MineIntel Module',
          description: 'Mining operational module in development.',
          icon: Icons.dashboard_outlined,
          targetPhase: 'Upcoming',
          plannedFeatures: ['Under active development'],
        );
    }
  }
}

class _ModuleInfo {
  final String title;
  final String description;
  final IconData icon;
  final String targetPhase;
  final List<String> plannedFeatures;

  const _ModuleInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.targetPhase,
    required this.plannedFeatures,
  });
}
