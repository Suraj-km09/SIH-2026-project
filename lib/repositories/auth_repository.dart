import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import '../network/auth_remote_data_source.dart';
import 'base_repository.dart';

/// Abstract contract for authentication operations.
abstract class AuthRepository {
  Future<AuthResultModel> register({
    required String username,
    required String password,
    String? email,
  });

  Future<AuthResultModel> login({
    required String username,
    required String password,
  });

  Future<UserModel> getMe();

  Future<UserModel> updateProfile({
    String? email,
    String? department,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<RefreshTokenResultModel> refresh(String token);

  Future<void> logout();
}

/// Concrete implementation delegating to AuthRemoteDataSource or Mock.
class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthRepository? mockRepository;

  AuthRepositoryImpl({
    AuthRemoteDataSource? remoteDataSource,
    this.mockRepository,
  })  : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSourceImpl();

  @override
  Future<AuthResultModel> register({
    required String username,
    required String password,
    String? email,
  }) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.register(
        username: username,
        password: password,
        email: email,
      );
    }

    return execute(() => _remoteDataSource.register(
          username: username,
          password: password,
          email: email,
        ));
  }

  @override
  Future<AuthResultModel> login({
    required String username,
    required String password,
  }) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.login(
        username: username,
        password: password,
      );
    }

    return execute(() => _remoteDataSource.login(
          username: username,
          password: password,
        ));
  }

  @override
  Future<UserModel> getMe() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getMe();
    }

    return execute(() => _remoteDataSource.getMe());
  }

  @override
  Future<UserModel> updateProfile({
    String? email,
    String? department,
  }) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.updateProfile(
        email: email,
        department: department,
      );
    }

    return execute(() => _remoteDataSource.updateProfile(
          email: email,
          department: department,
        ));
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    }

    return execute(() => _remoteDataSource.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ));
  }

  @override
  Future<RefreshTokenResultModel> refresh(String token) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.refresh(token);
    }

    return execute(() => _remoteDataSource.refresh(token));
  }

  @override
  Future<void> logout() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.logout();
    }

    return execute(() => _remoteDataSource.logout());
  }
}

/// Offline Mock Implementation for unit testing and offline development.
class MockAuthRepository implements AuthRepository {
  UserModel _currentUser = const UserModel(
    id: 'mock_user_1',
    username: 'mining_engineer',
    email: 'engineer@mineintel.ai',
    role: 'user',
    department: 'Mining Operations',
    status: 'active',
  );

  @override
  Future<AuthResultModel> register({
    required String username,
    required String password,
    String? email,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = UserModel(
      id: 'mock_user_new',
      username: username,
      email: email,
      role: 'user',
      department: 'Operations',
      status: 'active',
    );
    return AuthResultModel(user: _currentUser, token: 'mock_jwt_token_register');
  }

  @override
  Future<AuthResultModel> login({
    required String username,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final role = username == 'admin' ? 'admin' : (username == 'reviewer' ? 'reviewer' : 'user');
    _currentUser = UserModel(
      id: 'mock_user_login',
      username: username,
      email: '$username@mineintel.ai',
      role: role,
      department: 'Mining Directorate',
      status: 'active',
    );
    return AuthResultModel(user: _currentUser, token: 'mock_jwt_token_login');
  }

  @override
  Future<UserModel> getMe() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _currentUser;
  }

  @override
  Future<UserModel> updateProfile({
    String? email,
    String? department,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _currentUser = UserModel(
      id: _currentUser.id,
      username: _currentUser.username,
      email: email ?? _currentUser.email,
      department: department ?? _currentUser.department,
      role: _currentUser.role,
      status: _currentUser.status,
    );
    return _currentUser;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<RefreshTokenResultModel> refresh(String token) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return RefreshTokenResultModel(
      token: 'mock_jwt_refreshed_token',
      user: _currentUser,
    );
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 50));
  }
}
