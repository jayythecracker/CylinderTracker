import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';

enum UserFilterType {
  all,
  admin,
  manager,
  filler,
  seller,
  active,
  inactive
}

class UsersState {
  final List<User> users;
  final bool isLoading;
  final String? error;
  final UserFilterType filter;

  UsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
    this.filter = UserFilterType.all,
  });

  UsersState copyWith({
    List<User>? users,
    bool? isLoading,
    String? error,
    UserFilterType? filter,
  }) {
    return UsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filter: filter ?? this.filter,
    );
  }

  List<User> get filteredUsers {
    switch (filter) {
      case UserFilterType.admin:
        return users.where((user) => user.role == 'Admin').toList();
      case UserFilterType.manager:
        return users.where((user) => user.role == 'Manager').toList();
      case UserFilterType.filler:
        return users.where((user) => user.role == 'Filler').toList();
      case UserFilterType.seller:
        return users.where((user) => user.role == 'Seller').toList();
      case UserFilterType.active:
        return users.where((user) => user.isActive).toList();
      case UserFilterType.inactive:
        return users.where((user) => !user.isActive).toList();
      case UserFilterType.all:
      default:
        return users;
    }
  }
}

class UserNotifier extends StateNotifier<UsersState> {
  final ApiService _apiService;

  UserNotifier(this._apiService) : super(UsersState()) {
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _apiService.getUsers();
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<User?> getUserById(int id) async {
    try {
      return await _apiService.getUserById(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> createUser(Map<String, dynamic> userData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.createUser(userData);
      await fetchUsers();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateUser(int id, Map<String, dynamic> userData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.updateUser(id, userData);
      await fetchUsers();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> resetUserPassword(int id, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.resetUserPassword(id, newPassword);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.deleteUser(id);
      await fetchUsers();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void setFilter(UserFilterType filter) {
    state = state.copyWith(filter: filter);
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UsersState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return UserNotifier(apiService);
});
