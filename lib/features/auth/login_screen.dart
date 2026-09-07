import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/env_config.dart';
import '../../state/app_state.dart';
import '../../state/auth_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/status_chip.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/dialogs/app_dialog.dart';
import '../../widgets/inputs/app_text_field.dart';

/// Clean, responsive authentication screen for MineIntel AI.
/// Connects to POST /auth/login and offers seamless navigation to registration.
class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToRegister;
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    super.key,
    this.onNavigateToRegister,
    this.onLoginSuccess,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _localError = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    final success = await ref
        .read(authNotifierProvider.notifier)
        .login(username, password);

    if (mounted) {
      if (success) {
        widget.onLoginSuccess?.call();
      } else {
        final authState = ref.read(authNotifierProvider);
        setState(() {
          _localError = authState.errorMessage ?? 'Authentication failed. Please check credentials.';
        });
      }
    }
  }

  void _fillCredentials(String user, String pass) {
    setState(() {
      _usernameController.text = user;
      _passwordController.text = pass;
    });
  }

  void _showForgotPasswordDialog() {
    AppDialog.alert(
      context,
      title: 'Password Assistance',
      message:
          'Unauthenticated password resets are strictly restricted under mining governance compliance.\n\n'
          'To reset your password:\n'
          '• Contact your Mining Directorate Administrator.\n'
          '• Or change your password from the Profile screen once logged in.',
      buttonText: 'Understood',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 380;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 14 : 24, vertical: isCompact ? 16 : 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AppCard(
              padding: EdgeInsets.all(isCompact ? 16 : 30),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Header
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.heroSurface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.insights,
                          color: AppColors.textInverse,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Welcome to MineIntel AI',
                      style: AppTypography.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in with your operational credentials to access your mining intelligence workspace.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Environment Status Pill & Mock Toggle
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        StatusChip(
                          status: EnvConfig.useMockData ? 'mock_mode' : 'active',
                        ),
                        TextButton(
                          onPressed: () {
                            final current = EnvConfig.useMockData;
                            ref.read(envConfigProvider.notifier).toggleMockMode(!current);
                            setState(() {});
                          },
                          child: Text(
                            EnvConfig.useMockData ? 'Switch to Live API' : 'Switch to Mock Mode',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.accentTeal),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Error Message Banner
                    if (_localError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _localError!,
                                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Username Input
                    AppTextField(
                      controller: _usernameController,
                      label: 'Username / User ID',
                      hint: 'Enter your mining username',
                      prefixIcon: Icons.person_outline,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Username is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Input
                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter your password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Forgot Password Action
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: Text(
                          'Forgot Password?',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.accentTeal),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    AppButton(
                      text: 'Sign In to Workspace',
                      isLoading: isLoading,
                      icon: Icons.login,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: 20),

                    // Quick Demo Credentials Selector
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('QUICK ROLE SELECTION (TESTING)', style: AppTypography.labelSmall),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              ActionChip(
                                label: const Text('Admin', style: TextStyle(fontSize: 12)),
                                avatar: const Icon(Icons.shield_outlined, size: 14),
                                onPressed: () => _fillCredentials('admin', 'admin123'),
                              ),
                              ActionChip(
                                label: const Text('Reviewer', style: TextStyle(fontSize: 12)),
                                avatar: const Icon(Icons.rate_review_outlined, size: 14),
                                onPressed: () => _fillCredentials('reviewer', 'reviewer123'),
                              ),
                              ActionChip(
                                label: const Text('User', style: TextStyle(fontSize: 12)),
                                avatar: const Icon(Icons.person_outline, size: 14),
                                onPressed: () => _fillCredentials('mining_engineer', 'engineer123'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Register Navigation Link
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: AppTypography.bodySmall,
                        ),
                        TextButton(
                          onPressed: widget.onNavigateToRegister,
                          child: Text(
                            'Register Now',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.accentTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
