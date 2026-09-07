import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';
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
class ResponsiveScaffold extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (ctx, isMobile, isTablet, isDesktop) {
        if (isDesktop) {
          return _buildDesktopLayout(ctx);
        } else if (isTablet) {
          return _buildTabletLayout(ctx);
        } else {
          return _buildMobileLayout(ctx);
        }
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Collapsible / Categorized Desktop Sidebar
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.border, width: 1)),
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
                            Text('MineIntel AI', style: AppTypography.headlineSmall),
                            Text(
                              'Mining Intelligence Platform',
                              style: AppTypography.labelSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // Scrollable Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: [
                      _buildNavSectionHeader('OPERATIONS'),
                      _buildSidebarItem(0, Icons.dashboard_outlined, 'Dashboard'),
                      _buildSidebarItem(1, Icons.terminal_outlined, 'Command Centre'),
                      _buildSidebarItem(2, Icons.folder_outlined, 'Documents'),
                      _buildSidebarItem(3, Icons.table_chart_outlined, 'Data Extraction'),
                      _buildSidebarItem(4, Icons.rule_outlined, 'Validation'),

                      const SizedBox(height: 12),
                      _buildNavSectionHeader('INTELLIGENCE & AI'),
                      _buildSidebarItem(5, Icons.auto_awesome_outlined, 'AI Assistant'),
                      _buildSidebarItem(6, Icons.travel_explore_outlined, 'Knowledge Base'),
                      _buildSidebarItem(7, Icons.trending_up_outlined, 'Mining Analytics'),
                      _buildSidebarItem(8, Icons.map_outlined, 'GIS Spatial Map'),
                      _buildSidebarItem(9, Icons.hub_outlined, 'Topics'),
                      _buildSidebarItem(10, Icons.smart_toy_outlined, 'Autonomous Agents'),

                      const SizedBox(height: 12),
                      _buildNavSectionHeader('GOVERNANCE'),
                      _buildSidebarItem(11, Icons.description_outlined, 'Statutory Reports'),
                      if (userRole == 'reviewer' || userRole == 'admin')
                        _buildSidebarItem(12, Icons.rate_review_outlined, 'Review Queue'),
                      _buildSidebarItem(13, Icons.history_outlined, 'Audit Trail'),
                      if (userRole == 'admin')
                        _buildSidebarItem(14, Icons.admin_panel_settings_outlined, 'Admin Console'),

                      const SizedBox(height: 12),
                      _buildNavSectionHeader('SYSTEM'),
                      _buildSidebarItem(15, Icons.notifications_none_outlined, 'Notifications'),
                      _buildSidebarItem(16, Icons.settings_outlined, 'Settings'),
                      _buildSidebarItem(17, Icons.help_outline, 'Help & FAQs'),
                    ],
                  ),
                ),

                // User Identity Footer
                const Divider(),
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
                              style: AppTypography.labelMedium,
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
    return Scaffold(
      backgroundColor: AppColors.background,
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

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          title,
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
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

  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.headlineMedium,
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

  Widget _buildNavSectionHeader(String label) {
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

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
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
              color: isSelected ? AppColors.surfaceMuted : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
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
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary, size: 20),
      title: Text(title, style: AppTypography.labelMedium),
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
