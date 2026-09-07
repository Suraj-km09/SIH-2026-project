import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/auth_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/inputs/app_text_field.dart';

/// Clean registration screen for new MineIntel AI users.
/// Implements strictly documented parameters: POST /auth/register (username, password, optional email).
class RegisterScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToLogin;
  final VoidCallback? onRegisterSuccess;

  const RegisterScreen({
    super.key,
    this.onNavigateToLogin,
    this.onRegisterSuccess,
  });

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _localError;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _localError = null;
    });

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await ref.read(authNotifierProvider.notifier).register(
          username,
          password,
          email.isNotEmpty ? email : null,
        );

    if (mounted) {
      if (success) {
        widget.onRegisterSuccess?.call();
      } else {
        final authState = ref.read(authNotifierProvider);
        setState(() {
          _localError = authState.errorMessage ?? 'Registration failed. Username may already exist.';
        });
      }
    }
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
                    // Brand Icon
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.heroSurface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.person_add_outlined,
                          color: AppColors.textInverse,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Create MineIntel Account',
                      style: AppTypography.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Register to access statutory compliance documents, data extraction, and mining analytics.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Error Banner
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
                      label: 'Username',
                      hint: 'e.g. geologist_roy',
                      prefixIcon: Icons.badge_outlined,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Username is required';
                        }
                        if (val.trim().length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(val.trim())) {
                          return 'Only letters, numbers, hyphens, and underscores allowed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Optional Email Input
                    AppTextField(
                      controller: _emailController,
                      label: 'Email (Optional)',
                      hint: 'name@mining-directorate.gov',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
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

                    // Password Input
                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Minimum 6 characters',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Password is required';
                        }
                        if (val.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Input
                    AppTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      hint: 'Re-enter your password',
                      prefixIcon: Icons.lock_reset_outlined,
                      isPassword: true,
                      validator: (val) {
                        if (val != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Register Button
                    AppButton(
                      text: 'Create Account',
                      isLoading: isLoading,
                      icon: Icons.how_to_reg_outlined,
                      onPressed: _handleRegister,
                    ),
                    const SizedBox(height: 20),

                    // Navigation Back to Login
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already registered?',
                          style: AppTypography.bodySmall,
                        ),
                        TextButton(
                          onPressed: widget.onNavigateToLogin,
                          child: Text(
                            'Sign In',
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
