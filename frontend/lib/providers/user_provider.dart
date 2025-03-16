import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

// Provider for API service
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Provider for users list state
final usersProvider = AsyncNotifierProvider<UsersNotifier, List<User>>(() {
  return UsersNotifier();
});

// Provider for selected user
final selectedUserProvider = StateProvider<User?>((ref) => null);

class UsersNotifier extends AsyncNotifier<List<User>> {
  late ApiService _apiService;
  
  @override
  Future<List<User>> build() async {
    _apiService = ref.read(apiServiceProvider);
    return [];
  }
  
  // Get all users
  Future<void> getUsers() async {
    state = const AsyncValue.loading();
    
    try {
      final response = await _apiService.get(AppConfig.usersEndpoint);
      final List<User> users = (response['users'] as List)
          .map((userData) => User.fromJson(userData))
          .toList();
      
      state = AsyncValue.data(users);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  // Get user by ID
  Future<User> getUserById(int id) async {
    try {
      final response = await _apiService.get('${AppConfig.usersEndpoint}/$id');
      return User.fromJson(response['user']);
    } catch (e) {
      rethrow;
    }
  }
  
  // Create user
  Future<User> createUser(String name, String email, String password, String role, 
      String? contactNumber, String? address) async {
    try {
      final response = await _apiService.post(
        AppConfig.usersEndpoint,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'contactNumber': contactNumber,
          'address': address,
        },
      );
      
      final newUser = User.fromJson(response['user']);
      
      // Update state with new user
      state = AsyncValue.data([...state.value ?? [], newUser]);
      
      return newUser;
    } catch (e) {
      rethrow;
    }
  }
  
  // Update user
  Future<User> updateUser(int id, String name, String email, String role, 
      String? contactNumber, String? address, bool isActive) async {
    try {
      final response = await _apiService.put(
        '${AppConfig.usersEndpoint}/$id',
        data: {
          'name': name,
          'email': email,
          'role': role,
          'contactNumber': contactNumber,
          'address': address,
          'isActive': isActive,
        },
      );
      
      final updatedUser = User.fromJson(response['user']);
      
      // Update state with updated user
      state = AsyncValue.data(
        state.value?.map((user) => user.id == id ? updatedUser : user).toList() ?? [],
      );
      
      return updatedUser;
    } catch (e) {
      rethrow;
    }
  }
  
  // Reset user password
  Future<void> resetPassword(int id, String newPassword) async {
    try {
      await _apiService.put(
        '${AppConfig.usersEndpoint}/$id/reset-password',
        data: {
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // Delete user
  Future<void> deleteUser(int id) async {
    try {
      await _apiService.delete('${AppConfig.usersEndpoint}/$id');
      
      // Update state by removing deleted user
      state = AsyncValue.data(
        state.value?.where((user) => user.id != id).toList() ?? [],
      );
    } catch (e) {
      rethrow;
    }
  }
}
