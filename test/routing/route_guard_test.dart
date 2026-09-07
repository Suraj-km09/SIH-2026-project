import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/core/constants/app_constants.dart';
import 'package:mineintel_ai/routing/app_router.dart';

void main() {
  group('RouteGuard Tests', () {
    test('isPublic identifies public and non-public routes', () {
      expect(RouteGuard.isPublic(AppRoutes.splash), isTrue);
      expect(RouteGuard.isPublic(AppRoutes.login), isTrue);
      expect(RouteGuard.isPublic(AppRoutes.register), isTrue);
      expect(RouteGuard.isPublic(AppRoutes.dashboard), isFalse);
      expect(RouteGuard.isPublic(AppRoutes.admin), isFalse);
      expect(RouteGuard.isPublic(AppRoutes.reports), isFalse);
    });

    test('isGuestOnly identifies guest-only routes', () {
      expect(RouteGuard.isGuestOnly(AppRoutes.login), isTrue);
      expect(RouteGuard.isGuestOnly(AppRoutes.register), isTrue);
      expect(RouteGuard.isGuestOnly(AppRoutes.splash), isFalse);
      expect(RouteGuard.isGuestOnly(AppRoutes.dashboard), isFalse);
    });

    test('canAccess prevents unauthenticated users from accessing protected routes', () {
      // Unauthenticated can access public routes
      expect(
        RouteGuard.canAccess(AppRoutes.login, isAuthenticated: false, role: null),
        isTrue,
      );
      expect(
        RouteGuard.canAccess(AppRoutes.register, isAuthenticated: false, role: null),
        isTrue,
      );

      // Unauthenticated cannot access protected routes
      expect(
        RouteGuard.canAccess(AppRoutes.dashboard, isAuthenticated: false, role: null),
        isFalse,
      );
      expect(
        RouteGuard.canAccess(AppRoutes.admin, isAuthenticated: false, role: null),
        isFalse,
      );
      expect(
        RouteGuard.canAccess(AppRoutes.reports, isAuthenticated: false, role: null),
        isFalse,
      );
    });

    test('canAccess prevents authenticated users from accessing guest-only routes', () {
      expect(
        RouteGuard.canAccess(AppRoutes.login, isAuthenticated: true, role: AppConstants.roleUser),
        isFalse,
      );
      expect(
        RouteGuard.canAccess(AppRoutes.register, isAuthenticated: true, role: AppConstants.roleUser),
        isFalse,
      );
    });

    test('canAccess enforces role-based access control for admin and review routes', () {
      // User role
      expect(
        RouteGuard.canAccess(AppRoutes.dashboard, isAuthenticated: true, role: AppConstants.roleUser),
        isTrue,
      );
      expect(
        RouteGuard.canAccess(AppRoutes.documents, isAuthenticated: true, role: AppConstants.roleUser),
        isTrue,
      );
      expect(
        RouteGuard.canAccess(AppRoutes.reviews, isAuthenticated: true, role: AppConstants.roleUser),
        isFalse,
      );
      expect(
        RouteGuard.canAccess(AppRoutes.admin, isAuthenticated: true, role: AppConstants.roleUser),
        isFalse,
      );

      // Reviewer role
      expect(
        RouteGuard.canAccess(AppRoutes.reviews, isAuthenticated: true, role: AppConstants.roleReviewer),
        isTrue,
      );
      expect(
        RouteGuard.canAccess(AppRoutes.admin, isAuthenticated: true, role: AppConstants.roleReviewer),
        isFalse,
      );

      // Admin role
      expect(
        RouteGuard.canAccess(AppRoutes.admin, isAuthenticated: true, role: AppConstants.roleAdmin),
        isTrue,
      );
      expect(
        RouteGuard.canAccess(AppRoutes.reviews, isAuthenticated: true, role: AppConstants.roleAdmin),
        isTrue,
      );
    });

    test('resolveRedirect redirects unauthenticated to /login and authenticated guest attempts to /dashboard', () {
      // Unauthenticated user trying to access /reports
      expect(
        RouteGuard.resolveRedirect(AppRoutes.reports, isAuthenticated: false, role: null),
        equals(AppRoutes.login),
      );

      // Authenticated user trying to access /login
      expect(
        RouteGuard.resolveRedirect(AppRoutes.login, isAuthenticated: true, role: AppConstants.roleUser),
        equals(AppRoutes.dashboard),
      );

      // Non-admin trying to access /admin
      expect(
        RouteGuard.resolveRedirect(AppRoutes.admin, isAuthenticated: true, role: AppConstants.roleUser),
        equals(AppRoutes.dashboard),
      );

      // Permitted navigation returns null
      expect(
        RouteGuard.resolveRedirect(AppRoutes.dashboard, isAuthenticated: true, role: AppConstants.roleUser),
        isNull,
      );
      expect(
        RouteGuard.resolveRedirect(AppRoutes.admin, isAuthenticated: true, role: AppConstants.roleAdmin),
        isNull,
      );
    });
  });

  group('RoleHandler RBAC Tests', () {
    test('isUser, isReviewer, and isAdmin validate hierarchy', () {
      expect(RoleHandler.isUser('user'), isTrue);
      expect(RoleHandler.isReviewer('user'), isFalse);
      expect(RoleHandler.isAdmin('user'), isFalse);

      expect(RoleHandler.isUser('reviewer'), isTrue);
      expect(RoleHandler.isReviewer('reviewer'), isTrue);
      expect(RoleHandler.isAdmin('reviewer'), isFalse);

      expect(RoleHandler.isUser('admin'), isTrue);
      expect(RoleHandler.isReviewer('admin'), isTrue);
      expect(RoleHandler.isAdmin('admin'), isTrue);
    });

    test('canApproveReports is strictly restricted to Admin only (Maker-Checker)', () {
      expect(RoleHandler.canApproveReports('user'), isFalse);
      expect(RoleHandler.canApproveReports('reviewer'), isFalse);
      expect(RoleHandler.canApproveReports('admin'), isTrue);
    });

    test('canRejectReports is allowed for Reviewer and Admin', () {
      expect(RoleHandler.canRejectReports('user'), isFalse);
      expect(RoleHandler.canRejectReports('reviewer'), isTrue);
      expect(RoleHandler.canRejectReports('admin'), isTrue);
    });

    test('canManageUsers is strictly restricted to Admin only', () {
      expect(RoleHandler.canManageUsers('user'), isFalse);
      expect(RoleHandler.canManageUsers('reviewer'), isFalse);
      expect(RoleHandler.canManageUsers('admin'), isTrue);
    });
  });
}
