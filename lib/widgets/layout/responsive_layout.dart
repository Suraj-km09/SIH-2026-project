import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/responsive.dart';
import '../../state/settings_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Builder providing active breakpoint flags.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < Responsive.mobileBreakpoint;
        final isTablet = width >= Responsive.mobileBreakpoint && width < Responsive.tabletBreakpoint;
        final isDesktop = width >= Responsive.tabletBreakpoint;
        return builder(ctx, isMobile, isTablet, isDesktop);
      },
    );
  }
}

/// Responsive Centered Content Container with adaptive maximum width and padding.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPadding = Responsive.value<EdgeInsetsGeometry>(
      context,
      smallMobile: const EdgeInsets.all(12),
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? defaultPadding,
          child: child,
        ),
      ),
    );
  }
}

/// Adaptive Master-Detail View:
/// - Desktop / Tablet: Displays Master list on left and Detail panel on right.
/// - Mobile: Shows master or detail full-screen with back navigation.
class AdaptiveMasterDetail extends StatelessWidget {
  final Widget master;
  final Widget detail;
  final double masterWidth;
  final bool showDetailOnMobile;
  final VoidCallback? onBackToMaster;

  const AdaptiveMasterDetail({
    super.key,
    required this.master,
    required this.detail,
    this.masterWidth = 360,
    this.showDetailOnMobile = false,
    this.onBackToMaster,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (ctx, isMobile, isTablet, isDesktop) {
        if (!isMobile) {
          // Multi-panel layout on Tablet and Desktop
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: masterWidth,
                child: master,
              ),
              const VerticalDivider(width: 1),
              Expanded(child: detail),
            ],
          );
        }

        // Single-panel layout on Mobile
        if (showDetailOnMobile) {
          return Column(
            children: [
              if (onBackToMaster != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Back to list'),
                    onPressed: onBackToMaster,
                  ),
                ),
              Expanded(child: detail),
            ],
          );
        }
        return master;
      },
    );
  }
}

