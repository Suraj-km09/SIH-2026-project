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

  String? _errorMessage;
  Map<String, String> _fieldErrors = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    if (_errorMessage != null || _fieldErrors.isNotEmpty) {
      setState(() {
        _errorMessage = null;
        _fieldErrors = {};
      });
    }
  }

  void _showAlertSnackBar(String message, {bool isWarning = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isWarning ? Icons.warning_amber_rounded : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: isWarning ? const Color(0xFFD97706) : AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _cleanErrorMessage(String raw, String username) {
    var msg = raw.trim();

    // Strip technical exception and wrapper prefixes
    msg = msg.replaceAll(
      RegExp(r'^(?:DioException|Exception|Error|ServerFailure|AuthFailure|ValidationFailure|NetworkFailure|ValidationException|AuthException):\s*', caseSensitive: false),
      '',
    );
    msg = msg.replaceAll(
      RegExp(r'^Validation (?:failed|error):\s*', caseSensitive: false),
      '',
    );
    msg = msg.replaceAll(
      RegExp(r'\[(?:bad response|connection error|connection timeout|receive timeout|send timeout)\]\s*', caseSensitive: false),
      '',
    );
    msg = msg.replaceAll(
      RegExp(r'HTTP\s*\d{3}\s*(?::|-)?\s*', caseSensitive: false),
      '',
    );
    msg = msg.replaceAll(
      RegExp(r'^\d{3}\s+(?:Unauthorized|Bad Request|Internal Server Error|Forbidden|Conflict)\s*', caseSensitive: false),
      '',
    );

    final lower = msg.toLowerCase();
    if (lower.contains('already exists') || lower.contains('user_exists')) {
      return username.isNotEmpty
          ? 'A user with username "$username" already exists. Please choose a different username.'
          : 'A user with this username already exists. Please choose a different username.';
    }
    if (lower.contains('503') || lower.contains('unavailable') || lower.contains('timeout')) {
      return 'Server is taking longer than expected to respond. Please try again.';
    }
    if (lower.contains('network') || lower.contains('connection') || lower.contains('socket')) {
      return 'Network connection error. Check your device connectivity and try again.';
    }

    return msg.isNotEmpty ? msg : 'Unable to create account. Please check your details and try again.';
  }

  Future<void> _handleRegister() async {
    // Guard against duplicate concurrent submissions
    if (_isSubmitting || ref.read(authNotifierProvider).isLoading) return;

    _clearErrors();

    if (!(_formKey.currentState?.validate() ?? false)) {
      const valMsg = 'Please complete all required fields correctly.';
      setState(() {
        _errorMessage = valMsg;
      });
      _showAlertSnackBar(valMsg, isWarning: true);
      return;
    }

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await ref.read(authNotifierProvider.notifier).register(
            username,
            password,
            email.isNotEmpty ? email : null,
          );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Account created successfully! Welcome, $username.',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        widget.onRegisterSuccess?.call();
      } else {
        final authState = ref.read(authNotifierProvider);
        final rawError = authState.errorMessage ?? 'Registration failed. Please check your details.';
        final isVal = authState.isValidationError;
        final fErrors = Map<String, String>.from(authState.fieldErrors ?? {});
        final message = _cleanErrorMessage(
          authState.validationMessage ?? rawError,
          username,
        );

        if (rawError.toLowerCase().contains('already exists') || rawError.contains('USER_EXISTS')) {
          fErrors['username'] = 'Username is already taken';
        }

        setState(() {
          _errorMessage = message;
          _fieldErrors = fErrors;
        });

        _showAlertSnackBar(message, isWarning: isVal);
      }
    } catch (e) {
      if (mounted) {
        final message = _cleanErrorMessage(e.toString(), username);
        setState(() {
          _errorMessage = message;
        });
        _showAlertSnackBar(message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = _isSubmitting || authState.isLoading;

    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 380;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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

                    // Error Message Alert Banner (Clean, user-friendly, no technical error types)
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() {
                                _errorMessage = null;
                                _fieldErrors.clear();
                              }),
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(Icons.close, size: 16, color: AppColors.textSecondary),
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
                      enabled: !isLoading,
                      errorText: _fieldErrors['username'],
                      onChanged: (_) {
                        if (_fieldErrors.containsKey('username')) {
                          setState(() => _fieldErrors.remove('username'));
                        }
                        if (_errorMessage != null) {
                          setState(() => _errorMessage = null);
                        }
                      },
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
                      enabled: !isLoading,
                      errorText: _fieldErrors['email'],
                      onChanged: (_) {
                        if (_fieldErrors.containsKey('email')) {
                          setState(() => _fieldErrors.remove('email'));
                        }
                      },
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
                      enabled: !isLoading,
                      errorText: _fieldErrors['password'],
                      onChanged: (_) {
                        if (_fieldErrors.containsKey('password')) {
                          setState(() => _fieldErrors.remove('password'));
                        }
                        if (_errorMessage != null) {
                          setState(() => _errorMessage = null);
                        }
                      },
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
                      enabled: !isLoading,
                      errorText: _fieldErrors['confirmPassword'],
                      onChanged: (_) {
                        if (_fieldErrors.containsKey('confirmPassword')) {
                          setState(() => _fieldErrors.remove('confirmPassword'));
                        }
                      },
                      validator: (val) {
                        if (val != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Register Button with integrated loader
                    AppButton(
                      text: isLoading ? 'Creating Account...' : 'Create Account',
                      isLoading: isLoading,
                      icon: isLoading ? null : Icons.how_to_reg_outlined,
                      onPressed: isLoading ? null : _handleRegister,
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
                          onPressed: isLoading ? null : widget.onNavigateToLogin,
                          child: Text(
                            'Sign In',
                            style: AppTypography.labelMedium.copyWith(
                              color: isLoading ? AppColors.textTertiary : AppColors.accentTeal,
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
