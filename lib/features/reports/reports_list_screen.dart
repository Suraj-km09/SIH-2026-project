import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/report_model.dart';
import '../../state/auth_state.dart';
import '../../state/report_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/status_chip.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/error_state.dart';
import '../../widgets/feedback/loading_indicator.dart';
import 'report_detail_screen.dart';
import 'widgets/report_editor_dialog.dart';
import 'widgets/report_generate_dialog.dart';

/// Screen listing all statutory mining reports with search, filter,
/// generation triggers, multi-format export, and review lifecycle status.
class ReportsListScreen extends ConsumerStatefulWidget {
  const ReportsListScreen({super.key});

  @override
  ConsumerState<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends ConsumerState<ReportsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all';
  String _typeFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportListNotifierProvider.notifier).loadReports();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    ref.read(reportListNotifierProvider.notifier).setFilter(
          ReportFilter(
            status: _statusFilter == 'all' ? null : _statusFilter,
            type: _typeFilter == 'all' ? null : _typeFilter,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportListNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isAdmin = user?.isAdmin ?? false;

    ref.listen<ReportListState>(reportListNotifierProvider, (previous, next) {
      if (next.actionMessage != null && next.actionMessage != previous?.actionMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.actionMessage!),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final filteredReports = state.reports.where((r) {
      if (_searchController.text.trim().isEmpty) return true;
      final q = _searchController.text.trim().toLowerCase();
      return r.title.toLowerCase().contains(q) || r.id.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, state),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await ref.read(reportListNotifierProvider.notifier).loadReports();
                },
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSummaryCards(state.reports),
                    const SizedBox(height: 16),
                    _buildFilterToolbar(context),
                    const SizedBox(height: 16),
                    _buildReportsBody(context, state, filteredReports, isAdmin),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ReportListState state) {
    final isCompact = MediaQuery.of(context).size.width < 600;

    final titleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Statutory Reports & Regulatory Filings',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Phase 8',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Automated report drafting, multi-format export, and statutory Maker-Checker review governance',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    final actionButton = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: state.isActionLoading
          ? null
          : () async {
              final report = await ReportGenerateDialog.show(
                context,
                onGenerate: (req) =>
                    ref.read(reportListNotifierProvider.notifier).generateReport(req),
              );
              if (report != null && context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ReportDetailScreen(reportId: report.id),
                  ),
                );
              }
            },
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Generate Report'),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleSection,
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: actionButton),
              ],
            )
          : Row(
              children: [
                Expanded(child: titleSection),
                const SizedBox(width: 12),
                actionButton,
              ],
            ),
    );
  }

  Widget _buildSummaryCards(List<ReportModel> reports) {
    final total = reports.length;
    final approved = reports.where((r) => r.isApproved).length;
    final review = reports.where((r) => r.isReview).length;
    final draft = reports.where((r) => r.isDraft).length;
    final rejected = reports.where((r) => r.isRejected).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth < 360
            ? 1
            : (constraints.maxWidth < 750 ? 2 : 5);
        final isMobile = constraints.maxWidth < 750;
        final itemWidth = count == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - (count - 1) * 12) / count;

        final cards = [
          _StatCard(label: 'Total Reports', value: '$total', icon: Icons.description, color: AppColors.textPrimary),
          _StatCard(label: 'Approved (Published)', value: '$approved', icon: Icons.check_circle_outline, color: AppColors.success),
          _StatCard(label: 'In Review (Pending)', value: '$review', icon: Icons.rate_review_outlined, color: AppColors.warning),
          _StatCard(label: 'Draft Reports', value: '$draft', icon: Icons.edit_note, color: AppColors.accentBlue),
          _StatCard(label: 'Rejected (Action Req)', value: '$rejected', icon: Icons.cancel_outlined, color: AppColors.error),
        ];

        if (isMobile) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards.map((c) => SizedBox(width: itemWidth, child: c)).toList(),
          );
        }

        return Row(
          children: cards
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: c,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildFilterToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: AppTypography.bodySmall,
                    decoration: InputDecoration(
                      hintText: 'Search reports by title or ID...',
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () => setState(() => _searchController.clear()),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: AppColors.surfaceMuted,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Status:',
                style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              _FilterChip(
                label: 'All',
                isSelected: _statusFilter == 'all',
                onSelected: () {
                  setState(() => _statusFilter = 'all');
                  _applyFilter();
                },
              ),
              _FilterChip(
                label: 'Draft',
                isSelected: _statusFilter == 'draft',
                onSelected: () {
                  setState(() => _statusFilter = 'draft');
                  _applyFilter();
                },
              ),
              _FilterChip(
                label: 'Review',
                isSelected: _statusFilter == 'review',
                onSelected: () {
                  setState(() => _statusFilter = 'review');
                  _applyFilter();
                },
              ),
              _FilterChip(
                label: 'Approved',
                isSelected: _statusFilter == 'approved',
                onSelected: () {
                  setState(() => _statusFilter = 'approved');
                  _applyFilter();
                },
              ),
              _FilterChip(
                label: 'Rejected',
                isSelected: _statusFilter == 'rejected',
                onSelected: () {
                  setState(() => _statusFilter = 'rejected');
                  _applyFilter();
                },
              ),
              const SizedBox(width: 14),
              Text(
                'Type:',
                style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              _FilterChip(
                label: 'All Types',
                isSelected: _typeFilter == 'all',
                onSelected: () {
                  setState(() => _typeFilter = 'all');
                  _applyFilter();
                },
              ),
              _FilterChip(
                label: 'Production',
                isSelected: _typeFilter == 'production_summary',
                onSelected: () {
                  setState(() => _typeFilter = 'production_summary');
                  _applyFilter();
                },
              ),
              _FilterChip(
                label: 'Variance',
                isSelected: _typeFilter == 'variance_analysis',
                onSelected: () {
                  setState(() => _typeFilter = 'variance_analysis');
                  _applyFilter();
                },
              ),
              _FilterChip(
                label: 'Compliance',
                isSelected: _typeFilter == 'compliance_audit',
                onSelected: () {
                  setState(() => _typeFilter = 'compliance_audit');
                  _applyFilter();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportsBody(
    BuildContext context,
    ReportListState state,
    List<ReportModel> reports,
    bool isAdmin,
  ) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: AppLoadingIndicator(message: 'Loading statutory mining reports...'),
      );
    }

    if (state.isError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: ErrorStateWidget(
          message: state.errorMessage ?? 'Failed to load reports.',
          onRetry: () => ref.read(reportListNotifierProvider.notifier).loadReports(),
        ),
      );
    }

    if (reports.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: EmptyStateWidget(
          title: 'No Statutory Reports Found',
          description: 'Click "Generate Report" above to synthesize formal compliance filings from verified data.',
          icon: Icons.description_outlined,
          actionText: 'Generate Report Now',
          onAction: () async {
            final rep = await ReportGenerateDialog.show(
              context,
              onGenerate: (req) => ref.read(reportListNotifierProvider.notifier).generateReport(req),
            );
            if (rep != null && context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ReportDetailScreen(reportId: rep.id)),
              );
            }
          },
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 850) {
          return _buildDesktopTable(context, reports, isAdmin);
        }
        return _buildMobileCardList(context, reports, isAdmin);
      },
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<ReportModel> reports, bool isAdmin) {
    final notifier = ref.read(reportListNotifierProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surfaceMuted),
          horizontalMargin: 16,
          columnSpacing: 20,
          columns: [
            DataColumn(label: Text('Report Title', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Type', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Version', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Author', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Lang', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold))),
          ],
          rows: reports.map((r) {
            return DataRow(
              cells: [
                DataCell(
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => ReportDetailScreen(reportId: r.id)),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            r.title,
                            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text('ID: ${r.id}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    r.type.replaceAll('_', ' '),
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                DataCell(StatusChip(status: r.status)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('v${r.version}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                DataCell(
                  Text(r.generatedBy ?? 'Author', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                ),
                DataCell(
                  Text(r.language.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
                        tooltip: 'View Details',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => ReportDetailScreen(reportId: r.id)),
                        ),
                      ),
                      if (r.isDraft) ...[
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.accentBlue),
                          tooltip: 'Edit Draft',
                          onPressed: () => ReportEditorDialog.show(
                            context,
                            report: r,
                            onSave: (req) => ref.read(reportDetailNotifierProvider.notifier).updateReport(r.id, req),
                          ),
                        ),
                      ],
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                        tooltip: 'More Actions',
                        onSelected: (val) {
                          if (val == 'delete') {
                            notifier.deleteReport(r.id);
                          } else {
                            notifier.exportReport(r.id, val);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
                          const PopupMenuItem(value: 'docx', child: Text('Export Word (.docx)')),
                          const PopupMenuItem(value: 'csv', child: Text('Export CSV')),
                          const PopupMenuItem(value: 'json', child: Text('Export JSON')),
                          if (r.isDraft || isAdmin) ...[
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete Report', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileCardList(BuildContext context, List<ReportModel> reports, bool isAdmin) {
    final notifier = ref.read(reportListNotifierProvider.notifier);

    return Column(
      children: reports.map((r) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusChip(status: r.status),
                  Text(
                    'v${r.version} • ${r.language.toUpperCase()}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(r.title, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                'Type: ${r.type.replaceAll('_', ' ')} • Author: ${r.generatedBy ?? 'Operator'}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => ReportDetailScreen(reportId: r.id)),
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View Details'),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.file_download_outlined, size: 16),
                          SizedBox(width: 4),
                          Text('Export', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    onSelected: (fmt) => notifier.exportReport(r.id, fmt),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'pdf', child: Text('PDF Document')),
                      PopupMenuItem(value: 'docx', child: Text('Word (.docx)')),
                      PopupMenuItem(value: 'csv', child: Text('CSV Tabular')),
                      PopupMenuItem(value: 'json', child: Text('JSON Data')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
