import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cylinder_management/models/user.dart';
import 'package:cylinder_management/services/auth_service.dart';

// Provider for the current authenticated user
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(AuthService());
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;
  
  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _init();
  }
  
  // Initialize by checking for existing user
  Future<void> _init() async {
    try {
      state = const AsyncValue.loading();
      final user = await _authService.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  // Login user
  Future<void> login(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      final user = await _authService.login(email, password);
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow; // Rethrow to handle in UI
    }
  }
  
  // Logout user
  Future<void> logout() async {
    try {
      await _authService.logout();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  // Update password
  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    try {
      return await _authService.updatePassword(currentPassword, newPassword);
    } catch (e) {
      rethrow; // Rethrow to handle in UI
    }
  }
  
  // Register new user (admin only)
  Future<User?> registerUser(Map<String, dynamic> userData) async {
    try {
      return await _authService.registerUser(userData);
    } catch (e) {
      rethrow; // Rethrow to handle in UI
    }
  }
  
  // Refresh user data
  Future<void> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
