import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/env_config.dart';
import '../../state/auth_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/status_chip.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/feedback/loading_indicator.dart';

/// Splash & Session Restoration Screen.
/// Probes server connectivity, restores persisted JWT credentials,
/// and routes user to either MainShell or LoginScreen.
class SplashScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSessionChecked;

  const SplashScreen({super.key, this.onSessionChecked});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isChecking = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSession();
    });
  }

  Future<void> _initializeSession() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).restoreSession();
      widget.onSessionChecked?.call();
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to restore session. Please log in.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Branded Platform Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.heroSurface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.insights,
                    color: AppColors.textInverse,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 24),

                // Platform Title & Subtitle
                Text(
                  'MineIntel AI',
                  style: AppTypography.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Mining Intelligence & Statutory Compliance Platform',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Server Status Indicator
                StatusChip(
                  status: EnvConfig.useMockData ? 'mock_mode' : 'active',
                ),
                const SizedBox(height: 32),

                // Dynamic Action / Loader
                if (_isChecking) ...[
                  const AppLoadingIndicator(
                    size: 36,
                    message: 'Restoring session & verifying credentials...',
                  ),
                ] else if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'Retry Connection',
                    icon: Icons.refresh,
                    onPressed: _initializeSession,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
