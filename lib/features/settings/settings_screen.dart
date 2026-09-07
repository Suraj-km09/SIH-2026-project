import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/settings_model.dart';
import '../../state/auth_state.dart';
import '../../state/settings_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/status_chip.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/feedback/loading_indicator.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/layout/responsive_layout.dart';

/// Comprehensive User Settings & Preferences Screen.
/// Supports Profile/Account management, Language, Timezone, Theme,
/// and Notification channel preference toggles.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Profile Form Controllers
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _emailController;
  late final TextEditingController _departmentController;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  bool _isUpdatingProfile = false;
  bool _isChangingPassword = false;
  String? _profileFeedback;
  String? _passwordFeedback;
  bool _profileSuccess = false;
  bool _passwordSuccess = false;

  // Local state for notification switches before explicit save
  bool _emailNotif = true;
  bool _pushNotif = false;
  bool _reportAlerts = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final user = ref.read(authNotifierProvider).user;
    _emailController = TextEditingController(text: user?.email ?? '');
    _departmentController =
        TextEditingController(text: user?.department ?? '');

    final notifs = ref.read(settingsNotifierProvider).settings.notifications;
    _emailNotif = notifs.emailNotif;
    _pushNotif = notifs.pushNotif;
    _reportAlerts = notifs.reportAlerts;

    Future.microtask(() {
      ref.read(settingsNotifierProvider.notifier).loadSettings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    // Sync notification switches when settings state finishes loading
    if (!settingsState.isLoading &&
        _emailNotif == true &&
        _pushNotif == false &&
        _reportAlerts == true) {
      final notifs = settingsState.settings.notifications;
      _emailNotif = notifs.emailNotif;
      _pushNotif = notifs.pushNotif;
      _reportAlerts = notifs.reportAlerts;
    }

    return ResponsiveContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Settings & Preferences',
                      style: AppTypography.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure your profile credentials, display theme, language, and notification channels.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (settingsState.isSaving)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Feedback alerts
          if (settingsState.successMessage != null) ...[
            _buildAlertBanner(
              message: settingsState.successMessage!,
              isSuccess: true,
              onDismiss: () =>
                  ref.read(settingsNotifierProvider.notifier).clearMessages(),
            ),
            const SizedBox(height: 12),
          ],
          if (settingsState.errorMessage != null) ...[
            _buildAlertBanner(
              message: settingsState.errorMessage!,
              isSuccess: false,
              onDismiss: () =>
                  ref.read(settingsNotifierProvider.notifier).clearMessages(),
            ),
            const SizedBox(height: 12),
          ],

          // Tab Navigation Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(
                icon: Icon(Icons.person_outline, size: 18),
                text: 'Profile & Account',
              ),
              Tab(
                icon: Icon(Icons.palette_outlined, size: 18),
                text: 'Appearance & Locale',
              ),
              Tab(
                icon: Icon(Icons.notifications_outlined, size: 18),
                text: 'Notification Channels',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tab Views
          Expanded(
            child: settingsState.isLoading
                ? const Center(
                    child: AppLoadingIndicator(message: 'Loading settings...'),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProfileTab(context, user),
                      _buildAppearanceLocaleTab(
                          context, settingsState.settings),
                      _buildNotificationPreferencesTab(
                          context, settingsState.settings),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner({
    required String message,
    required bool isSuccess,
    required VoidCallback onDismiss,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSuccess ? AppColors.successBg : AppColors.errorBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSuccess ? AppColors.successBorder : AppColors.errorBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error_outline,
            size: 18,
            color: isSuccess ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: isSuccess ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: Profile & Account
  // =========================================================================
  Widget _buildProfileTab(BuildContext context, dynamic user) {
    return ListView(
      children: [
        // User Identity Card
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.heroSurface,
                child: Text(
                  (user?.username != null && user!.username.isNotEmpty)
                      ? user!.username[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textInverse,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user?.username ?? 'Mining Specialist',
                          style: AppTypography.headlineSmall,
                        ),
                        const SizedBox(width: 10),
                        StatusChip(
                          status: user?.role ?? 'user',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'No email configured',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (user?.department != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Department: ${user.department}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Update Profile Form
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _profileFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update Contact & Department',
                  style: AppTypography.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Updates the contact email and operational department associated with your account.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Official Email Address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!v.contains('@')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Mining Operational Division / Department',
                  controller: _departmentController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Department is required';
                    }
                    return null;
                  },
                ),
                if (_profileFeedback != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _profileFeedback!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _profileSuccess
                          ? AppColors.success
                          : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    text: 'Save Profile',
                    icon: Icons.save_outlined,
                    isLoading: _isUpdatingProfile,
                    onPressed: _handleUpdateProfile,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Change Password Form
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _passwordFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security & Password',
                  style: AppTypography.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Change your account password. Requires current credentials verification.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Current Password',
                  controller: _currentPasswordController,
                  isPassword: true,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Current password required'
                      : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'New Password',
                  controller: _newPasswordController,
                  isPassword: true,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'At least 6 chars' : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Confirm New Password',
                  controller: _confirmNewPasswordController,
                  isPassword: true,
                  validator: (v) {
                    if (v != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                if (_passwordFeedback != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _passwordFeedback!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _passwordSuccess
                          ? AppColors.success
                          : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    text: 'Change Password',
                    icon: Icons.lock_reset,
                    isLoading: _isChangingPassword,
                    onPressed: _handleChangePassword,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleUpdateProfile() async {
    if (!(_profileFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isUpdatingProfile = true;
      _profileFeedback = null;
    });

    final success = await ref
        .read(authNotifierProvider.notifier)
        .updateProfile(
          email: _emailController.text.trim(),
          department: _departmentController.text.trim(),
        );

    if (mounted) {
      setState(() {
        _isUpdatingProfile = false;
        _profileSuccess = success;
        _profileFeedback = success
            ? 'Profile updated successfully.'
            : 'Failed to update profile. Please try again.';
      });
    }
  }

  Future<void> _handleChangePassword() async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isChangingPassword = true;
      _passwordFeedback = null;
    });

    final success = await ref
        .read(authNotifierProvider.notifier)
        .changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );

    if (mounted) {
      setState(() {
        _isChangingPassword = false;
        _passwordSuccess = success;
        _passwordFeedback = success
            ? 'Password changed successfully.'
            : 'Failed to change password. Verify your current password.';
      });
      if (success) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();
      }
    }
  }

  // =========================================================================
  // TAB 2: Appearance & Locale
  // =========================================================================
  Widget _buildAppearanceLocaleTab(
      BuildContext context, UserSettings settings) {
    final isDark = settings.appearance.isDark;
    final activeLanguage = settings.language;
    final activeTimezone = settings.timezone;

    return ListView(
      children: [
        // Theme Selection Card
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UI Theme & Color Palette',
                style: AppTypography.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Switch between Light (Enterprise Neutral) and Dark (Deep Charcoal) modes.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 540;
                  final lightCard = _buildThemeCard(
                    title: 'Light Theme',
                    description: 'Crisp white canvas with high contrast',
                    isSelected: !isDark,
                    icon: Icons.light_mode_outlined,
                    onTap: () => ref
                        .read(settingsNotifierProvider.notifier)
                        .updateTheme('light'),
                  );
                  final darkCard = _buildThemeCard(
                    title: 'Dark Theme',
                    description: 'Low-glare dark palette for monitoring',
                    isSelected: isDark,
                    icon: Icons.dark_mode_outlined,
                    onTap: () => ref
                        .read(settingsNotifierProvider.notifier)
                        .updateTheme('dark'),
                  );

                  if (isCompact) {
                    return Column(
                      children: [
                        lightCard,
                        const SizedBox(height: 12),
                        darkCard,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: lightCard),
                      const SizedBox(width: 14),
                      Expanded(child: darkCard),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Language & Localization Card
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Language / भाषा',
                style: AppTypography.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Select interface and statutory reporting language.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 540;
                  final enCard = _buildLocaleCard(
                    title: 'English',
                    subtitle: 'Standard Indian Statutory & DGMS Terminology',
                    isSelected: activeLanguage == 'en',
                    code: 'en',
                    onTap: () => ref
                        .read(settingsNotifierProvider.notifier)
                        .updateLanguage('en'),
                  );
                  final hiCard = _buildLocaleCard(
                    title: 'हिन्दी (Hindi)',
                    subtitle: 'खनन शब्दावली एवं राजभाषा प्रपत्र',
                    isSelected: activeLanguage == 'hi',
                    code: 'hi',
                    onTap: () => ref
                        .read(settingsNotifierProvider.notifier)
                        .updateLanguage('hi'),
                  );

                  if (isCompact) {
                    return Column(
                      children: [
                        enCard,
                        const SizedBox(height: 12),
                        hiCard,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: enCard),
                      const SizedBox(width: 14),
                      Expanded(child: hiCard),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Timezone Preference Card
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Timezone & Date Localization',
                style: AppTypography.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Timestamp display across audit trails and production logs.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: activeTimezone,
                decoration: const InputDecoration(
                  labelText: 'Active Timezone',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Asia/Kolkata (IST)',
                    child: Text('Asia/Kolkata (IST, UTC+05:30)'),
                  ),
                  DropdownMenuItem(
                    value: 'UTC (+00:00)',
                    child: Text('Coordinated Universal Time (UTC)'),
                  ),
                  DropdownMenuItem(
                    value: 'Asia/Dubai (GST)',
                    child: Text('Asia/Dubai (GST, UTC+04:00)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(settingsNotifierProvider.notifier)
                        .updateTimezone(val);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeCard({
    required String title,
    required String description,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.heroSurface.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accentTeal : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 24,
                    color: isSelected
                        ? AppColors.accentTeal
                        : AppColors.textSecondary),
                const Spacer(),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: AppColors.accentTeal, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTypography.labelLarge.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocaleCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required String code,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.heroSurface.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accentTeal : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentTeal
                        : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    code.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.textInverse
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: AppColors.accentTeal, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTypography.labelLarge.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 3: Notification Channels
  // =========================================================================
  Widget _buildNotificationPreferencesTab(
      BuildContext context, UserSettings settings) {
    return ListView(
      children: [
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notification Dispatch Preferences',
                style: AppTypography.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Configure alerts for ingestion completions, statutory reviews, and validation alarms.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Email Notifications Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Email Notifications',
                  style: AppTypography.labelLarge,
                ),
                subtitle: Text(
                  'Receive statutory compliance and approval emails at your registered address.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                value: _emailNotif,
                onChanged: (val) {
                  setState(() => _emailNotif = val);
                },
              ),
              const Divider(),

              // Push Preference Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Push Notification Preference',
                  style: AppTypography.labelLarge,
                ),
                subtitle: Text(
                  'Store push preference flag in backend. (Note: Device FCM/APNs services are disabled per architecture).',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                value: _pushNotif,
                onChanged: (val) {
                  setState(() => _pushNotif = val);
                },
              ),
              const Divider(),

              // Report Alerts Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Statutory Report Alerts',
                  style: AppTypography.labelLarge,
                ),
                subtitle: Text(
                  'Immediate notices on reviewer rejections, SLA deadlines, and audit inspections.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                value: _reportAlerts,
                onChanged: (val) {
                  setState(() => _reportAlerts = val);
                },
              ),
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerRight,
                child: AppButton(
                  text: 'Save Preferences',
                  icon: Icons.save_outlined,
                  onPressed: () {
                    ref
                        .read(settingsNotifierProvider.notifier)
                        .updateNotificationPreferences(
                          emailNotif: _emailNotif,
                          pushNotif: _pushNotif,
                          reportAlerts: _reportAlerts,
                        );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
