import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/admin_model.dart';
import '../../state/admin_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/feedback/loading_indicator.dart';

/// System Health Screen matching Screenshot 2 visual specification.
/// Displays infrastructure readiness for Backend Server, MongoDB, AI Provider (Gemini), and Vector DB.
class SystemHealthScreen extends ConsumerStatefulWidget {
  const SystemHealthScreen({super.key});

  @override
  ConsumerState<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends ConsumerState<SystemHealthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminNotifierProvider.notifier).loadSystemHealth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminNotifierProvider);
    final health = state.systemHealth ?? const SystemHealthModel();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(adminNotifierProvider.notifier).loadSystemHealth(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Screen Title
                Text(
                  'System Health',
                  style: AppTypography.headlineLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle with pulse/chart spark icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.show_chart,
                        size: 16,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Monitor critical system dependencies and infrastructure.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (state.isLoading && state.systemHealth == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: AppLoadingIndicator(message: 'Checking subsystem health...'),
                  )
                else ...[
                  // Card 1: Backend Server (Express API Layer)
                  _buildSubsystemCard(
                    icon: Icons.dns_outlined,
                    title: 'Backend\nServer',
                    subtitle: 'Express API\nLayer',
                    statusText: health.backend,
                    isOnline: health.isBackendOnline,
                  ),
                  const SizedBox(height: 16),

                  // Card 2: MongoDB (Primary Datastore)
                  _buildSubsystemCard(
                    icon: Icons.storage_outlined,
                    title: 'MongoDB',
                    subtitle: 'Primary\nDatastore',
                    statusText: health.mongoDB,
                    isOnline: health.isMongoConnected,
                  ),
                  const SizedBox(height: 16),

                  // Card 3: AI Provider (Gemini) (LLM & Embeddings)
                  _buildSubsystemCard(
                    icon: Icons.psychology_outlined,
                    title: 'AI Provider\n(Gemini)',
                    subtitle: 'LLM &\nEmbeddings',
                    statusText: health.aiProvider,
                    isOnline: health.isAiOnline,
                  ),
                  const SizedBox(height: 16),

                  // Card 4: Vector DB / Knowledge Embeddings
                  _buildSubsystemCard(
                    icon: Icons.hub_outlined,
                    title: 'Vector DB\n(Index)',
                    subtitle: 'Knowledge\nEmbeddings',
                    statusText: health.vectorDB,
                    isOnline: health.isVectorDbOnline,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubsystemCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String statusText,
    required bool isOnline,
  }) {
    final statusColor = isOnline ? const Color(0xFF10B981) : const Color(0xFFE11D48);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Dark rounded container icon matching Screenshot 2
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF1E232E),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF94A3B8),
              size: 28,
            ),
          ),
          const SizedBox(width: 18),

          // Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.replaceAll('\n', ' '),
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.replaceAll('\n', ' '),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Status with checkmark circle matching Screenshot 2
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                statusText,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Icon(
                  isOnline ? Icons.check : Icons.close,
                  size: 16,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