/// Responsive Scaffold providing Mobile Bottom Navigation, Tablet Rail,
/// and Windows Desktop Persistent Sidebar Navigation.
class ResponsiveScaffold extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final String? userRole;
  final String? username;

  const ResponsiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    required this.title,
    this.actions,
    this.userRole,
    this.username,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveBuilder(
      builder: (ctx, isMobile, isTablet, isDesktop) {
        if (isDesktop) {
          return _buildDesktopLayout(ctx);
        } else if (isTablet) {
          return _buildTabletLayout(ctx);
        } else {
          return _buildMobileLayout(ctx, ref);
        }
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final sidebarColor = colorScheme.surface;
    final bodyBgColor = colorScheme.surfaceContainerHighest;
    final sidebarBorderColor = isDark ? const Color(0xFF374151) : AppColors.border;

    return Scaffold(
      backgroundColor: bodyBgColor,
      body: Row(
        children: [
          // Collapsible / Categorized Desktop Sidebar
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: sidebarColor,
              border: Border(right: BorderSide(color: sidebarBorderColor, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Branding Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.heroSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.insights,
                          color: AppColors.textInverse,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MineIntel AI', style: AppTypography.headlineSmall.copyWith(color: colorScheme.onSurface)),
                            Text(
                              'Mining Intelligence Platform',
                              style: AppTypography.labelSmall.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: sidebarBorderColor),

                // Scrollable Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: [
                      _buildNavSectionHeader('OPERATIONS', context),
                      _buildSidebarItem(0, Icons.dashboard_outlined, 'Dashboard', context),
                      _buildSidebarItem(1, Icons.terminal_outlined, 'Command Centre', context),
                      _buildSidebarItem(2, Icons.folder_outlined, 'Documents', context),
                      _buildSidebarItem(3, Icons.table_chart_outlined, 'Data Extraction', context),
                      _buildSidebarItem(4, Icons.rule_outlined, 'Validation', context),

                      const SizedBox(height: 12),
                      _buildNavSectionHeader('INTELLIGENCE & AI', context),
                      _buildSidebarItem(5, Icons.auto_awesome_outlined, 'AI Assistant', context),
                      _buildSidebarItem(6, Icons.travel_explore_outlined, 'Knowledge Base', context),
                      _buildSidebarItem(7, Icons.trending_up_outlined, 'Mining Analytics', context),
                      _buildSidebarItem(8, Icons.map_outlined, 'GIS Spatial Map', context),
                      _buildSidebarItem(9, Icons.hub_outlined, 'Topics', context),
                      _buildSidebarItem(10, Icons.smart_toy_outlined, 'Autonomous Agents', context),

                      const SizedBox(height: 12),
                      _buildNavSectionHeader('GOVERNANCE', context),
                      _buildSidebarItem(11, Icons.description_outlined, 'Statutory Reports', context),
                      if (userRole == 'reviewer' || userRole == 'admin')
                        _buildSidebarItem(12, Icons.rate_review_outlined, 'Review Queue', context),
                      _buildSidebarItem(13, Icons.history_outlined, 'Audit Trail', context),
                      if (userRole == 'admin')
                        _buildSidebarItem(14, Icons.admin_panel_settings_outlined, 'Admin Console', context),

                      const SizedBox(height: 12),
                      _buildNavSectionHeader('SYSTEM', context),
                      _buildSidebarItem(15, Icons.notifications_none_outlined, 'Notifications', context),
                      _buildSidebarItem(16, Icons.settings_outlined, 'Settings', context),
                      _buildSidebarItem(17, Icons.help_outline, 'Help & FAQs', context),
                    ],
                  ),
                ),

                // User Identity Footer
                Divider(color: sidebarBorderColor),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.heroSurface,
                        child: Text(
                          (username != null && username!.isNotEmpty)
                              ? username![0].toUpperCase()
                              : 'U',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textInverse,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username ?? 'User',
                              style: AppTypography.labelMedium.copyWith(color: colorScheme.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              userRole?.toUpperCase() ?? 'USER',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.accentTeal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Viewport
          Expanded(
            child: Column(
              children: [
                _buildTopAppBar(context),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bodyBgColor = colorScheme.surfaceContainerHighest;

    return Scaffold(
      backgroundColor: bodyBgColor,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _mapToRailIndex(selectedIndex),
            onDestinationSelected: (railIdx) {
              if (railIdx == 4) {
                _showMobileMoreSheet(context);
              } else {
                onDestinationSelected(_mapFromRailIndex(railIdx));
              }
            },
            labelType: NavigationRailLabelType.selected,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.heroSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.insights, color: Colors.white, size: 20),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder),
                label: Text('Documents'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: Text('AI Assistant'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.description_outlined),
                selectedIcon: Icon(Icons.description),
                label: Text('Reports'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.more_horiz),
                label: Text('More'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                _buildTopAppBar(context),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bodyBgColor = theme.colorScheme.surfaceContainerHighest;

    return Scaffold(
      backgroundColor: bodyBgColor,
      drawer: _buildMobileDrawer(context, ref),
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
            tooltip: 'Open Navigation Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          title,
          style: AppTypography.headlineMedium.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: actions,
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _mapToMobileIndex(selectedIndex),
        onDestinationSelected: (mobileIdx) {
          if (mobileIdx == 4) {
            _showMobileMoreSheet(context);
          } else {
            onDestinationSelected(_mapFromMobileIndex(mobileIdx));
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Documents',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Assistant',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu),
            label: 'More',
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Drawer(
      backgroundColor: const Color(0xFF1B202A),
      child: SafeArea(
        child: Column(
          children: [
            // Top Theme Toggle Header matching Screenshot 3
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      color: Colors.white70,
                      size: 22,
                    ),
                    tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                    onPressed: () {
                      ref.read(settingsNotifierProvider.notifier).updateTheme(isDark ? 'light' : 'dark');
                    },
                  ),
                ],
              ),
            ),

            // Navigation Sections matching Screenshot 3
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildDrawerSectionHeader('INTELLIGENCE'),
                  _buildDrawerItem(context, 6, Icons.storage_outlined, 'Knowledge Base'),
                  _buildDrawerItem(context, 5, Icons.chat_bubble_outline, 'AI Assistant'),
                  _buildDrawerItem(context, 7, Icons.bar_chart_outlined, 'Analytics'),
                  _buildDrawerItem(context, 9, Icons.auto_awesome_outlined, 'Intelligence'),
                  _buildDrawerItem(context, 9, Icons.tag, 'Topics'),

                  const SizedBox(height: 16),
                  _buildDrawerSectionHeader('GOVERNANCE'),
                  _buildDrawerItem(context, 11, Icons.description_outlined, 'Reports'),
                  _buildDrawerItem(context, 13, Icons.receipt_long_outlined, 'Audit Trail'),
                  if (userRole == 'admin')
                    _buildDrawerItem(context, 14, Icons.group_outlined, 'User Management'),
                  if (userRole == 'reviewer' || userRole == 'admin')
                    _buildDrawerItem(context, 12, Icons.fact_check_outlined, 'Pending Reviews'),

                  const SizedBox(height: 16),
                  _buildDrawerSectionHeader('SYSTEM'),
                  _buildDrawerItem(context, 18, Icons.show_chart, 'System Health'),
                  _buildDrawerItem(context, 17, Icons.help_outline, 'Help & Support'),
                ],
              ),
            ),

            // Profile Identity Footer matching Screenshot 3
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF2D3748), width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF262C38),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD97706), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        (username != null && username!.isNotEmpty) ? username![0].toUpperCase() : 'V',
                        style: const TextStyle(
                          color: Color(0xFFD97706),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username ?? 'vishal',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userRole?.toUpperCase() ?? 'ADMIN',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF262C38) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: const Color(0xFFD97706), width: 1.5) : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? const Color(0xFFD97706) : Colors.white70,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFD97706) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          onDestinationSelected(index);
        },
      ),
    );
  }

  Widget _buildDrawerSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final appBarColor = colorScheme.surface;
    final borderColor = isDark ? const Color(0xFF374151) : AppColors.border;
    final titleColor = colorScheme.onSurface;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: appBarColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))]
            : [BoxShadow(color: AppColors.border.withValues(alpha: 0.5), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.headlineMedium.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: actions ?? [],
          ),
        ],
      ),
    );
  }

  Widget _buildNavSectionHeader(String label, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 12, bottom: 6),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label, BuildContext context) {
    final isSelected = selectedIndex == index;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final selectedBg = isDark ? const Color(0xFF374151) : AppColors.surfaceMuted;
    final selectedTextColor = colorScheme.onSurface;
    final unselectedTextColor = isDark ? AppColors.textTertiary : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onDestinationSelected(index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? selectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? selectedTextColor : unselectedTextColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected ? selectedTextColor : unselectedTextColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMobileMoreSheet(BuildContext context) {
    final theme = Theme.of(context);
    final sheetBg = theme.colorScheme.surface;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.85;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              children: [
              Text('More Operations & Governance', style: AppTypography.headlineSmall),
              const SizedBox(height: 12),
              _buildMoreTile(ctx, 1, Icons.terminal_outlined, 'Command Centre'),
              _buildMoreTile(ctx, 3, Icons.table_chart_outlined, 'Data Extraction'),
              _buildMoreTile(ctx, 4, Icons.rule_outlined, 'Validation'),
              _buildMoreTile(ctx, 6, Icons.travel_explore_outlined, 'Knowledge Base'),
              _buildMoreTile(ctx, 7, Icons.trending_up_outlined, 'Mining Analytics'),
              _buildMoreTile(ctx, 8, Icons.map_outlined, 'GIS Spatial Map'),
              _buildMoreTile(ctx, 9, Icons.hub_outlined, 'Topics'),
              _buildMoreTile(ctx, 10, Icons.smart_toy_outlined, 'Autonomous Agents'),
              if (userRole == 'reviewer' || userRole == 'admin')
                _buildMoreTile(ctx, 12, Icons.rate_review_outlined, 'Review Queue'),
              _buildMoreTile(ctx, 13, Icons.history_outlined, 'Audit Trail'),
              if (userRole == 'admin')
                _buildMoreTile(ctx, 14, Icons.admin_panel_settings_outlined, 'Admin Console'),
              _buildMoreTile(ctx, 15, Icons.notifications_none_outlined, 'Notifications'),
              _buildMoreTile(ctx, 16, Icons.settings_outlined, 'Settings'),
              _buildMoreTile(ctx, 17, Icons.help_outline, 'Help & FAQs'),
            ],
          ),
        ),
      );
    },
  );
  }

  Widget _buildMoreTile(BuildContext ctx, int index, IconData icon, String title) {
    final colorScheme = Theme.of(ctx).colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.onSurface, size: 20),
      title: Text(title, style: AppTypography.labelMedium.copyWith(color: colorScheme.onSurface)),
      dense: true,
      onTap: () {
        Navigator.pop(ctx);
        onDestinationSelected(index);
      },
    );
  }

  int _mapToMobileIndex(int fullIndex) {
    if (fullIndex == 0) return 0;
    if (fullIndex == 2) return 1;
    if (fullIndex == 5) return 2;
    if (fullIndex == 11) return 3;
    return 4;
  }

  int _mapFromMobileIndex(int mobileIdx) {
    if (mobileIdx == 0) return 0;
    if (mobileIdx == 1) return 2;
    if (mobileIdx == 2) return 5;
    if (mobileIdx == 3) return 11;
    return 0;
  }

  int _mapToRailIndex(int fullIndex) => _mapToMobileIndex(fullIndex);
  int _mapFromRailIndex(int railIdx) => _mapFromMobileIndex(railIdx);
}
