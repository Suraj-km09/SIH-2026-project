import 'package:flutter/material.dart';

/// Responsive design breakpoints and layout utilities for MineIntel AI.
/// Explicitly supports Mobile (<600dp), Tablet (600–1024dp), and Windows Desktop (>1024dp).
class Responsive {
  Responsive._();

  static const double smallMobileBreakpoint = 380.0;
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;

  static bool isSmallMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < smallMobileBreakpoint;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  /// Returns different values based on active responsive breakpoint.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? smallMobile,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= tabletBreakpoint && desktop != null) {
      return desktop;
    }
    if (width >= mobileBreakpoint && tablet != null) {
      return tablet;
    }
    if (width < smallMobileBreakpoint && smallMobile != null) {
      return smallMobile;
    }
    return mobile;
  }
}

/// Convenience extension on BuildContext for responsive queries.
extension ResponsiveContextExtension on BuildContext {
  bool get isSmallMobile => Responsive.isSmallMobile(this);
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);
  bool get isLandscape => Responsive.isLandscape(this);

  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
}
