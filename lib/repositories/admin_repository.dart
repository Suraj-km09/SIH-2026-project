import '../models/admin_model.dart';
import '../models/user_model.dart';
import '../network/admin_remote_data_source.dart';
import 'base_repository.dart';

/// Abstract contract for Admin & System Health operations.
abstract class AdminRepository {
  Future<AdminStatsModel> getStats();
  Future<SystemHealthModel> getSystemHealth();
  Future<List<UserModel>> getUsers();
  Future<UserModel> updateUserRole({required String userId, required String role});
  Future<void> deleteUser(String userId);
}

/// Concrete implementation delegating to AdminRemoteDataSource with Mock fallback.
class AdminRepositoryImpl extends BaseRepository implements AdminRepository {
  final AdminRemoteDataSource _remoteDataSource;
  final AdminRepository? mockRepository;

  AdminRepositoryImpl({
    AdminRemoteDataSource? remoteDataSource,
    this.mockRepository,
  }) : _remoteDataSource = remoteDataSource ?? AdminRemoteDataSourceImpl();

  @override
  Future<AdminStatsModel> getStats() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getStats();
    }
    try {
      return await execute(() => _remoteDataSource.getStats());
    } catch (_) {
      if (mockRepository != null) {
        return mockRepository!.getStats();
      }
      rethrow;
    }
  }

  @override
  Future<SystemHealthModel> getSystemHealth() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getSystemHealth();
    }
    try {
      return await execute(() => _remoteDataSource.getSystemHealth());
    } catch (_) {
      if (mockRepository != null) {
        return mockRepository!.getSystemHealth();
      }
      rethrow;
    }
  }

  @override
  Future<List<UserModel>> getUsers() async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.getUsers();
    }
    try {
      return await execute(() => _remoteDataSource.getUsers());
    } catch (_) {
      if (mockRepository != null) {
        return mockRepository!.getUsers();
      }
      rethrow;
    }
  }

  @override
  Future<UserModel> updateUserRole({required String userId, required String role}) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.updateUserRole(userId: userId, role: role);
    }
    try {
      return await execute(() => _remoteDataSource.updateUserRole(userId: userId, role: role));
    } catch (_) {
      if (mockRepository != null) {
        return mockRepository!.updateUserRole(userId: userId, role: role);
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    if (isMockMode && mockRepository != null) {
      return mockRepository!.deleteUser(userId);
    }
    try {
      return await execute(() => _remoteDataSource.deleteUser(userId));
    } catch (_) {
      if (mockRepository != null) {
        return mockRepository!.deleteUser(userId);
      }
      rethrow;
    }
  }
}

/// Offline Mock Repository matching the web application screenshot references.
class MockAdminRepository implements AdminRepository {
  final Duration delay;

  MockAdminRepository({this.delay = Duration.zero});

  List<UserModel> _users = [
    const UserModel(
      id: 'usr_001',
      username: 'sih_audit_926871',
      email: 'audit926871@mineintel.ai',
      role: 'user',
      department: 'Safety & Audit',
      status: 'active',
      createdAt: '2026-09-01T10:15:00Z',
    ),
    const UserModel(
      id: 'usr_002',
      username: 'test_lgn_1788806463567',
      email: null,
      role: 'user',
      department: 'Field Operations',
      status: 'active',
      createdAt: '2026-09-02T11:20:00Z',
    ),
    const UserModel(
      id: 'usr_003',
      username: 'test_sih_1788806451730',
      email: 'test178880@mineintel.ai',
      role: 'reviewer',
      department: 'Statutory Verification',
      status: 'active',
      createdAt: '2026-09-03T14:45:00Z',
    ),
    const UserModel(
      id: 'usr_004',
      username: 'Reyes',
      email: 'abhinjay.reyes@mineintel.ai',
      role: 'user',
      department: 'Geology & Survey',
      status: 'active',
      createdAt: '2026-09-04T09:00:00Z',
    ),
    const UserModel(
      id: 'usr_005',
      username: 'Mangesh',
      email: 's24_dhamande@mineintel.ai',
      role: 'reviewer',
      department: 'Environmental Compliance',
      status: 'active',
      createdAt: '2026-09-04T16:30:00Z',
    ),
    const UserModel(
      id: 'usr_006',
      username: 'vishal',
      email: 'vishal.admin@mineintel.ai',
      role: 'admin',
      department: 'Directorate IT & Governance',
      status: 'active',
      createdAt: '2026-08-15T08:00:00Z',
    ),
    const UserModel(
      id: 'usr_007',
      username: 'alok_patel',
      email: 'alok.patel@mineintel.ai',
      role: 'user',
      department: 'Production Analytics',
      status: 'active',
      createdAt: '2026-09-05T12:00:00Z',
    ),
    const UserModel(
      id: 'usr_008',
      username: 'priya_sharma',
      email: 'priya.sharma@mineintel.ai',
      role: 'reviewer',
      department: 'DGMS Safety Bureau',
      status: 'active',
      createdAt: '2026-09-06T15:20:00Z',
    ),
  ];

  @override
  Future<AdminStatsModel> getStats() async {
    if (delay > Duration.zero) await Future.delayed(delay);
    return const AdminStatsModel(
      totalUsers: 36,
      totalDocuments: 48,
      indexedDocuments: 42,
      reportsGenerated: 15,
      totalValidations: 9,
      openValidations: 3,
    );
  }

  @override
  Future<SystemHealthModel> getSystemHealth() async {
    if (delay > Duration.zero) await Future.delayed(delay);
    return const SystemHealthModel(
      backend: 'Online',
      mongoDB: 'Connected',
      aiProvider: 'Online',
      vectorDB: 'Online',
      timestamp: '2026-09-08T12:00:00Z',
      version: 'v1.4.2',
      uptime: 86400,
    );
  }

  @override
  Future<List<UserModel>> getUsers() async {
    if (delay > Duration.zero) await Future.delayed(delay);
    return List.unmodifiable(_users);
  }

  @override
  Future<UserModel> updateUserRole({required String userId, required String role}) async {
    if (delay > Duration.zero) await Future.delayed(delay);
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final updated = _users[idx].copyWith(role: role);
      _users = List.from(_users)..[idx] = updated;
      return updated;
    }
    throw Exception('User not found: $userId');
  }

  @override
  Future<void> deleteUser(String userId) async {
    if (delay > Duration.zero) await Future.delayed(delay);
    final target = _users.firstWhere((u) => u.id == userId, orElse: () => throw Exception('User not found'));
    if (target.isAdmin) {
      throw Exception('Administrator accounts cannot be deleted directly.');
    }
    _users = _users.where((u) => u.id != userId).toList();
  }
}
