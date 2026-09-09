import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_model.dart';
import '../models/user_model.dart';
import '../repositories/admin_repository.dart';
import 'app_state.dart';

enum AdminRoleFilter { all, user, reviewer, admin }

extension AdminRoleFilterExtension on AdminRoleFilter {
  String get label {
    switch (this) {
      case AdminRoleFilter.all:
        return 'All Roles';
      case AdminRoleFilter.user:
        return 'User';
      case AdminRoleFilter.reviewer:
        return 'Reviewer';
      case AdminRoleFilter.admin:
        return 'Admin';
    }
  }
}

class AdminState {
  final ViewStatus status;
  final AdminStatsModel? stats;
  final SystemHealthModel? systemHealth;
  final List<UserModel> users;
  final AdminRoleFilter roleFilter;
  final String searchQuery;
  final bool isActionLoading;
  final String? actionMessage;
  final String? errorMessage;

  const AdminState({
    this.status = ViewStatus.initial,
    this.stats,
    this.systemHealth,
    this.users = const [],
    this.roleFilter = AdminRoleFilter.all,
    this.searchQuery = '',
    this.isActionLoading = false,
    this.actionMessage,
    this.errorMessage,
  });

  bool get isLoading => status == ViewStatus.loading;
  bool get isSuccess => status == ViewStatus.success;
  bool get isError => status == ViewStatus.error;

  List<UserModel> get filteredUsers {
    var result = users;
    if (roleFilter != AdminRoleFilter.all) {
      final roleStr = roleFilter == AdminRoleFilter.admin
          ? 'admin'
          : (roleFilter == AdminRoleFilter.reviewer ? 'reviewer' : 'user');
      result = result.where((u) => u.role.toLowerCase() == roleStr).toList();
    }
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      result = result
          .where((u) =>
              u.username.toLowerCase().contains(q) ||
              (u.email?.toLowerCase().contains(q) ?? false) ||
              (u.department?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return result;
  }

  AdminState copyWith({
    ViewStatus? status,
    AdminStatsModel? stats,
    SystemHealthModel? systemHealth,
    List<UserModel>? users,
    AdminRoleFilter? roleFilter,
    String? searchQuery,
    bool? isActionLoading,
    String? actionMessage,
    String? errorMessage,
  }) {
    return AdminState(
      status: status ?? this.status,
      stats: stats ?? this.stats,
      systemHealth: systemHealth ?? this.systemHealth,
      users: users ?? this.users,
      roleFilter: roleFilter ?? this.roleFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      actionMessage: actionMessage,
      errorMessage: errorMessage,
    );
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(mockRepository: MockAdminRepository());
});

final adminNotifierProvider =
    NotifierProvider<AdminNotifier, AdminState>(AdminNotifier.new);

class AdminNotifier extends Notifier<AdminState> {
  late final AdminRepository _repository;

  @override
  AdminState build() {
    _repository = ref.watch(adminRepositoryProvider);
    return const AdminState();
  }

  Future<void> loadAdminData() async {
    state = state.copyWith(status: ViewStatus.loading, errorMessage: null);

    try {
      final results = await Future.wait([
        _repository.getStats(),
        _repository.getSystemHealth(),
        _repository.getUsers(),
      ]);

      state = state.copyWith(
        status: ViewStatus.success,
        stats: results[0] as AdminStatsModel,
        systemHealth: results[1] as SystemHealthModel,
        users: results[2] as List<UserModel>,
      );
    } catch (e) {
      state = state.copyWith(
        status: ViewStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadSystemHealth() async {
    try {
      final health = await _repository.getSystemHealth();
      state = state.copyWith(systemHealth: health);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void setRoleFilter(AdminRoleFilter filter) {
    state = state.copyWith(roleFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> updateUserRole(String userId, String newRole) async {
    state = state.copyWith(isActionLoading: true, actionMessage: null, errorMessage: null);
    try {
      final updated = await _repository.updateUserRole(userId: userId, role: newRole);
      final updatedUsers = state.users.map((u) => u.id == userId ? updated : u).toList();
      state = state.copyWith(
        users: updatedUsers,
        isActionLoading: false,
        actionMessage: 'Role for ${updated.username} updated to ${newRole.toUpperCase()}',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    state = state.copyWith(isActionLoading: true, actionMessage: null, errorMessage: null);
    try {
      await _repository.deleteUser(userId);
      final updatedUsers = state.users.where((u) => u.id != userId).toList();
      final newStats = state.stats != null
          ? AdminStatsModel(
              totalUsers: (state.stats!.totalUsers - 1).clamp(0, 999999),
              totalDocuments: state.stats!.totalDocuments,
              indexedDocuments: state.stats!.indexedDocuments,
              reportsGenerated: state.stats!.reportsGenerated,
              totalValidations: state.stats!.totalValidations,
              openValidations: state.stats!.openValidations,
            )
          : null;

      state = state.copyWith(
        users: updatedUsers,
        stats: newStats,
        isActionLoading: false,
        actionMessage: 'User account successfully deleted.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}
