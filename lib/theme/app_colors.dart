import 'package:flutter/material.dart';

/// Design tokens derived strictly from the MineIntel AI visual reference:
/// Light neutral canvas, pure white card surfaces, dark hero metric card,
/// crisp high-contrast typography, and restrained muted accents.
class AppColors {
  AppColors._();

  // Background & Canvas (Light Neutral)
  static const Color background = Color(0xFFF8F9FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F3F7);
  static const Color surfaceHover = Color(0xFFF8FAFC);

  // Hero Card Surface (Dark Charcoal / Near-Black)
  static const Color heroSurface = Color(0xFF111827);
  static const Color heroSurfaceLight = Color(0xFF1F2937);

  // Borders & Dividers (Subtle Gray)
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFEEF2F6);
  static const Color borderActive = Color(0xFFCBD5E1);

  // Typography (Near-black & Muted Gray)
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textInverseMuted = Color(0xFF9CA3AF);

  // Brand & Restrained Accents (Teal, Blue, Green)
  static const Color primary = Color(0xFF0F172A);
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentGreen = Color(0xFF059669);
  static const Color accentIndigo = Color(0xFF4F46E5);

  // Status & Severity Colors
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color error = Color(0xFFE11D48);
  static const Color errorBg = Color(0xFFFFF1F2);
  static const Color errorBorder = Color(0xFFFECDD3);

  static const Color info = Color(0xFF0284C7);
  static const Color infoBg = Color(0xFFF0F9FF);
  static const Color infoBorder = Color(0xFFBAE6FD);

  // Pill and Badge Tints
  static const Color badgeNeutralBg = Color(0xFFF1F5F9);
  static const Color badgeNeutralText = Color(0xFF475569);

  // Minimalist Shadows (Soft Ambient, No harsh shadows)
  static const BoxShadow softShadow = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 10,
    spreadRadius: 0,
    offset: Offset(0, 2),
  );

  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x080F172A),
    blurRadius: 8,
    spreadRadius: 0,
    offset: Offset(0, 1),
  );
}
