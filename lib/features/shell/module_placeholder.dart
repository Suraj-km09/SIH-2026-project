import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/status_chip.dart';
import '../../widgets/cards/app_card.dart';

/// Clean, professional placeholder for MineIntel modules scheduled for upcoming phases.
class ModulePlaceholder extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String targetPhase;
  final List<String> plannedFeatures;

  const ModulePlaceholder({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.targetPhase,
    required this.plannedFeatures,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Module Card
              AppCard(
                padding: const EdgeInsets.all(28),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.heroSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: AppColors.textInverse, size: 32),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(title, style: AppTypography.headlineMedium),
                              const StatusChip(
                                status: 'active',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Capabilities Preview Card
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Architectural Blueprint & Planned Features', style: AppTypography.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Documented API endpoints and capabilities implemented in $targetPhase.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ...plannedFeatures.map((feat) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: AppColors.accentTeal,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(feat, style: AppTypography.bodyMedium),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
