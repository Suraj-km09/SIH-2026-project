import 'package:flutter/material.dart';
import '../../../models/dashboard_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/cards/app_card.dart';

/// Recent Activity audit stream card for Dashboard.
class DashboardRecentActivityCard extends StatelessWidget {
  final List<DashboardActivityModel> activity;

  const DashboardRecentActivityCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.history_toggle_off_outlined,
                        size: 20,
                        color: AppColors.accentIndigo,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Recent Audit Activity',
                        style: AppTypography.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${activity.length} Events',
                style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (activity.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No recent activity recorded.', style: AppTypography.bodySmall),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activity.length,
              separatorBuilder: (_, _) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final item = activity[index];
                final iconConfig = _resolveActionIcon(item.action);
                final displayAction = item.action.isNotEmpty
                    ? item.action.replaceAll('_', ' ')
                    : (item.title ?? 'Activity Event');

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconConfig.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(iconConfig.icon, size: 16, color: iconConfig.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayAction,
                                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item.resource.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.badgeNeutralBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.resource,
                                    style: const TextStyle(fontSize: 10, color: AppColors.badgeNeutralText),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'by ${item.user.isEmpty ? "system" : item.user}',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item.timestamp.isNotEmpty) ...[
                                const Text(' • ', style: TextStyle(color: AppColors.textTertiary)),
                                Text(
                                  _formatTime(item.timestamp),
                                  style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  _ActionIconConfig _resolveActionIcon(String action) {
    final act = action.toUpperCase();
    if (act.contains('UPLOAD')) {
      return const _ActionIconConfig(Icons.upload_file, AppColors.accentBlue, AppColors.infoBg);
    } else if (act.contains('APPROVE')) {
      return const _ActionIconConfig(Icons.check_circle_outline, AppColors.success, AppColors.successBg);
    } else if (act.contains('REJECT')) {
      return const _ActionIconConfig(Icons.cancel_outlined, AppColors.error, AppColors.errorBg);
    } else if (act.contains('VALIDAT')) {
      return const _ActionIconConfig(Icons.rule_folder_outlined, AppColors.accentTeal, Color(0xFFF0FDFA));
    } else if (act.contains('REPORT')) {
      return const _ActionIconConfig(Icons.description_outlined, AppColors.accentIndigo, Color(0xFFEEF2FF));
    } else if (act.contains('LOGIN') || act.contains('LOGOUT') || act.contains('AUTH')) {
      return const _ActionIconConfig(Icons.lock_clock_outlined, AppColors.accentBlue, Color(0xFFEFF6FF));
    } else if (act.contains('INDEX') || act.contains('KNOWLEDGE')) {
      return const _ActionIconConfig(Icons.auto_stories_outlined, AppColors.accentTeal, Color(0xFFF0FDFA));
    }
    return const _ActionIconConfig(Icons.bubble_chart_outlined, AppColors.textSecondary, AppColors.surfaceMuted);
  }

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} (${dt.day}/${dt.month})';
    } catch (_) {
      return raw;
    }
  }
}

class _ActionIconConfig {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _ActionIconConfig(this.icon, this.color, this.backgroundColor);
}
