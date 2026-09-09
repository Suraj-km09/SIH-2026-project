import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/admin_model.dart';
import '../../models/user_model.dart';
import '../../state/admin_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/dialogs/app_dialog.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/loading_indicator.dart';

/// Admin Dashboard & User Governance Screen.
/// Displays full platform statistics from /admin/stats, role distribution donut chart,
/// document status bar chart, and user directory with role filtering.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  int _donutTouchedIndex = -1;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminNotifierProvider.notifier).loadAdminData();
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // â”€â”€â”€ Role filter modal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showRoleFilterModal(BuildContext context, AdminRoleFilter currentFilter) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF262C38),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 4)),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRoleRadioItem(ctx, 'All Roles', AdminRoleFilter.all, currentFilter),
                const Divider(height: 1, color: Color(0xFF333B4A)),
                _buildRoleRadioItem(ctx, 'User', AdminRoleFilter.user, currentFilter),
                const Divider(height: 1, color: Color(0xFF333B4A)),
                _buildRoleRadioItem(ctx, 'Reviewer', AdminRoleFilter.reviewer, currentFilter),
                const Divider(height: 1, color: Color(0xFF333B4A)),
                _buildRoleRadioItem(ctx, 'Admin', AdminRoleFilter.admin, currentFilter),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleRadioItem(
    BuildContext ctx,
    String label,
    AdminRoleFilter filter,
    AdminRoleFilter current,
  ) {
    final isSelected = filter == current;
    return InkWell(
      onTap: () {
        ref.read(adminNotifierProvider.notifier).setRoleFilter(filter);
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF7DD3FC) : Colors.white54,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF7DD3FC),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€ User action modal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _handleUserAction(UserModel user) async {
    final notifier = ref.read(adminNotifierProvider.notifier);

    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Manage User: ${user.username}',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (user.role != 'admin') ...[
              ListTile(
                leading: const Icon(Icons.manage_accounts_outlined),
                title: Text(user.role == 'user' ? 'Promote to Reviewer' : 'Demote to Standard User'),
                onTap: () => Navigator.pop(ctx, user.role == 'user' ? 'promote' : 'demote'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Delete User Account', style: TextStyle(color: AppColors.error)),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            ] else ...[
              const ListTile(
                leading: Icon(Icons.shield_outlined, color: AppColors.warning),
                title: Text('Administrator account is protected'),
                subtitle: Text('Admin accounts cannot be demoted or deleted via console.'),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected == null || !mounted) return;

    if (selected == 'promote') {
      await notifier.updateUserRole(user.id, 'reviewer');
    } else if (selected == 'demote') {
      await notifier.updateUserRole(user.id, 'user');
    } else if (selected == 'delete') {
      if (!mounted) return;
      final confirmed = await AppDialog.confirm(
        context,
        title: 'Delete User Account',
        message: 'Are you sure you want to permanently delete user account "${user.username}"?',
        confirmText: 'Delete',
        isDestructive: true,
      );
      if (confirmed && mounted) {
        await notifier.deleteUser(user.id);
      }
    }
  }

  // â”€â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminNotifierProvider);

    ref.listen<AdminState>(adminNotifierProvider, (prev, next) {
      if (next.actionMessage != null && next.actionMessage != prev?.actionMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.actionMessage!),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final stats = state.stats;
    final filteredUsers = state.filteredUsers;
    final totalUserCount = stats?.totalUsers ?? state.users.length;

    // Role counts derived from the live /admin/users list
    final adminCount = state.users.where((u) => u.role == 'admin').length;
    final reviewerCount = state.users.where((u) => u.role == 'reviewer').length;
    final userCount = state.users.where((u) => u.role == 'user').length;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: RefreshIndicator(
          onRefresh: () => ref.read(adminNotifierProvider.notifier).loadAdminData(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // â”€â”€ Section label â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Text(
                  'Platform Overview',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real-time platform activity and system metrics',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                // ── Row 1: Users · Documents · Indexed ───────────────────
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _KpiCard(
                          label: 'TOTAL USERS',
                          value: '${stats?.totalUsers ?? '—'}',
                          icon: Icons.people_alt_outlined,
                          iconColor: const Color(0xFF2563EB),
                          iconBg: const Color(0xFFEFF6FF),
                          isLoading: state.isLoading && stats == null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _KpiCard(
                          label: 'DOCUMENTS',
                          value: '${stats?.totalDocuments ?? '—'}',
                          icon: Icons.insert_drive_file_outlined,
                          iconColor: const Color(0xFF7C3AED),
                          iconBg: const Color(0xFFF5F3FF),
                          isLoading: state.isLoading && stats == null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _KpiCard(
                          label: 'INDEXED',
                          value: '${stats?.indexedDocuments ?? '—'}',
                          icon: Icons.search_outlined,
                          iconColor: const Color(0xFF0D9488),
                          iconBg: const Color(0xFFF0FDFA),
                          isLoading: state.isLoading && stats == null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ── Row 2: Reports · Validations · Open Issues ────────────
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _KpiCard(
                          label: 'REPORTS',
                          value: '${stats?.reportsGenerated ?? '—'}',
                          icon: Icons.assessment_outlined,
                          iconColor: const Color(0xFF059669),
                          iconBg: const Color(0xFFECFDF5),
                          isLoading: state.isLoading && stats == null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _KpiCard(
                          label: 'VALIDATIONS',
                          value: '${stats?.totalValidations ?? '—'}',
                          icon: Icons.shield_outlined,
                          iconColor: const Color(0xFFD97706),
                          iconBg: const Color(0xFFFEF3C7),
                          isLoading: state.isLoading && stats == null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _KpiCard(
                          label: 'OPEN ISSUES',
                          value: '${stats?.openValidations ?? '—'}',
                          icon: Icons.error_outline,
                          iconColor: const Color(0xFFE11D48),
                          iconBg: const Color(0xFFFFE4E6),
                          isLoading: state.isLoading && stats == null,
                          highlight: (stats?.openValidations ?? 0) > 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Charts row ──────────────────────────────────────────────
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 640;
                    if (isNarrow) {
                      return Column(
                        children: [
                          _buildRoleDonutCard(
                            adminCount: adminCount,
                            reviewerCount: reviewerCount,
                            userCount: userCount,
                            isLoading: state.isLoading && state.users.isEmpty,
                          ),
                          const SizedBox(height: 14),
                          _buildDocStatusBarCard(
                            stats: stats,
                            isLoading: state.isLoading && stats == null,
                          ),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Donut: Role Distribution (from /admin/users)
                        Expanded(
                          child: _buildRoleDonutCard(
                            adminCount: adminCount,
                            reviewerCount: reviewerCount,
                            userCount: userCount,
                            isLoading: state.isLoading && state.users.isEmpty,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Bar: Document Processing Status (from /admin/stats)
                        Expanded(
                          child: _buildDocStatusBarCard(
                            stats: stats,
                            isLoading: state.isLoading && stats == null,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // â”€â”€ User Management â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [AppColors.cardShadow],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.group_outlined, size: 20, color: Color(0xFFD97706)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'User Management ($totalUserCount)',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _showRoleFilterModal(context, state.roleFilter),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      state.roleFilter.label,
                                      style: AppTypography.labelSmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.keyboard_arrow_down, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Search input
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) =>
                              ref.read(adminNotifierProvider.notifier).setSearchQuery(val),
                          decoration: InputDecoration(
                            hintText: 'Search by username or email...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref
                                          .read(adminNotifierProvider.notifier)
                                          .setSearchQuery('');
                                    },
                                  )
                                : null,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),

                      // User list
                      if (state.isLoading && state.users.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: AppLoadingIndicator(message: 'Loading user directory...'),
                        )
                      else if (filteredUsers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: EmptyStateWidget(
                            icon: Icons.person_search_outlined,
                            title: 'No Users Found',
                            description: 'No accounts match "${state.roleFilter.label}".',
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredUsers.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (ctx, idx) {
                            final user = filteredUsers[idx];
                            return _buildUserListTile(user);
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // â”€â”€â”€ Role Distribution Donut Chart (data from /admin/users) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildRoleDonutCard({
    required int adminCount,
    required int reviewerCount,
    required int userCount,
    required bool isLoading,
  }) {
    final total = adminCount + reviewerCount + userCount;
    final segments = <_DonutSegment>[
      _DonutSegment('Users', userCount, const Color(0xFF2563EB)),
      _DonutSegment('Reviewers', reviewerCount, const Color(0xFF0D9488)),
      _DonutSegment('Admins', adminCount, const Color(0xFFD97706)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.pie_chart_outline, size: 16, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Role Distribution',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          else if (total == 0)
            const SizedBox(
              height: 120,
              child: Center(child: Text('No user data yet')),
            )
          else
            SizedBox(
              height: 120,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          _donutTouchedIndex = -1;
                          return;
                        }
                        _donutTouchedIndex =
                            response.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sectionsSpace: 2,
                  centerSpaceRadius: 32,
                  sections: segments.asMap().entries.map((e) {
                    final isTouched = e.key == _donutTouchedIndex;
                    final seg = e.value;
                    return PieChartSectionData(
                      value: seg.count.toDouble(),
                      color: seg.color,
                      radius: isTouched ? 26.0 : 22.0,
                      title: seg.count > 0 ? '${seg.count}' : '',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: segments.map((s) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${s.label} (${s.count})',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ Document Status Bar Chart (data from /admin/stats) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildDocStatusBarCard({
    required AdminStatsModel? stats,
    required bool isLoading,
  }) {
    final total = (stats?.totalDocuments ?? 0).toDouble();
    final indexed = (stats?.indexedDocuments ?? 0).toDouble();
    final pending = math.max(0.0, total - indexed);

    final values = [total, indexed, pending];
    final shortLabels = ['Total', 'Indexed', 'Pending'];
    final colors = [
      const Color(0xFF4F46E5),
      const Color(0xFF0D9488),
      const Color(0xFFD97706),
    ];

    final barGroups = List.generate(3, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: values[i],
            color: colors[i],
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ],
      );
    });

    final maxY = values.fold(0.0, math.max) * 1.3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.bar_chart_rounded, size: 16, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Document Status',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          else
            SizedBox(
              height: 120,
              child: BarChart(
                BarChartData(
                  maxY: maxY == 0 ? 10 : maxY,
                  barGroups: barGroups,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY == 0 ? 5 : maxY / 4,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: AppColors.border, strokeWidth: 0.8),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final i = val.toInt();
                          if (i < 0 || i >= shortLabels.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              shortLabels[i],
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: colors[i],
                              ),
                            ),
                          );
                        },
                        reservedSize: 22,
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                        '${['Total', 'Indexed', 'Pending'][group.x]}\n${rod.toY.toInt()}',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),
          if (stats != null && stats.totalDocuments > 0)
            Text(
              'Index coverage: ${((stats.indexedDocuments / stats.totalDocuments) * 100).toStringAsFixed(0)}%',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  // â”€â”€â”€ User List Tile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildUserListTile(UserModel user) {
    final roleColor = user.isAdmin
        ? const Color(0xFFD97706)
        : (user.isReviewer ? AppColors.accentBlue : AppColors.textSecondary);

    return InkWell(
      onTap: () => _handleUserAction(user),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: user.isAdmin ? const Color(0xFFFEF3C7) : AppColors.surfaceMuted,
              child: Text(
                user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: user.isAdmin ? const Color(0xFFD97706) : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email ?? (user.department ?? 'Standard Operator'),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                user.role.toUpperCase(),
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.more_vert, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Reusable KPI card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool isLoading;
  final bool highlight;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.isLoading = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: highlight && !isDark
            ? const Color(0xFFFFF8F8)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? (isDark ? const Color(0xFF991B1B) : const Color(0xFFFDA4AF))
              : AppColors.border,
          width: highlight ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: highlight
                ? iconColor.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? iconColor.withValues(alpha: 0.2) : iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              if (highlight)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF4C0519)
                        : const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ACTION',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: iconColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              isLoading
                  ? Container(
                      height: 24,
                      width: 44,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    )
                  : Text(
                      value,
                      style: AppTypography.displayLarge.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: highlight ? iconColor : AppColors.textPrimary,
                        height: 1.1,
                      ),
                    ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontSize: 10.5,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Donut segment helper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DonutSegment {
  final String label;
  final int count;
  final Color color;
  const _DonutSegment(this.label, this.count, this.color);
}

