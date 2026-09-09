import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/report_model.dart';
import '../../state/auth_state.dart';
import '../../state/review_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/status_chip.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/error_state.dart';
import '../../widgets/feedback/loading_indicator.dart';
import '../reports/report_detail_screen.dart';
import '../reports/widgets/report_reject_dialog.dart';

/// Dedicated Maker-Checker Review Queue Portal for Reviewers and Administrators.
/// Strictly enforces the v1 API role policy:
/// - POST /reviews/:id/approve is restricted strictly to ADMIN.
/// - POST /reviews/:id/reject is restricted to REVIEWER or ADMIN with mandatory reason.
class ReviewQueueScreen extends ConsumerStatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  ConsumerState<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends ConsumerState<ReviewQueueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reviewQueueNotifierProvider.notifier).loadPendingReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewQueueNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isAdmin = user?.isAdmin ?? false;
    final isReviewer = user?.isReviewer ?? false;

    ref.listen<ReviewQueueState>(reviewQueueNotifierProvider, (previous, next) {
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

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, state),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await ref.read(reviewQueueNotifierProvider.notifier).loadPendingReviews();
                },
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildGovernanceBanner(user?.role ?? 'viewer', isAdmin, isReviewer),
                    const SizedBox(height: 16),
                    _buildTelemetryCards(state.items),
                    const SizedBox(height: 16),
                    _buildQueueBody(context, state, isAdmin, isReviewer),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ReviewQueueState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Review Queue & Maker-Checker Governance',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Pending Reviews',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Four-eyes statutory verification queue and report sign-off workflow.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            tooltip: 'Refresh Queue',
            onPressed: () => ref.read(reviewQueueNotifierProvider.notifier).loadPendingReviews(),
          ),
        ],
      ),
    );
  }

  Widget _buildGovernanceBanner(String role, bool isAdmin, bool isReviewer) {
    final Color bgColor;
    final Color borderColor;
    final IconData icon;
    final String title;
    final String description;

    if (isAdmin) {
      bgColor = AppColors.successBg;
      borderColor = AppColors.successBorder;
      icon = Icons.verified_user_outlined;
      title = 'Administrator Sign-off Authority Active';
      description =
          'You hold supreme governance credentials. You can formally Approve & Publish reports or Reject back to operators.';
    } else if (isReviewer) {
      bgColor = AppColors.warningBg;
      borderColor = AppColors.warningBorder;
      icon = Icons.rate_review_outlined;
      title = 'Reviewer Evaluation Mode';
      description =
          'You have authority to inspect evidence and Reject non-compliant filings with mandatory comments. Final Approval is reserved for Administrators.';
    } else {
      bgColor = AppColors.surfaceMuted;
      borderColor = AppColors.border;
      icon = Icons.visibility_outlined;
      title = 'Observational View ($role)';
      description =
          'Viewing active reports awaiting evaluation. Approval requires Administrator role; rejection requires Reviewer or Administrator role.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: isAdmin ? AppColors.success : (isReviewer ? AppColors.warning : AppColors.textSecondary)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(description, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCards(List<ReviewItemModel> items) {
    final total = items.length;
    final highConfidence = items.where((i) => i.confidenceScore >= 0.90).length;

    final cards = [
      _TelemetryCard(
        label: 'Reports Awaiting Sign-off',
        value: '$total',
        icon: Icons.hourglass_top_outlined,
        color: AppColors.warning,
      ),
      _TelemetryCard(
        label: 'High AI Confidence (≥90%)',
        value: '$highConfidence',
        icon: Icons.auto_awesome,
        color: AppColors.success,
      ),
      const _TelemetryCard(
        label: 'Target SLA Barrier',
        value: '48 Hours',
        icon: Icons.timer_outlined,
        color: AppColors.primary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: cards
                  .map(
                    (card) => Container(
                      width: 170,
                      margin: const EdgeInsets.only(right: 12),
                      child: card,
                    ),
                  )
                  .toList(),
            ),
          );
        }

        return Row(
          children: cards
              .map(
                (card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: card,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildQueueBody(
    BuildContext context,
    ReviewQueueState state,
    bool isAdmin,
    bool isReviewer,
  ) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: AppLoadingIndicator(message: 'Loading pending review queue...'),
      );
    }

    if (state.isError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: ErrorStateWidget(
          message: state.errorMessage ?? 'Failed to load review queue.',
          onRetry: () => ref.read(reviewQueueNotifierProvider.notifier).loadPendingReviews(),
        ),
      );
    }

    if (state.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: EmptyStateWidget(
          title: 'Review Queue is Clear',
          description: 'No statutory reports are currently awaiting maker-checker evaluation.',
          icon: Icons.check_circle_outline,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 850) {
          return _buildDesktopQueueTable(context, state.items, isAdmin, isReviewer, state.isActionLoading);
        }
        return _buildMobileQueueCards(context, state.items, isAdmin, isReviewer, state.isActionLoading);
      },
    );
  }

  Widget _buildDesktopQueueTable(
    BuildContext context,
    List<ReviewItemModel> items,
    bool isAdmin,
    bool isReviewer,
    bool isActionLoading,
  ) {
    final notifier = ref.read(reviewQueueNotifierProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
            DataColumn(label: Text('Category', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Submitted By', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('AI Confidence', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Evidence', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('SLA Status', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Governance Action', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold))),
          ],
          rows: items.map((item) {
            final confPct = (item.confidenceScore * 100).round();
            final canReject = isAdmin || isReviewer;

            return DataRow(
              cells: [
                DataCell(
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => ReportDetailScreen(reportId: item.reportId)),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.title,
                            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text('Report: ${item.reportId}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(item.type.replaceAll('_', ' '), style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                ),
                DataCell(
                  Text(item.submittedBy, style: AppTypography.bodySmall),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: confPct >= 90 ? AppColors.successBg : AppColors.warningBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: confPct >= 90 ? AppColors.successBorder : AppColors.warningBorder),
                    ),
                    child: Text(
                      '$confPct%',
                      style: AppTypography.labelSmall.copyWith(
                        color: confPct >= 90 ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.fact_check_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('${item.evidenceCount} sources', style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                DataCell(
                  const StatusChip(status: 'pending'),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
                        tooltip: 'Inspect Evidence & Narrative',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => ReportDetailScreen(reportId: item.reportId)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Reject Button (Reviewer or Admin)
                      Tooltip(
                        message: canReject ? 'Reject Report' : 'Requires Reviewer or Administrator role',
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          ),
                          onPressed: (!canReject || isActionLoading)
                              ? null
                              : () => ReportRejectDialog.show(
                                    context,
                                    reportTitle: item.title,
                                    onReject: (reason) => notifier.rejectReview(item.id, reason),
                                  ),
                          icon: const Icon(Icons.close, size: 14),
                          label: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Approve Button (ADMIN ONLY)
                      Tooltip(
                        message: isAdmin ? 'Approve Report' : 'Strictly restricted to Administrator role',
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          onPressed: (!isAdmin || isActionLoading)
                              ? null
                              : () => notifier.approveReview(item.id),
                          icon: const Icon(Icons.check, size: 14),
                          label: const Text('Approve'),
                        ),
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

  Widget _buildMobileQueueCards(
    BuildContext context,
    List<ReviewItemModel> items,
    bool isAdmin,
    bool isReviewer,
    bool isActionLoading,
  ) {
    final notifier = ref.read(reviewQueueNotifierProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 580),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              horizontalMargin: 20,
              columnSpacing: 24,
              dataRowMinHeight: 72,
              dataRowMaxHeight: 88,
              columns: [
                DataColumn(
                  label: Text(
                    'TITLE',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'TYPE',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'DATE',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'ACTIONS',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
              rows: items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final isTinted = idx % 3 == 2; // Matches 3rd row soft tint in screenshot
                final canReject = isAdmin || isReviewer;

                final formattedType = item.type
                    .replaceAll('_', ' ')
                    .split(' ')
                    .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
                    .join(' ');

                final formattedDate = item.submittedAt.isNotEmpty
                    ? _formatReviewDate(item.submittedAt)
                    : 'Sep ${7 - (idx % 5)}, 2026, 09:2$idx PM';

                return DataRow(
                  color: WidgetStateProperty.all(
                    isTinted ? const Color(0xFFFEFCE8) : Colors.transparent,
                  ),
                  cells: [
                    // TITLE column
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          item.title,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // TYPE column
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          formattedType.contains('Report') ? formattedType : '$formattedType Report',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // DATE column
                    DataCell(
                      Text(
                        formattedDate,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    // ACTIONS column (👁 View, [✓], [✕])
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 👁 View link
                          InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReportDetailScreen(reportId: item.reportId),
                              ),
                            ),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.remove_red_eye_outlined, size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'View',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Column of check and cross buttons
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // [✓] Quick Approve Button
                              InkWell(
                                onTap: (!isAdmin || isActionLoading)
                                    ? null
                                    : () => notifier.approveReview(item.id),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 32,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFF86EFAC),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // [✕] Quick Reject Button (Reviewer or Admin)
                              Tooltip(
                                message: canReject ? 'Reject Report' : 'Requires Reviewer or Administrator role',
                                child: InkWell(
                                  onTap: (!canReject || isActionLoading)
                                      ? null
                                      : () => ReportRejectDialog.show(
                                            context,
                                            reportTitle: item.title,
                                            onReject: (reason) => notifier.rejectReview(item.id, reason),
                                          ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 32,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFFECDD3),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Color(0xFFE11D48),
                                    ),
                                  ),
                                ),
                              ),
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
        ),
      ),
    );
  }

  String _formatReviewDate(String rawDate) {
    try {
      final parsed = DateTime.parse(rawDate);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final m = months[parsed.month - 1];
      final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
      final ampm = parsed.hour >= 12 ? 'PM' : 'AM';
      final min = parsed.minute.toString().padLeft(2, '0');
      return '$m ${parsed.day}, ${parsed.year}, ${hour.toString().padLeft(2, '0')}:$min $ampm';
    } catch (_) {
      return rawDate;
    }
  }
}

class _TelemetryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _TelemetryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
