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
  String? _errorMessage;
  Map<String, String> _fieldErrors = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    if (_errorMessage != null || _fieldErrors.isNotEmpty) {
      setState(() {
        _errorMessage = null;
        _fieldErrors.clear();
      });
    }
  }

  void _showAlertSnackBar(String message, {bool isWarning = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isWarning ? const Color(0xFFD97706) : AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'RETRY',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
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
    if (lower.contains('incorrect') ||
        lower.contains('invalid credentials') ||
        lower.contains('invalid username or password') ||
        lower.contains('401') ||
        lower.contains('unauthorized')) {
      return 'Invalid username or password. Please verify your credentials and try again.';
    }
    if (lower.contains('user') && (lower.contains('not found') || lower.contains('404'))) {
      return username.isNotEmpty
          ? 'User "$username" not found. Please verify your username or register.'
          : 'User account not found. Please verify your credentials or register.';
    }
    if (lower.contains('503') || lower.contains('unavailable') || lower.contains('timeout')) {
      return 'Server is taking longer than expected to respond. Please try again or switch to Mock Mode.';
    }
    if (lower.contains('network') || lower.contains('connection') || lower.contains('socket')) {
      return 'Network connection error. Check your device connectivity or switch to Mock Mode.';
    }

    return msg.isNotEmpty ? msg : 'Invalid username or password. Please verify your credentials and try again.';
  }

  Future<void> _handleLogin() async {
    // Guard against duplicate concurrent submissions
    if (_isSubmitting || ref.read(authNotifierProvider).isLoading) return;

    _clearErrors();

    // 1. Form and client-side validation
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;
      final fErrors = <String, String>{};
      if (username.isEmpty) fErrors['username'] = 'Username is required';
      if (password.isEmpty) {
        fErrors['password'] = 'Password is required';
      } else if (password.length < 6) {
        fErrors['password'] = 'Password must be at least 6 characters';
      }

      const valMsg = 'Please complete all required fields correctly.';
      setState(() {
        _errorMessage = valMsg;
        _fieldErrors = fErrors;
      });
      _showAlertSnackBar(valMsg, isWarning: true);
      return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 2. Submit credentials
      final success = await ref
          .read(authNotifierProvider.notifier)
          .login(username, password);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Signed in successfully as $username.',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        widget.onLoginSuccess?.call();
      } else {
        final authState = ref.read(authNotifierProvider);
        final rawError = authState.errorMessage ?? 'Authentication failed. Please check credentials.';
        final isVal = authState.isValidationError || authState.isInvalidPassword;
        final message = _cleanErrorMessage(
          authState.validationMessage ?? rawError,
          username,
        );
        final fErrors = Map<String, String>.from(authState.fieldErrors ?? {});

        if (isVal && fErrors.isEmpty) {
          if (rawError.toLowerCase().contains('password')) {
            fErrors['password'] = 'Password must be at least 6 characters';
          }
          if (rawError.toLowerCase().contains('username')) {
            fErrors['username'] = 'Username is required';
          }
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

  void _fillCredentials(String user, String pass) {
    if (_isSubmitting || ref.read(authNotifierProvider).isLoading) return;
    setState(() {
      _errorMessage = null;
      _fieldErrors.clear();
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
                          onPressed: isLoading
                              ? null
                              : () {
                                  final current = EnvConfig.useMockData;
                                  ref.read(envConfigProvider.notifier).toggleMockMode(!current);
                                  setState(() {});
                                },
                          child: Text(
                            EnvConfig.useMockData ? 'Switch to Live API' : 'Switch to Mock Mode',
                            style: AppTypography.labelSmall.copyWith(
                              color: isLoading ? AppColors.textTertiary : AppColors.accentTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Error Message Alert Banner (Clean, user-friendly, no technical error types)
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.35),
                            width: 1.5,
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
                      label: 'Username / User ID',
                      hint: 'Enter your mining username',
                      prefixIcon: Icons.person_outline,
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
                    const SizedBox(height: 12),

                    // Forgot Password Action
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading ? null : _showForgotPasswordDialog,
                        child: Text(
                          'Forgot Password?',
                          style: AppTypography.labelSmall.copyWith(
                            color: isLoading ? AppColors.textTertiary : AppColors.accentTeal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submit Button with integrated loader
                    AppButton(
                      text: isLoading ? 'Signing In...' : 'Sign In to Workspace',
                      isLoading: isLoading,
                      icon: isLoading ? null : Icons.login,
                      onPressed: isLoading ? null : _handleLogin,
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
                                onPressed: isLoading ? null : () => _fillCredentials('admin', 'admin123'),
                              ),
                              ActionChip(
                                label: const Text('Reviewer', style: TextStyle(fontSize: 12)),
                                avatar: const Icon(Icons.rate_review_outlined, size: 14),
                                onPressed: isLoading ? null : () => _fillCredentials('reviewer', 'reviewer123'),
                              ),
                              ActionChip(
                                label: const Text('User', style: TextStyle(fontSize: 12)),
                                avatar: const Icon(Icons.person_outline, size: 14),
                                onPressed: isLoading ? null : () => _fillCredentials('mining_engineer', 'engineer123'),
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
                          onPressed: isLoading ? null : widget.onNavigateToRegister,
                          child: Text(
                            'Register Now',
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
