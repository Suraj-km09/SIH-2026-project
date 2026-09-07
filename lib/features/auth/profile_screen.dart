import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../state/auth_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/status_chip.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/inputs/app_text_field.dart';

/// User Profile & Account Management Screen.
/// Displays authenticated session details and supports:
/// - PUT /auth/profile (email, department)
/// - PUT /auth/change-password (currentPassword, newPassword)
/// - POST /auth/logout (session termination)
class ProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback? onLogout;

  const ProfileScreen({super.key, this.onLogout});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _emailController;
  late final TextEditingController _departmentController;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  bool _isUpdatingProfile = false;
  bool _isChangingPassword = false;
  String? _profileMessage;
  String? _passwordMessage;
  bool _profileSuccess = false;
  bool _passwordSuccess = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).user;
    _emailController = TextEditingController(text: user?.email ?? '');
    _departmentController = TextEditingController(text: user?.department ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _departmentController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateProfile() async {
    if (!(_profileFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isUpdatingProfile = true;
      _profileMessage = null;
    });

    final success = await ref.read(authNotifierProvider.notifier).updateProfile(
          email: _emailController.text.trim(),
          department: _departmentController.text.trim(),
        );

    if (mounted) {
      setState(() {
        _isUpdatingProfile = false;
        _profileSuccess = success;
        _profileMessage = success
            ? 'Profile updated successfully.'
            : 'Failed to update profile. Please try again.';
      });
    }
  }

  Future<void> _handleChangePassword() async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isChangingPassword = true;
      _passwordMessage = null;
    });

    final success = await ref.read(authNotifierProvider.notifier).changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );

    if (mounted) {
      setState(() {
        _isChangingPassword = false;
        _passwordSuccess = success;
        _passwordMessage = success
            ? 'Password changed successfully.'
            : 'Failed to change password. Please verify your current password.';
      });

      if (success) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();
      }
    }
  }

  Future<void> _handleLogout() async {
    await ref.read(authNotifierProvider.notifier).logout();
    widget.onLogout?.call();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Account Summary Card
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.heroSurface,
                      child: Text(
                        (user?.username.isNotEmpty ?? false)
                            ? user!.username[0].toUpperCase()
                            : 'U',
                        style: AppTypography.headlineMedium.copyWith(color: AppColors.textInverse),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(user?.username ?? 'Mining Professional', style: AppTypography.headlineSmall),
                              const SizedBox(width: 12),
                              _buildRoleBadge(user?.role ?? 'user'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user?.email ?? 'No email associated',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Department: ${user?.department ?? 'General Mining Operations'}',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      text: 'Log Out',
                      icon: Icons.logout,
                      variant: AppButtonVariant.outline,
                      onPressed: _handleLogout,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Profile Details Form
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _profileFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Profile Information', style: AppTypography.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Update your contact email and designated mining department.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      if (_profileMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _profileSuccess
                                ? AppColors.success.withValues(alpha: 0.08)
                                : AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _profileSuccess
                                  ? AppColors.success.withValues(alpha: 0.3)
                                  : AppColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _profileSuccess ? Icons.check_circle_outline : Icons.error_outline,
                                color: _profileSuccess ? AppColors.success : AppColors.error,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _profileMessage!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: _profileSuccess ? AppColors.success : AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      AppTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'geologist@mineintel.ai',
                        prefixIcon: Icons.email_outlined,
                        validator: (val) {
                          if (val != null && val.trim().isNotEmpty) {
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val.trim())) {
                              return 'Enter a valid email address';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _departmentController,
                        label: 'Department / Mining Directorate',
                        hint: 'e.g. Directorate General of Mines Safety (DGMS)',
                        prefixIcon: Icons.business_outlined,
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: AppButton(
                          text: 'Save Profile Changes',
                          isLoading: _isUpdatingProfile,
                          icon: Icons.save_outlined,
                          onPressed: _handleUpdateProfile,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 3. Change Password Card
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _passwordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Security & Password', style: AppTypography.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Update your account access password regularly.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      if (_passwordMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _passwordSuccess
                                ? AppColors.success.withValues(alpha: 0.08)
                                : AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _passwordSuccess
                                  ? AppColors.success.withValues(alpha: 0.3)
                                  : AppColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _passwordSuccess ? Icons.check_circle_outline : Icons.error_outline,
                                color: _passwordSuccess ? AppColors.success : AppColors.error,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _passwordMessage!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: _passwordSuccess ? AppColors.success : AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      AppTextField(
                        controller: _currentPasswordController,
                        label: 'Current Password',
                        hint: 'Enter your current password',
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Current password is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _newPasswordController,
                        label: 'New Password',
                        hint: 'Minimum 6 characters',
                        prefixIcon: Icons.lock_reset_outlined,
                        isPassword: true,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'New password is required';
                          }
                          if (val.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _confirmNewPasswordController,
                        label: 'Confirm New Password',
                        hint: 'Re-enter new password',
                        prefixIcon: Icons.check_outlined,
                        isPassword: true,
                        validator: (val) {
                          if (val != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: AppButton(
                          text: 'Update Password',
                          isLoading: _isChangingPassword,
                          icon: Icons.key_outlined,
                          onPressed: _handleChangePassword,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    switch (role) {
      case AppConstants.roleAdmin:
        return const StatusChip(status: 'admin');
      case AppConstants.roleReviewer:
        return const StatusChip(status: 'reviewer');
      case AppConstants.roleUser:
      default:
        return const StatusChip(status: 'user');
    }
  }
}
