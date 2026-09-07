import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/shell/main_shell.dart';
import 'state/auth_state.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';
import 'widgets/badges/status_chip.dart';
import 'widgets/buttons/app_button.dart';
import 'widgets/cards/app_card.dart';
import 'widgets/feedback/loading_indicator.dart';
import 'state/settings_state.dart';
import 'widgets/inputs/app_text_field.dart';
import 'widgets/layout/responsive_layout.dart';

/// Root Application Widget for MineIntel AI.
class MineIntelApp extends StatelessWidget {
  final Widget? home;

  const MineIntelApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final themeMode = ref.watch(themeModeProvider);
          return MaterialApp(
            title: 'MineIntel AI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: home ?? const AppGateway(),
          );
        },
      ),
    );
  }
}

/// Dynamic Authentication Gateway directing user based on active session state.
class AppGateway extends ConsumerStatefulWidget {
  const AppGateway({super.key});

  @override
  ConsumerState<AppGateway> createState() => _AppGatewayState();
}

class _AppGatewayState extends ConsumerState<AppGateway> {
  bool _showRegister = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    switch (authState.status) {
      case AuthStatus.initial:
        return const SplashScreen();
      case AuthStatus.authenticating:
        if (authState.user != null) {
          return const MainShell();
        }
        return const SplashScreen();
      case AuthStatus.authenticated:
        return const MainShell();
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        if (_showRegister) {
          return RegisterScreen(
            onNavigateToLogin: () => setState(() => _showRegister = false),
            onRegisterSuccess: () {
              // Automatically transitioned by Riverpod state
            },
          );
        }
        return LoginScreen(
          onNavigateToRegister: () => setState(() => _showRegister = true),
          onLoginSuccess: () {
            // Automatically transitioned by Riverpod state
          },
        );
    }
  }
}

/// Foundation verification screen showcasing Phase 2 scalable design system,
/// responsive breakpoints, reusable widgets, and cards.
class FoundationGalleryScreen extends StatefulWidget {
  const FoundationGalleryScreen({super.key});

  @override
  State<FoundationGalleryScreen> createState() => _FoundationGalleryScreenState();
}

class _FoundationGalleryScreenState extends State<FoundationGalleryScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      selectedIndex: _currentIndex,
      onDestinationSelected: (idx) {
        setState(() => _currentIndex = idx);
      },
      title: 'Executive Dashboard',
      username: 'mining_engineer',
      userRole: 'user',
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_outlined),
          tooltip: 'Notifications',
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Phase 02 Active: Scalable Architecture, Centralized Config, Design System & Reusable Widgets',
                      style: AppTypography.bodyMedium.copyWith(
                        color: const Color(0xFF166534),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Search Bar Component
            AppSearchField(
              controller: _searchController,
              hint: 'Search mining reports, documents, or extracted entities...',
              onChanged: (val) {},
            ),
            const SizedBox(height: 24),

            // Responsive Metrics Grid (Derived from reference image style)
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 1024;
                final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
                final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 1);

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isDesktop ? 1.4 : (isTablet ? 1.3 : 2.2),
                  children: const [
                    HeroMetricCard(
                      title: 'Ingested Documents',
                      value: '180',
                      progress: 0.75,
                    ),
                    MetricCard(
                      title: 'Extracted Records',
                      value: '2,150',
                      progress: 0.88,
                      progressColor: AppColors.accentTeal,
                      icon: Icons.table_chart_outlined,
                    ),
                    MetricCard(
                      title: 'Quality Score',
                      value: '94%',
                      progress: 0.94,
                      progressColor: AppColors.accentBlue,
                      icon: Icons.verified_outlined,
                    ),
                    MetricCard(
                      title: 'Active Reports',
                      value: '14',
                      subtitle: '4 awaiting reviewer approval',
                      icon: Icons.description_outlined,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // Reusable Buttons Showcase
            Text('Design System: Reusable Buttons', style: AppTypography.headlineSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppButton(
                  text: 'Primary Action',
                  icon: Icons.upload_file,
                  onPressed: () {},
                  variant: AppButtonVariant.primary,
                ),
                AppButton(
                  text: 'Secondary',
                  onPressed: () {},
                  variant: AppButtonVariant.secondary,
                ),
                AppButton(
                  text: 'Outlined',
                  icon: Icons.tune,
                  onPressed: () {},
                  variant: AppButtonVariant.outline,
                ),
                AppButton(
                  text: 'Critical / Delete',
                  icon: Icons.delete_outline,
                  onPressed: () {},
                  variant: AppButtonVariant.danger,
                ),
                AppButton(
                  text: 'Loading...',
                  isLoading: true,
                  onPressed: () {},
                  variant: AppButtonVariant.primary,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Reusable Badges & Chips
            Text('Design System: Status Chips & Badges', style: AppTypography.headlineSmall),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusChip(status: 'completed'),
                StatusChip(status: 'processing'),
                StatusChip(status: 'queued'),
                StatusChip(status: 'failed'),
                StatusChip(status: 'approved'),
                StatusChip(status: 'rejected'),
                SeverityChip(severity: 'critical'),
                SeverityChip(severity: 'error'),
                SeverityChip(severity: 'warning'),
                SeverityChip(severity: 'info'),
                CategoryChip(label: 'Production Report', isSelected: true),
                CategoryChip(label: 'Statutory Return'),
                CategoryChip(label: 'DGMS Safety'),
              ],
            ),
            const SizedBox(height: 28),

            // Telemetry Progress Bar
            Text('Design System: Ingestion Telemetry', style: AppTypography.headlineSmall),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Document Parsing & Extraction Pipeline', style: AppTypography.titleMedium),
                  const SizedBox(height: 12),
                  const AppProgressBar(
                    progress: 0.65,
                    label: 'Stage 3 of 4: AI Parameter & Entity Extraction',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
