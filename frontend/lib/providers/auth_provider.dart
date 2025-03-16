import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Provider for current user state
final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<User?> {
  late AuthService _authService;
  
  @override
  Future<User?> build() async {
    _authService = ref.read(authServiceProvider);
    return _authService.getCurrentUser();
  }
  
  // Login user
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    
    try {
      final user = await _authService.login(email, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  // Refresh user profile
  Future<void> refreshProfile() async {
    state = const AsyncValue.loading();
    
    try {
      final user = await _authService.getUserProfile();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  // Update user profile
  Future<void> updateProfile(String name, String? contactNumber, String? address) async {
    state = const AsyncValue.loading();
    
    try {
      final user = await _authService.updateProfile(name, contactNumber, address);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _authService.changePassword(currentPassword, newPassword);
    } catch (e) {
      rethrow;
    }
  }
  
  // Logout user
  Future<void> logout() async {
    try {
      await _authService.logout();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _authService.isLoggedIn();
  }
}
