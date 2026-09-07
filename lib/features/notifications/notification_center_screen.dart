import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/notification_model.dart';
import '../../state/notification_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/status_chip.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/feedback/loading_indicator.dart';
import '../../widgets/layout/responsive_layout.dart';

/// Notification Center Screen.
/// Provides in-app notification list, unread indicators, category filtering,
/// and individual/bulk mark-as-read workflows.
class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationsNotifierProvider.notifier).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(notificationsNotifierProvider);
    final unreadCount = notifState.unreadCount;
    final items = notifState.filteredNotifications;

    return ResponsiveContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          _buildHeaderBar(context, unreadCount, notifState.isLoading),
          const SizedBox(height: 16),

          // Category Filter Bar
          _buildFilterChips(context, notifState.activeCategoryFilter),
          const SizedBox(height: 16),

          // Main List View
          Expanded(
            child: notifState.isLoading && items.isEmpty
                ? const Center(
                    child: AppLoadingIndicator(message: 'Loading alerts...'),
                  )
                : items.isEmpty
                    ? _buildEmptyState(context, notifState.activeCategoryFilter)
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(notificationsNotifierProvider.notifier)
                            .loadNotifications(),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _buildNotificationCard(
                                context, items[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar(
      BuildContext context, int unreadCount, bool isLoading) {
    final isCompact = MediaQuery.of(context).size.width < 560;

    final titleSection = Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Notification Center',
          style: AppTypography.headlineMedium,
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: unreadCount > 0
                ? AppColors.accentBlue
                : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            unreadCount > 0 ? '$unreadCount unread' : 'All caught up',
            style: AppTypography.labelSmall.copyWith(
              color: unreadCount > 0
                  ? AppColors.textInverse
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (unreadCount > 0)
          AppButton(
            text: 'Mark All Read',
            icon: Icons.done_all,
            variant: AppButtonVariant.outline,
            height: 36,
            onPressed: () {
              ref
                  .read(notificationsNotifierProvider.notifier)
                  .markAllAsRead();
            },
          ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: 'Refresh Notifications',
          onPressed: isLoading
              ? null
              : () => ref
                  .read(notificationsNotifierProvider.notifier)
                  .loadNotifications(),
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleSection,
          const SizedBox(height: 10),
          actions,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        titleSection,
        actions,
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context, String activeFilter) {
    final filters = [
      {'key': 'all', 'label': 'All Alerts'},
      {'key': 'unread', 'label': 'Unread Only'},
      {'key': 'approval', 'label': 'Approvals'},
      {'key': 'alert', 'label': 'Critical Alerts'},
      {'key': 'upload', 'label': 'Document Tasks'},
      {'key': 'review', 'label': 'HITL Reviews'},
      {'key': 'system', 'label': 'System'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = activeFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (_) {
                ref
                    .read(notificationsNotifierProvider.notifier)
                    .setFilter(f['key']!);
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.heroSurface,
              labelStyle: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? AppColors.textInverse
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.heroSurface : AppColors.border,
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationCard(
      BuildContext context, NotificationModel notification) {
    final isUnread = !notification.read;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      backgroundColor: isUnread
          ? AppColors.infoBg.withValues(alpha: 0.35)
          : AppColors.surface,
      border: BorderSide(
        color: isUnread ? AppColors.infoBorder : AppColors.border,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type Icon
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 14),
            child: _buildTypeIcon(notification.type),
          ),

          // Message & Meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusChip(
                      status: notification.category.toLowerCase(),
                    ),
                    const SizedBox(width: 8),
                    if (notification.createdAt != null)
                      Text(
                        _formatTimestamp(notification.createdAt!),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    const Spacer(),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accentBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  notification.message,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (notification.relatedId != null &&
                    notification.relatedId!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Reference ID: ${notification.relatedId}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action: Mark Read Button
          if (isUnread) ...[
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.check, size: 18),
              tooltip: 'Mark as read',
              onPressed: () {
                ref
                    .read(notificationsNotifierProvider.notifier)
                    .markAsRead(notification.id);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'success':
        return const Icon(Icons.check_circle_outline,
            color: AppColors.success, size: 22);
      case 'error':
        return const Icon(Icons.error_outline,
            color: AppColors.error, size: 22);
      case 'warning':
        return const Icon(Icons.warning_amber_outlined,
            color: AppColors.warning, size: 22);
      case 'info':
      default:
        return const Icon(Icons.info_outline,
            color: AppColors.info, size: 22);
    }
  }

  String _formatTimestamp(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes.clamp(1, 60)}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      return raw;
    }
  }

  Widget _buildEmptyState(BuildContext context, String filter) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              filter == 'unread'
                  ? 'No unread notifications'
                  : 'No alerts found in this category',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You are all caught up with statutory notices and processing pipeline events.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
