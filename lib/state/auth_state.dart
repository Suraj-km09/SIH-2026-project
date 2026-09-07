import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/secure_storage_service.dart';
import 'app_state.dart';

/// Authentication status states.
enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

/// Immutable state representing active user session and role.
class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.authenticating;
  String get role => user?.role ?? 'user';
  bool get isAdmin => user?.isAdmin ?? false;
  bool get isReviewer => user?.isReviewer ?? false;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.authenticating() => const AuthState(status: AuthStatus.authenticating);
  factory AuthState.authenticated(UserModel user) =>
      AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String message) =>
      AuthState(status: AuthStatus.error, errorMessage: message);
}

/// Provider for AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    mockRepository: MockAuthRepository(),
  );
});

/// Riverpod Notifier for Authentication & Session Restoration.
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _authRepository;
  late final SecureStorageService _storage;

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _storage = ref.watch(secureStorageProvider);
    return AuthState.initial();
  }

  /// Restore persisted authenticated session on startup.
  Future<void> restoreSession() async {
    state = AuthState.authenticating();

    try {
      final token = await _storage.getToken();
      if (token == null || token.isEmpty) {
        state = AuthState.unauthenticated();
        return;
      }

      // Fetch fresh profile with existing token
      try {
        final user = await _authRepository.getMe();
        await _storage.saveUserSession(
          id: user.id,
          username: user.username,
          role: user.role,
        );
        state = AuthState.authenticated(user);
      } catch (_) {
        // Token might be expired, attempt refresh
        try {
          final refreshResult = await _authRepository.refresh(token);
          await _storage.saveToken(refreshResult.token);

          final refreshedUser = refreshResult.user ?? await _authRepository.getMe();
          await _storage.saveUserSession(
            id: refreshedUser.id,
            username: refreshedUser.username,
            role: refreshedUser.role,
          );
          state = AuthState.authenticated(refreshedUser);
        } catch (_) {
          // Token refresh failed, purge stale credentials
          await _storage.clearUserSession();
          state = AuthState.unauthenticated();
        }
      }
    } catch (e) {
      await _storage.clearUserSession();
      state = AuthState.unauthenticated();
    }
  }

  /// Login with username and password.
  Future<bool> login(String username, String password) async {
    state = AuthState.authenticating();

    try {
      final result = await _authRepository.login(
        username: username,
        password: password,
      );

      await _storage.saveToken(result.token);
      await _storage.saveUserSession(
        id: result.user.id,
        username: result.user.username,
        role: result.user.role,
      );

      state = AuthState.authenticated(result.user);
      return true;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Register a standard user.
  Future<bool> register(String username, String password, [String? email]) async {
    state = AuthState.authenticating();

    try {
      final result = await _authRepository.register(
        username: username,
        password: password,
        email: email,
      );

      await _storage.saveToken(result.token);
      await _storage.saveUserSession(
        id: result.user.id,
        username: result.user.username,
        role: result.user.role,
      );

      state = AuthState.authenticated(result.user);
      return true;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Update email and department.
  Future<bool> updateProfile({String? email, String? department}) async {
    try {
      final updatedUser = await _authRepository.updateProfile(
        email: email,
        department: department,
      );

      state = state.copyWith(user: updatedUser);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Change password.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Log out and purge token & user session.
  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (_) {
      // Proceed with local logout regardless of network state
    } finally {
      await _storage.clearUserSession();
      state = AuthState.unauthenticated();
    }
  }
}
