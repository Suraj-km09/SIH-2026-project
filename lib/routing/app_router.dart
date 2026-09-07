import '../core/constants/app_constants.dart';

/// Centralized route name constants for MineIntel AI.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String commandCentre = '/command-centre';
  static const String documents = '/documents';
  static const String documentDetail = '/documents/detail';
  static const String extraction = '/extraction';
  static const String validation = '/validation';
  static const String reports = '/reports';
  static const String reportDetail = '/reports/detail';
  static const String reviews = '/reviews';
  static const String aiAssistant = '/ai-assistant';
  static const String knowledgeBase = '/knowledge-base';
  static const String analytics = '/analytics';
  static const String topics = '/topics';
  static const String agents = '/agents';
  static const String gis = '/gis';
  static const String audit = '/audit';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String admin = '/admin';
  static const String help = '/help';
}

/// Routing guards for unauthenticated/authenticated users and RBAC role tiers.
class RouteGuard {
  RouteGuard._();

  /// Public routes accessible without authentication.
  static bool isPublic(String route) {
    return route == AppRoutes.splash ||
        route == AppRoutes.login ||
        route == AppRoutes.register;
  }

  /// Guest-only routes that authenticated users should not access (e.g. login).
  static bool isGuestOnly(String route) {
    return route == AppRoutes.login || route == AppRoutes.register;
  }

  /// Check whether a user with given authentication state and role can access target route.
  static bool canAccess(
    String route, {
    required bool isAuthenticated,
    required String? role,
  }) {
    // Guest-only routes blocked for authenticated users
    if (isAuthenticated && isGuestOnly(route)) {
      return false;
    }

    // Public routes allowed for unauthenticated users
    if (!isAuthenticated && isPublic(route)) {
      return true;
    }

    // Protected routes require active authentication
    if (!isAuthenticated) {
      return false;
    }

    // Role-based restrictions
    if (route == AppRoutes.admin) {
      return role == AppConstants.roleAdmin;
    }

    if (route == AppRoutes.reviews) {
      return role == AppConstants.roleReviewer || role == AppConstants.roleAdmin;
    }

    // Standard user routes accessible to all authenticated roles
    return true;
  }

  /// Resolves the redirection route if access is denied.
  /// Returns null if navigation to targetRoute is permitted.
  static String? resolveRedirect(
    String targetRoute, {
    required bool isAuthenticated,
    required String? role,
  }) {
    // Unauthenticated user trying to access protected route
    if (!isAuthenticated && !isPublic(targetRoute)) {
      return AppRoutes.login;
    }

    // Authenticated user trying to access login/register
    if (isAuthenticated && isGuestOnly(targetRoute)) {
      return AppRoutes.dashboard;
    }

    // Insufficient permissions for role-restricted routes
    if (isAuthenticated) {
      if (targetRoute == AppRoutes.admin && role != AppConstants.roleAdmin) {
        return AppRoutes.dashboard;
      }
      if (targetRoute == AppRoutes.reviews &&
          role != AppConstants.roleReviewer &&
          role != AppConstants.roleAdmin) {
        return AppRoutes.dashboard;
      }
    }

    return null;
  }
}

/// Role handling and permission checking helper.
class RoleHandler {
  RoleHandler._();

  /// Standard user: can view/manage own resources.
  static bool isUser(String? role) =>
      role == AppConstants.roleUser || role == AppConstants.roleReviewer || role == AppConstants.roleAdmin;

  /// Reviewer: can access pending review queues and reject reports with reasons.
  static bool isReviewer(String? role) =>
      role == AppConstants.roleReviewer || role == AppConstants.roleAdmin;

  /// Administrator: strictly restricted governance authority.
  static bool isAdmin(String? role) => role == AppConstants.roleAdmin;

  /// Maker-Checker Report Approval Barrier: Admin ONLY.
  static bool canApproveReports(String? role) => isAdmin(role);

  /// Maker-Checker Report Rejection: Reviewer or Admin with mandatory reason.
  static bool canRejectReports(String? role) => isReviewer(role);

  /// User Administration (List, Change Role, Delete): Admin ONLY.
  static bool canManageUsers(String? role) => isAdmin(role);
}
