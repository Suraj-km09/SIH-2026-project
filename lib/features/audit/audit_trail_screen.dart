import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/audit_model.dart';
import '../../state/audit_state.dart';
import '../../state/auth_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/status_chip.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/feedback/loading_indicator.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/layout/responsive_layout.dart';

/// Role-aware System Audit Trail & Compliance Provenance Screen.
/// Supports stats overview, multi-attribute filtering, entity-scoped drilldown
/// (user, document, report), log detail modal, and statutory CSV/JSON export.
class AuditTrailScreen extends ConsumerStatefulWidget {
  const AuditTrailScreen({super.key});

  @override
  ConsumerState<AuditTrailScreen> createState() => _AuditTrailScreenState();
}

class _AuditTrailScreenState extends ConsumerState<AuditTrailScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(auditNotifierProvider.notifier).loadStats();
      ref.read(auditNotifierProvider.notifier).loadLogs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auditState = ref.watch(auditNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isAdmin = user?.role == AppConstants.roleAdmin;

    return ResponsiveContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role-Aware Header & Export Actions
          _buildRoleHeader(context, isAdmin, auditState),
          const SizedBox(height: 16),

          // Statistics Overview Cards
          if (auditState.stats != null) ...[
            _buildStatsRow(context, auditState.stats!),
            const SizedBox(height: 16),
          ],

          // Filter & Search Toolbar
          _buildFilterToolbar(context, auditState),
          const SizedBox(height: 12),

          // Active Entity Filter Pill (if scoped to User, Document, or Report)
          if (auditState.hasEntityFilter) ...[
            _buildActiveEntityFilterPill(context, auditState),
            const SizedBox(height: 12),
          ],

          // Audit Event Log Table / List
          Expanded(
            child: auditState.isLoading && auditState.logs.isEmpty
                ? const Center(
                    child: AppLoadingIndicator(message: 'Loading audit trail...'),
                  )
                : auditState.logs.isEmpty
                    ? _buildEmptyState(context)
                    : _buildLogList(context, auditState.logs),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleHeader(
      BuildContext context, bool isAdmin, AuditState state) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isNarrow = constraints.maxWidth < 750;

        final titleWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: [
                Text(
                  'Audit Trail & Provenance',
                  style: AppTypography.headlineMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? AppColors.heroSurface
                        : AppColors.accentTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isAdmin
                        ? 'ADMINISTRATOR SCOPE'
                        : 'USER SCOPED HISTORY',
                    style: AppTypography.labelSmall.copyWith(
                      color: isAdmin
                          ? AppColors.textInverse
                          : AppColors.accentTeal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isAdmin
                  ? 'Immutable compliance log of all statutory decisions, record mutations, and pipeline jobs.'
                  : 'Activity provenance scoped to your account identity and authorized document events.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );

        final actionButtons = Row(
          mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
          children: [
            AppButton(
              text: 'Filter by Entity',
              icon: Icons.filter_alt_outlined,
              variant: AppButtonVariant.outline,
              height: 38,
              onPressed: () => _showEntityFilterDialog(context),
            ),
            const SizedBox(width: 8),
            AppButton(
              text: state.isExporting ? 'Exporting...' : 'Export Logs',
              icon: Icons.download_outlined,
              height: 38,
              isLoading: state.isExporting,
              onPressed: () => _showExportDialog(context),
            ),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget,
              const SizedBox(height: 12),
              actionButtons,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleWidget),
            const SizedBox(width: 16),
            actionButtons,
          ],
        );
      },
    );
  }

  Widget _buildStatsRow(BuildContext context, AuditStats stats) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isNarrow = constraints.maxWidth < 650;
        final cards = [
          _buildStatCard(
            label: 'Total Events',
            value: stats.totalEvents.toString(),
            icon: Icons.receipt_long_outlined,
            color: AppColors.accentBlue,
          ),
          _buildStatCard(
            label: 'Successful',
            value: stats.successful.toString(),
            icon: Icons.check_circle_outline,
            color: AppColors.success,
          ),
          _buildStatCard(
            label: 'Failed Actions',
            value: stats.failed.toString(),
            icon: Icons.error_outline,
            color: AppColors.error,
          ),
          _buildStatCard(
            label: 'Active Users',
            value: stats.activeUsers.toString(),
            icon: Icons.people_outline,
            color: AppColors.accentTeal,
          ),
        ];

        if (isNarrow) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: cards
                  .map((c) => Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        child: c,
                      ))
                  .toList(),
            ),
          );
        }

        return Row(
          children: cards
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: c,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar(BuildContext context, AuditState state) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          final searchWidget = AppTextField(
            hint: 'Search by action, user, IP, or resource...',
            prefixIcon: Icons.search,
            controller: _searchController,
            onChanged: (val) {
              ref.read(auditNotifierProvider.notifier).setSearch(val.trim());
            },
          );

          final statusDropdown = DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: state.selectedStatus,
              isDense: true,
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('Status: All')),
                DropdownMenuItem(value: 'SUCCESS', child: Text('SUCCESS')),
                DropdownMenuItem(value: 'FAILED', child: Text('FAILED')),
              ],
              onChanged: (val) {
                if (val != null) {
                  ref.read(auditNotifierProvider.notifier).setStatus(val);
                }
              },
            ),
          );

          if (isNarrow) {
            return Column(
              children: [
                searchWidget,
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    statusDropdown,
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Refresh',
                      onPressed: () =>
                          ref.read(auditNotifierProvider.notifier).loadLogs(),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: searchWidget),
              const SizedBox(width: 16),
              statusDropdown,
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh',
                onPressed: () =>
                    ref.read(auditNotifierProvider.notifier).loadLogs(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveEntityFilterPill(
      BuildContext context, AuditState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.heroSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            state.entityFilterType == 'user'
                ? Icons.person_outline
                : state.entityFilterType == 'document'
                    ? Icons.description_outlined
                    : Icons.assessment_outlined,
            size: 16,
            color: AppColors.accentTeal,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filtered by ${state.entityFilterType?.toUpperCase()}: ${state.entityFilterId}',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () {
              ref.read(auditNotifierProvider.notifier).clearEntityFilter();
            },
            child: const Row(
              children: [
                Text(
                  'Clear Filter',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.close, size: 14, color: AppColors.error),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(BuildContext context, List<AuditLogEntry> logs) {
    return ListView.separated(
      itemCount: logs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final log = logs[index];
        return AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusChip(
                    status: log.isSuccess ? 'success' : 'error',
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${log.action} • ${log.resource}',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTimestamp(log.timestamp),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_circle,
                                size: 14, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              '${log.user.username} (${log.user.role ?? "user"})',
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (log.ipAddress != null) ...[
                              const SizedBox(width: 12),
                              Text(
                                'IP: ${log.ipAddress}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (log.resourceId != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Target ID: ${log.resourceId}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Inspect Button
                  OutlinedButton.icon(
                    onPressed: () => _showLogDetailModal(context, log),
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text('Inspect'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: AppTypography.labelSmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogDetailModal(BuildContext context, AuditLogEntry log) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const Icon(Icons.security, color: AppColors.accentTeal, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Audit Provenance Detail: ${log.id}',
                    style: AppTypography.headlineSmall,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailItem('Timestamp', log.timestamp),
                  _buildDetailItem('Action', log.action),
                  _buildDetailItem('Resource', log.resource),
                  if (log.resourceId != null)
                    _buildDetailItem('Resource ID', log.resourceId!),
                  _buildDetailItem('Status', log.status),
                  _buildDetailItem('User ID', log.user.id),
                  _buildDetailItem('Username', log.user.username),
                  if (log.user.role != null)
                    _buildDetailItem('Role', log.user.role!),
                  if (log.ipAddress != null)
                    _buildDetailItem('IP Address', log.ipAddress!),
                  const SizedBox(height: 12),
                  Text('Event Payload (Details):',
                      style: AppTypography.labelMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.heroSurfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      const JsonEncoder.withIndent('  ').convert(log.details),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.textInverse,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text('$label:',
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: AppTypography.bodySmall
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showEntityFilterDialog(BuildContext context) {
    final userController = TextEditingController();
    final docController = TextEditingController();
    final reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Filter Audit by Entity'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select an entity type to scope compliance history to a specific actor, document, or statutory report:',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'User ID (e.g. 64e0a1b2c3d4e5f6a7b8c9d0)',
                  controller: userController,
                  hint: 'Enter 24-char ObjectId...',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Document ID (e.g. doc-bokaro-survey-01)',
                  controller: docController,
                  hint: 'Enter Document ID...',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Report ID (e.g. rep-q2-coal-2026)',
                  controller: reportController,
                  hint: 'Enter Report ID...',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (userController.text.trim().isNotEmpty) {
                  ref
                      .read(auditNotifierProvider.notifier)
                      .filterByUser(userController.text.trim());
                } else if (docController.text.trim().isNotEmpty) {
                  ref
                      .read(auditNotifierProvider.notifier)
                      .filterByDocument(docController.text.trim());
                } else if (reportController.text.trim().isNotEmpty) {
                  ref
                      .read(auditNotifierProvider.notifier)
                      .filterByReport(reportController.text.trim());
                }
              },
              child: const Text('Apply Filter'),
            ),
          ],
        );
      },
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Export Statutory Audit Trail'),
          content: const Text(
            'Select compliance format for the export download stream. The output includes tamper-evident immutable records with actor identities and IP addresses.',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            OutlinedButton.icon(
              icon: const Icon(Icons.table_chart_outlined, size: 16),
              label: const Text('Export CSV'),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final res = await ref
                    .read(auditNotifierProvider.notifier)
                    .exportAudit('csv');
                if (context.mounted && res != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Audit exported as ${res.filename}'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.code_outlined, size: 16),
              label: const Text('Export JSON'),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final res = await ref
                    .read(auditNotifierProvider.notifier)
                    .exportAudit('json');
                if (context.mounted && res != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Audit exported as ${res.filename}'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.manage_search_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No audit logs match current query',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try clearing entity filters or broadening the search term.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
