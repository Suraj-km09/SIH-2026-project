import 'dart:io';
import 'package:flutter/foundation.dart';

/// Supported Environment Presets for MineIntel AI.
enum AppEnvironment {
  production,
  localDesktop,
  localAndroidEmulator,
  custom,
}

/// Centralized Environment and API configuration.
/// Ensures the API base URL is configurable at runtime without modifying service code.
class EnvConfig {
  EnvConfig._();

  // Canonical Base URLs
  static const String productionBaseUrl = 'https://mini-intel-ai-sih.vercel.app/api/v1';
  static const String localDesktopBaseUrl = 'http://127.0.0.1:5000/api/v1';
  static const String localAndroidEmulatorBaseUrl = 'http://10.0.2.2:5000/api/v1';

  // Active Environment
  static AppEnvironment activeEnvironment = AppEnvironment.production;
  static String? customBaseUrl;
  static bool useMockData = false;

  /// Resolves the effective API base URL dynamically.
  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }

    switch (activeEnvironment) {
      case AppEnvironment.production:
        return productionBaseUrl;
      case AppEnvironment.localDesktop:
        return localDesktopBaseUrl;
      case AppEnvironment.localAndroidEmulator:
        return localAndroidEmulatorBaseUrl;
      case AppEnvironment.custom:
        return customBaseUrl ?? productionBaseUrl;
    }
  }

  /// Platform-aware local development URL.
  static String get defaultLocalUrl {
    if (kIsWeb) return 'http://localhost:5000/api/v1';
    if (Platform.isAndroid) return localAndroidEmulatorBaseUrl;
    return localDesktopBaseUrl; // Windows, iOS Simulator, macOS, Linux
  }

  /// Set custom URL for future local or staging backend.
  static void setCustomUrl(String url) {
    customBaseUrl = url.trim();
    activeEnvironment = AppEnvironment.custom;
  }

  /// Reset to production Vercel API.
  static void resetToProduction() {
    customBaseUrl = null;
    activeEnvironment = AppEnvironment.production;
  }

  // Network Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 3);

  // Safe Ingestion Polling Constraints
  static const Duration pollingInterval = Duration(milliseconds: 2500);
  static const Duration maxPollingDuration = Duration(minutes: 3);
}
